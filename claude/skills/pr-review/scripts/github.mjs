// Thin wrapper around the `gh` CLI shared by the pr-review and pr-fix scripts. No dependencies.

import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

export const REVIEW_MARKER = 'ai-review';
export const COMMENT_MARKER = '<!-- ai-review-comment -->';
export const FIX_MARKER = '<!-- ai-fix -->';
export const REPLY_MARKER = '<!-- ai-review-reply -->';
export const AGENT_MARKERS = [COMMENT_MARKER, FIX_MARKER, REPLY_MARKER];
export const SEVERITIES = ['blocking', 'should-fix', 'nit'];
export const SCOPES = ['local', 'cross-cutting'];
export const DEFAULT_MAX_ROUNDS = 3;

export class GhError extends Error {}

export function gh(args, { input, allowFailure = false } = {}) {
  const res = spawnSync('gh', args, { input, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  if (res.error) throw new GhError(`gh ${args.join(' ')} failed: ${res.error.message}`);
  if (res.status !== 0 && !allowFailure) throw new GhError(`gh ${args.join(' ')} failed:\n${res.stderr}`);
  return res.stdout;
}

export const ghJson = (args, opts) => JSON.parse(gh(args, opts));

let cachedRepo;
export function repo() {
  cachedRepo ??= ghJson(['repo', 'view', '--json', 'nameWithOwner']).nameWithOwner;
  return cachedRepo;
}

export const ownerAndName = () => repo().split('/', 2);

export const currentPrNumber = () => ghJson(['pr', 'view', '--json', 'number']).number;

export function prNumberFromArgs(argv) {
  const arg = argv.find((a) => /^\d+$/.test(a));
  return arg ? Number(arg) : currentPrNumber();
}

export function graphql(query, variables = {}) {
  const args = ['api', 'graphql', '-f', `query=${query}`];
  for (const [key, value] of Object.entries(variables)) {
    if (value === undefined || value === null) continue;
    args.push(Number.isInteger(value) ? '-F' : '-f', `${key}=${value}`);
  }
  const result = ghJson(args);
  if (result.errors) throw new GhError(`GraphQL errors: ${JSON.stringify(result.errors)}`);
  return result.data;
}

const PR_QUERY = `
  query($owner: String!, $name: String!, $pr: Int!, $cursor: String) {
    repository(owner: $owner, name: $name) {
      pullRequest(number: $pr) {
        title
        body
        url
        state
        mergedAt
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
            comments(first: 50) { nodes { databaseId body url author { login } createdAt } }
          }
        }
      }
    }
  }`;

// Returns { pull, threads } with all review threads (paginated).
export function fetchPullRequest(number) {
  const [owner, name] = ownerAndName();
  const threads = [];
  let cursor;
  let pull;
  for (;;) {
    pull = graphql(PR_QUERY, { owner, name, pr: number, cursor })?.repository?.pullRequest;
    if (!pull) throw new GhError(`PR #${number} not found in ${owner}/${name}`);
    threads.push(...pull.reviewThreads.nodes);
    if (!pull.reviewThreads.pageInfo.hasNextPage) break;
    cursor = pull.reviewThreads.pageInfo.endCursor;
  }
  return { pull, threads };
}

// Parses `<!-- ai-review round=2 sha=abc blocking=1 -->` into an object.
export function parseReviewMarker(body) {
  const match = String(body ?? '').match(new RegExp(`<!--\\s*${REVIEW_MARKER}\\s+(.*?)\\s*-->`));
  if (!match) return null;
  return Object.fromEntries(match[1].split(/\s+/).map((pair) => pair.split('=', 2)));
}

export const buildReviewMarker = (attrs) =>
  `<!-- ${REVIEW_MARKER} ${Object.entries(attrs)
    .map(([k, v]) => `${k}=${v}`)
    .join(' ')} -->`;

// All review markers of a PR, oldest round first.
export function reviewMarkers(pull) {
  return pull.reviews.nodes
    .map((r) => parseReviewMarker(r.body))
    .filter(Boolean)
    .sort((a, b) => Number(a.round) - Number(b.round));
}

// Reads the latest review round from the review markers of a PR.
export const lastReviewMarker = (pull) => reviewMarkers(pull).at(-1) ?? null;

// Comment header: `**[blocking · cross-cutting] · security** — title`
export const severityOf = (body) => String(body ?? '').match(/\*\*\[(blocking|should-fix|nit)\b/)?.[1] ?? null;
export const scopeOf = (body) => String(body ?? '').match(/\*\*\[[a-z-]+ · (local|cross-cutting)\]/)?.[1] ?? null;

// Reads `max_rounds:` from the YAML front matter of docs/review.md, if any.
export function maxRounds(root = process.cwd()) {
  if (process.env.AI_REVIEW_MAX_ROUNDS) return Number(process.env.AI_REVIEW_MAX_ROUNDS);
  const guide = join(root, 'docs', 'review.md');
  if (!existsSync(guide)) return DEFAULT_MAX_ROUNDS;
  const frontMatter = readFileSync(guide, 'utf8').match(/^---\n([\s\S]*?)\n---/)?.[1] ?? '';
  const value = frontMatter.match(/^max_rounds:\s*(\d+)/m)?.[1];
  return value ? Number(value) : DEFAULT_MAX_ROUNDS;
}

export function runMain(fn) {
  try {
    const code = fn();
    process.exit(code ?? 0);
  } catch (e) {
    console.error(e.message);
    process.exit(1);
  }
}
