# frozen_string_literal: true

require "json"
require "open3"

# Thin wrapper around the `gh` CLI shared by the review scripts.
module GitHub
  REVIEW_MARKER = "ai-review"
  COMMENT_MARKER = "<!-- ai-review-comment -->"

  class Error < StandardError; end

  module_function

  def gh(*args, input: nil)
    out, err, status = Open3.capture3("gh", *args, stdin_data: input)
    raise Error, "gh #{args.join(' ')} failed:\n#{err}" unless status.success?

    out.force_encoding(Encoding::UTF_8)
  end

  def gh_json(*args, input: nil)
    JSON.parse(gh(*args, input: input))
  end

  def repo
    @repo ||= gh_json("repo", "view", "--json", "nameWithOwner").fetch("nameWithOwner")
  end

  def owner_and_name
    repo.split("/", 2)
  end

  def current_pr_number
    gh_json("pr", "view", "--json", "number").fetch("number")
  end

  def graphql(query, **variables)
    args = ["api", "graphql", "-f", "query=#{query}"]
    variables.each do |key, value|
      flag = value.is_a?(Integer) ? "-F" : "-f"
      args += [flag, "#{key}=#{value}"]
    end
    result = gh_json(*args)
    raise Error, "GraphQL errors: #{result['errors'].to_json}" if result["errors"]

    result.fetch("data")
  end

  # Parses `<!-- ai-review round=2 sha=abc blocking=1 -->` into a hash.
  def parse_review_marker(body)
    match = body.to_s.match(/<!--\s*#{REVIEW_MARKER}\s+(.*?)\s*-->/)
    return nil unless match

    match[1].split.to_h { |pair| pair.split("=", 2) }
  end

  def build_review_marker(attrs)
    "<!-- #{REVIEW_MARKER} #{attrs.map { |k, v| "#{k}=#{v}" }.join(' ')} -->"
  end

  def severity_of(comment_body)
    comment_body.to_s[/\*\*\[(blocking|should-fix|nit)\]/, 1]
  end
end
