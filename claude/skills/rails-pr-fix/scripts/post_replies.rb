#!/usr/bin/env ruby
# frozen_string_literal: true

# Replies to review threads from a JSON file. Never resolves threads: the reviewer does that.
#
# Usage: ruby post_replies.rb REPLIES_JSON [--dry-run]
# JSON: { "pr": 123, "replies": [{ "comment_id": 1234567, "body": "Fixed in abc1234: ..." }] }

require_relative "../../rails-pr-review/scripts/github"

FIX_MARKER = "<!-- ai-fix -->"
PREFIXES = ["Fixed in ", "Won't fix: ", "Question: "].freeze

def validate!(replies)
  replies.each_with_index do |reply, i|
    raise ArgumentError, "reply ##{i} missing comment_id" unless reply["comment_id"]
    next if PREFIXES.any? { |prefix| reply["body"].to_s.start_with?(prefix) }

    raise ArgumentError, "reply ##{i} must start with one of: #{PREFIXES.join(' | ')}"
  end
end

begin
  data = JSON.parse(File.read(ARGV.fetch(0)))
  number = data.fetch("pr")
  replies = Array(data["replies"])
  validate!(replies)

  if ARGV.include?("--dry-run")
    puts JSON.pretty_generate(replies)
    exit 0
  end

  replies.each do |reply|
    GitHub.gh("api", "repos/#{GitHub.repo}/pulls/#{number}/comments/#{reply['comment_id']}/replies",
              "--method", "POST", "-f", "body=#{FIX_MARKER}\n#{reply['body']}")
  end
  puts "Posted #{replies.size} replies on PR ##{number}"
rescue GitHub::Error, ArgumentError, KeyError, IndexError, JSON::ParserError => e
  warn e.message
  exit 1
end
