#!/usr/bin/env ruby
# frozen_string_literal: true

# Prints the review state of a PR as JSON: round number, last reviewed commit,
# open threads left by the reviewer (with the fixer's replies), and CI status.
#
# Usage: ruby review_state.rb [PR_NUMBER]

require_relative "github"

THREADS_QUERY = <<~GRAPHQL
  query($owner: String!, $name: String!, $pr: Int!, $cursor: String) {
    repository(owner: $owner, name: $name) {
      pullRequest(number: $pr) {
        title
        headRefOid
        baseRefName
        headRefName
        reviews(last: 100) { nodes { body } }
        reviewThreads(first: 100, after: $cursor) {
          pageInfo { hasNextPage endCursor }
          nodes {
            id
            isResolved
            isOutdated
            path
            line
            originalLine
            comments(first: 30) {
              nodes { databaseId body author { login } createdAt }
            }
          }
        }
      }
    }
  }
GRAPHQL

def fetch_pull_request(owner, name, number)
  threads = []
  cursor = nil
  pull = nil

  loop do
    vars = { owner: owner, name: name, pr: number }
    vars[:cursor] = cursor if cursor
    pull = GitHub.graphql(THREADS_QUERY, **vars).dig("repository", "pullRequest")
    raise GitHub::Error, "PR ##{number} not found in #{owner}/#{name}" unless pull

    page = pull["reviewThreads"]
    threads.concat(page["nodes"])
    break unless page.dig("pageInfo", "hasNextPage")

    cursor = page.dig("pageInfo", "endCursor")
  end

  [pull, threads]
end

def ci_checks(number)
  # `gh pr checks` exits non-zero when checks fail or are pending, so read stdout regardless.
  out, _err, _status = Open3.capture3("gh", "pr", "checks", number.to_s, "--json", "name,state,bucket")
  checks = JSON.parse(out)
  {
    "failing" => checks.select { |c| c["bucket"] == "fail" }.map { |c| c["name"] },
    "pending" => checks.select { |c| c["bucket"] == "pending" }.map { |c| c["name"] },
    "passing_count" => checks.count { |c| c["bucket"] == "pass" }
  }
rescue JSON::ParserError
  { "failing" => [], "pending" => [], "passing_count" => 0, "note" => "no CI checks reported" }
end

def open_reviewer_threads(threads)
  threads.filter_map do |thread|
    next if thread["isResolved"]

    comments = thread.dig("comments", "nodes")
    first = comments.first
    next unless first && first["body"].include?(GitHub::COMMENT_MARKER)

    {
      "thread_id" => thread["id"],
      "comment_id" => first["databaseId"],
      "path" => thread["path"],
      "line" => thread["line"] || thread["originalLine"],
      "outdated" => thread["isOutdated"],
      "severity" => GitHub.severity_of(first["body"]),
      "comment" => first["body"].sub(GitHub::COMMENT_MARKER, "").strip,
      "replies" => comments.drop(1).map do |c|
        { "author" => c.dig("author", "login"), "body" => c["body"], "at" => c["createdAt"] }
      end
    }
  end
end

begin
  number = (ARGV[0] || GitHub.current_pr_number).to_i
  owner, name = GitHub.owner_and_name
  pull, threads = fetch_pull_request(owner, name, number)

  markers = pull.dig("reviews", "nodes").filter_map { |r| GitHub.parse_review_marker(r["body"]) }
  last = markers.max_by { |m| m["round"].to_i }
  previous_rounds = last ? last["round"].to_i : 0
  open_threads = open_reviewer_threads(threads)

  state = {
    "repo" => GitHub.repo,
    "pr" => number,
    "title" => pull["title"],
    "head_ref" => pull["headRefName"],
    "base_ref" => pull["baseRefName"],
    "head_sha" => pull["headRefOid"],
    "previous_rounds" => previous_rounds,
    "next_round" => previous_rounds + 1,
    "max_rounds" => (ENV["AI_REVIEW_MAX_ROUNDS"] || 3).to_i,
    "last_reviewed_sha" => last && last["sha"],
    "new_commits_since_last_review" => last.nil? || last["sha"] != pull["headRefOid"],
    "open_threads" => open_threads,
    "open_blocking_count" => open_threads.count { |t| t["severity"] == "blocking" },
    "ci_checks" => ci_checks(number)
  }

  puts JSON.pretty_generate(state)
rescue GitHub::Error, KeyError => e
  warn e.message
  exit 1
end
