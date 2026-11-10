#!/usr/bin/env ruby
# frozen_string_literal: true

# Prints the unresolved review threads of a PR as JSON, flagging the ones that still need a fixer answer
# (the last comment is not a fixer reply).
#
# Usage: ruby open_threads.rb [PR_NUMBER]

require_relative "../../rails-pr-review/scripts/github"

FIX_MARKER = "<!-- ai-fix -->"
THREADS_QUERY = <<~GRAPHQL
  query($owner: String!, $name: String!, $pr: Int!, $cursor: String) {
    repository(owner: $owner, name: $name) {
      pullRequest(number: $pr) {
        title
        headRefName
        headRefOid
        reviewThreads(first: 100, after: $cursor) {
          pageInfo { hasNextPage endCursor }
          nodes {
            id
            isResolved
            isOutdated
            path
            line
            originalLine
            comments(first: 50) { nodes { databaseId body author { login } createdAt } }
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

def serialize(thread)
  comments = thread.dig("comments", "nodes")
  first = comments.first
  ai_review = first["body"].include?(GitHub::COMMENT_MARKER)

  {
    "thread_id" => thread["id"],
    "comment_id" => first["databaseId"],
    "path" => thread["path"],
    "line" => thread["line"] || thread["originalLine"],
    "outdated" => thread["isOutdated"],
    "source" => ai_review ? "ai-review" : "human",
    "severity" => ai_review ? GitHub.severity_of(first["body"]) : nil,
    "needs_answer" => !comments.last["body"].include?(FIX_MARKER),
    "comments" => comments.map do |c|
      { "author" => c.dig("author", "login"), "body" => c["body"].sub(GitHub::COMMENT_MARKER, "").strip,
        "at" => c["createdAt"] }
    end
  }
end

begin
  number = (ARGV[0] || GitHub.current_pr_number).to_i
  owner, name = GitHub.owner_and_name
  pull, threads = fetch_pull_request(owner, name, number)
  open_threads = threads.reject { |t| t["isResolved"] || t.dig("comments", "nodes").empty? }.map { |t| serialize(t) }

  puts JSON.pretty_generate(
    "repo" => GitHub.repo,
    "pr" => number,
    "title" => pull["title"],
    "head_ref" => pull["headRefName"],
    "head_sha" => pull["headRefOid"],
    "to_answer_count" => open_threads.count { |t| t["needs_answer"] },
    "open_threads" => open_threads
  )
rescue GitHub::Error, KeyError => e
  warn e.message
  exit 1
end
