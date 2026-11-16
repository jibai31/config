#!/usr/bin/env node
// Replies to review threads from a JSON file. Never resolves threads: the reviewer does that.
//
// Usage: node post_replies.mjs REPLIES_JSON [--dry-run]
// JSON: { "pr": 123, "replies": [{ "comment_id": 1234567, "body": "Fixed in abc1234: ..." }] }

import { readFileSync } from 'node:fs';

import { FIX_MARKER, gh, repo, runMain } from '../../pr-review/scripts/github.mjs';

const PREFIXES = ['Fixed in ', "Won't fix: ", 'Question: '];

runMain(() => {
  const [path, ...flags] = process.argv.slice(2);
  if (!path) throw new Error('Usage: node post_replies.mjs REPLIES_JSON [--dry-run]');
  const data = JSON.parse(readFileSync(path, 'utf8'));
  const number = Number(data.pr);
  if (!number) throw new Error('replies file needs pr');
  const replies = data.replies ?? [];

  replies.forEach((reply, i) => {
    if (!reply.comment_id) throw new Error(`reply #${i} missing comment_id`);
    if (!PREFIXES.some((p) => String(reply.body ?? '').startsWith(p))) {
      throw new Error(`reply #${i} must start with one of: ${PREFIXES.join(' | ')}`);
    }
  });

  if (flags.includes('--dry-run')) {
    console.log(JSON.stringify(replies, null, 2));
    return 0;
  }

  for (const reply of replies) {
    gh([
      'api',
      `repos/${repo()}/pulls/${number}/comments/${reply.comment_id}/replies`,
      '--method',
      'POST',
      '-f',
      `body=${FIX_MARKER}\n${reply.body}`,
    ]);
  }
  console.log(`Posted ${replies.length} replies on PR #${number}`);
  return 0;
});
