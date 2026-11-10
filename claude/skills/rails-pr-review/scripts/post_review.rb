#!/usr/bin/env ruby
# frozen_string_literal: true

# Posts a review from a findings JSON file: resolves verified threads, replies to
# still-open ones, then posts a single review with inline comments.
#
# Usage: ruby post_review.rb FINDINGS_JSON [--dry-run]
#
# Exit codes: 0 no open blocking issues · 2 blocking issues open · 3 handoff to a human · 1 error

require_relative "github"

SEVERITIES = %w[blocking should-fix nit].freeze
RESOLVE_MUTATION = <<~GRAPHQL
  mutation($id: ID!) { resolveReviewThread(input: { threadId: $id }) { thread { id isResolved } } }
GRAPHQL

# Returns { "path" => Set-like Hash of commentable new-side line numbers } from the PR's patches.
def commentable_lines(number)
  lines_by_file = {}
  raw = GitHub.gh("api", "repos/#{GitHub.repo}/pulls/#{number}/files", "--paginate",
                  "--jq", '.[] | {filename, patch}')
  raw.each_line do |line|
    next if line.strip.empty?

    file = JSON.parse(line)
    lines_by_file[file["filename"]] = parse_patch(file["patch"].to_s)
  end
  lines_by_file
end

def parse_patch(patch)
  valid = {}
  new_line = nil
  patch.each_line do |row|
    if (hunk = row.match(/^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@/))
      new_line = hunk[1].to_i
    elsif new_line.nil? || row.start_with?("\\")
      next
    elsif row.start_with?("-")
      next
    else # context (" ") or addition ("+")
      valid[new_line] = true
      new_line += 1
    end
  end
  valid
end

def format_comment(finding)
  parts = ["#{GitHub::COMMENT_MARKER}\n**[#{finding['severity']}] · #{finding['category']}** — #{finding['title']}"]
  parts << finding["body"].to_s.strip
  if finding["suggestion"] && !finding["suggestion"].to_s.empty?
    parts << "```suggestion\n#{finding['suggestion'].to_s.chomp}\n```"
  end
  parts.join("\n\n")
end

def validate!(findings)
  findings.each_with_index do |f, i|
    missing = %w[path line severity title body].reject { |k| f[k] }
    raise ArgumentError, "finding ##{i} missing #{missing.join(', ')}" if missing.any?
    raise ArgumentError, "finding ##{i} has unknown severity #{f['severity']}" unless SEVERITIES.include?(f["severity"])
  end
end

def split_findings(findings, valid_lines)
  findings.partition do |f|
    file_lines = valid_lines[f["path"]]
    next false unless file_lines

    range_start = f["start_line"] || f["line"]
    (range_start..f["line"]).all? { |l| file_lines[l] }
  end
end

def build_body(data, counts, orphans, open_blocking)
  lines = []
  lines << if data["handoff"]
             "## 🤖 AI review — round #{data['round']}: handing off to a human"
           else
             "## 🤖 AI review — round #{data['round']}"
           end
  lines << data["summary"].to_s.strip
  lines << "**Findings:** #{counts['blocking']} blocking · #{counts['should-fix']} should-fix · #{counts['nit']} nit" \
           " — **open blocking (incl. previous rounds): #{open_blocking}**"
  if orphans.any?
    lines << "### Findings outside the diff"
    orphans.each do |f|
      lines << "- **[#{f['severity']}]** `#{f['path']}:#{f['line']}` — #{f['title']}: #{f['body']}"
    end
  end
  lines << GitHub.build_review_marker(round: data["round"], sha: data["commit_id"],
                                      blocking: open_blocking, handoff: !!data["handoff"])
  lines.join("\n\n")
end

path, *flags = ARGV
dry_run = flags.include?("--dry-run")
abort "Usage: ruby post_review.rb FINDINGS_JSON [--dry-run]" unless path && File.exist?(path)

begin
  data = JSON.parse(File.read(path))
  number = data.fetch("pr").to_i
  findings = data["handoff"] ? [] : Array(data["findings"])
  validate!(findings)

  inline, orphans = split_findings(findings, commentable_lines(number))
  counts = SEVERITIES.to_h { |s| [s, findings.count { |f| f["severity"] == s }] }
  open_blocking = counts["blocking"] + data["carried_blocking"].to_i

  review = {
    "commit_id" => data.fetch("commit_id"),
    "event" => "COMMENT",
    "body" => build_body(data, counts, orphans, open_blocking),
    "comments" => inline.map do |f|
      comment = { "path" => f["path"], "line" => f["line"], "side" => "RIGHT", "body" => format_comment(f) }
      if f["start_line"] && f["start_line"] < f["line"]
        comment.merge!("start_line" => f["start_line"], "start_side" => "RIGHT")
      end
      comment
    end
  }

  if dry_run
    puts JSON.pretty_generate("resolve" => Array(data["resolve"]), "replies" => Array(data["replies"]),
                              "review" => review, "moved_to_body" => orphans.size)
  else
    Array(data["resolve"]).each { |id| GitHub.graphql(RESOLVE_MUTATION, id: id) }
    Array(data["replies"]).each do |reply|
      GitHub.gh("api", "repos/#{GitHub.repo}/pulls/#{number}/comments/#{reply.fetch('comment_id')}/replies",
                "--method", "POST", "-f", "body=#{reply.fetch('body')}")
    end
    result = GitHub.gh_json("api", "repos/#{GitHub.repo}/pulls/#{number}/reviews",
                            "--method", "POST", "--input", "-", input: JSON.generate(review))
    puts "Posted review #{result['html_url']}"
    puts "Inline: #{inline.size} · in body: #{orphans.size} · resolved: #{Array(data['resolve']).size} · " \
         "replies: #{Array(data['replies']).size} · open blocking: #{open_blocking}"
  end

  exit(3) if data["handoff"]
  exit(open_blocking.positive? ? 2 : 0)
rescue GitHub::Error, KeyError, ArgumentError, JSON::ParserError => e
  warn e.message
  exit 1
end
