#!/usr/bin/env node
// Scores reviewer findings against eval cases.
//
// Usage: node score.mjs --cases DIR [--cases DIR...] --results DIR --work DIR [--out FILE] [--history FILE]
//                       [--label TEXT]
//
//   --cases    case roots (each holds <id>/case.json)
//   --results  holds <id>/run-<k>.json findings files written by pr-review local mode
//   --work     work root used by prepare_case.mjs (anchors are resolved in <work>/<id>)
//
// Case expectations (case.json):
//   expected:      [{ id, path, anchor, anchor_end?, span?, severity, severity_min?, scope?, required?, note }]
//   must_not_flag: [{ id, path, anchor, anchor_end?, span?, keywords?, note }]
//   acceptable:    [{ id, path, anchor, anchor_end?, span?, keywords?, note }]  real issues not planted: neither
//                  rewarded nor penalized
// `keywords` (expected / must_not_flag / acceptable): case-insensitive regex the finding's title + body must match.
// `anchor` is a regex matched against the file at the reviewed commit; the expected range is the matching line
// (through `anchor_end` if given) widened by `span` lines (default 3). `required` defaults to true when severity is
// blocking. A finding matches an expectation when it is on the same path and its line range overlaps, at the item's
// own location or at one of its `alternatives` ([{ path, anchor, anchor_end?, span? }]).

import { appendFileSync, existsSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const RANK = { nit: 0, 'should-fix': 1, blocking: 2 };

function parseArgs(argv) {
  const opts = { cases: [] };
  for (let i = 0; i < argv.length; i += 2) {
    const key = argv[i].replace(/^--/, '');
    if (key === 'cases') opts.cases.push(argv[i + 1]);
    else opts[key] = argv[i + 1];
  }
  if (!opts.cases.length || !opts.results || !opts.work) {
    throw new Error('Usage: node score.mjs --cases DIR --results DIR --work DIR [--out FILE] [--history FILE]');
  }
  return opts;
}

function resolveRange(workdir, item) {
  const file = join(workdir, item.path);
  if (!existsSync(file)) throw new Error(`${item.id}: ${item.path} not found in ${workdir}`);
  const lines = readFileSync(file, 'utf8').split('\n');
  const find = (re, from = 0) => {
    const rx = new RegExp(re);
    const idx = lines.findIndex((l, i) => i >= from && rx.test(l));
    if (idx < 0) throw new Error(`${item.id}: anchor /${re}/ not found in ${item.path}`);
    return idx + 1;
  };
  const start = find(item.anchor);
  const end = item.anchor_end ? find(item.anchor_end, start - 1) : start;
  const span = item.span ?? 3;
  return [Math.max(1, start - span), end + span];
}

const overlaps = (f, path, [lo, hi]) => f.path === path && (f.start_line ?? f.line) <= hi && f.line >= lo;

// An item's locations: its own, plus `alternatives` ([{ path, anchor, anchor_end?, span? }]) where the same issue
// can as validly be anchored (e.g. a missing test on the code or on the spec, a bug at the call or at the callee).
const withLocations = (workdir, item) => ({
  ...item,
  locations: [item, ...(item.alternatives ?? [])].map((loc) => ({
    path: loc.path,
    range: resolveRange(workdir, { id: item.id, ...loc }),
  })),
});

function scoreRun(spec, workdir, findings) {
  const expected = (spec.expected ?? []).map((e) => withLocations(workdir, e));
  const mustNot = (spec.must_not_flag ?? []).map((m) => withLocations(workdir, m));
  const accept = (spec.acceptable ?? []).map((a) => withLocations(workdir, a));
  const used = new Set();
  const matched = [];
  const missed = [];

  // Several findings can sit on the same lines (e.g. a race and a missing test on one validation). `keywords` (a
  // case-insensitive regex on title + body) disambiguates: those expectations match first, and only findings whose
  // text matches them.
  const text = (f) => `${f.title ?? ''} ${f.body ?? ''}`;
  const fits = (f, item) =>
    item.locations.some((loc) => overlaps(f, loc.path, loc.range)) &&
    (!item.keywords || new RegExp(item.keywords, 'i').test(text(f)));
  const ordered = [...expected].sort((a, b) => Number(!a.keywords) - Number(!b.keywords));

  for (const e of ordered) {
    const idx = findings.findIndex((f, i) => !used.has(i) && fits(f, e));
    if (idx < 0) {
      missed.push({ id: e.id, required: e.required ?? e.severity === 'blocking', note: e.note });
      continue;
    }
    used.add(idx);
    const f = findings[idx];
    // A finding may be one level below the expected severity only if severity_min allows it; it may be blocking
    // when blocking isn't expected only if blocking_ok says so (inflation keeps the loop churning).
    const inflated = f.severity === 'blocking' && e.severity !== 'blocking' && !e.blocking_ok;
    matched.push({
      id: e.id,
      severity: f.severity,
      expected_severity: e.severity,
      severity_ok: RANK[f.severity] >= RANK[e.severity_min ?? e.severity] && !inflated,
      scope_ok: e.scope ? f.scope === e.scope : null,
      inflated_to_blocking: inflated,
    });
  }

  // Order for the rest: acceptable (real issues the case didn't plant) → must_not_flag (traps) → unexpected.
  const mustNotHits = [];
  const unexpected = [];
  const acceptable = [];
  findings.forEach((f, i) => {
    if (used.has(i)) return;
    const ok = accept.find((a) => fits(f, a));
    if (ok) {
      acceptable.push({ id: ok.id, severity: f.severity, title: f.title });
      return;
    }
    const hit = mustNot.find((m) => fits(f, m));
    if (hit) mustNotHits.push({ id: hit.id, severity: f.severity, title: f.title });
    else unexpected.push({ path: f.path, line: f.line, severity: f.severity, title: f.title });
  });

  const requiredMissed = missed.filter((m) => m.required);
  const unexpectedBlocking = unexpected.filter((u) => u.severity === 'blocking');
  const inflated = matched.filter((m) => m.inflated_to_blocking);
  return {
    expected: expected.length,
    matched: matched.length,
    missed,
    required_missed: requiredMissed.length,
    must_not_hits: mustNotHits,
    acceptable,
    unexpected,
    unexpected_blocking: unexpectedBlocking.length,
    severity_ok: matched.filter((m) => m.severity_ok).length,
    scope_ok: matched.filter((m) => m.scope_ok === true).length,
    scope_checked: matched.filter((m) => m.scope_ok !== null).length,
    matched_detail: matched,
    pass: !requiredMissed.length && !mustNotHits.length && !unexpectedBlocking.length && !inflated.length,
  };
}

function loadCases(roots) {
  return roots.flatMap((root) =>
    readdirSync(root, { withFileTypes: true })
      .filter((d) => d.isDirectory() && existsSync(join(root, d.name, 'case.json')))
      .map((d) => JSON.parse(readFileSync(join(root, d.name, 'case.json'), 'utf8'))),
  );
}

const pct = (a, b) => (b ? Math.round((100 * a) / b) : null);
const fmt = (v) => (v === null ? "n/a" : `${v}%`);

function main() {
  const opts = parseArgs(process.argv.slice(2));
  const cases = loadCases(opts.cases);
  const results = [];

  for (const spec of cases) {
    const dir = join(opts.results, spec.id);
    if (!existsSync(dir)) {
      results.push({ id: spec.id, runs: [], note: 'no results' });
      continue;
    }
    const runs = readdirSync(dir)
      .filter((f) => /^run-\d+\.json$/.test(f))
      .sort()
      .map((f) => ({ run: f, ...scoreRun(spec, join(opts.work, spec.id), JSON.parse(readFileSync(join(dir, f), 'utf8')).findings ?? []) }));
    results.push({ id: spec.id, runs });
  }

  const runs = results.flatMap((r) => r.runs);
  const sum = (k) => runs.reduce((n, r) => n + (typeof r[k] === 'number' ? r[k] : r[k].length), 0);
  const requiredTotal = cases.reduce(
    (n, c) => n + (c.expected ?? []).filter((e) => e.required ?? e.severity === 'blocking').length * (results.find((r) => r.id === c.id)?.runs.length ?? 0),
    0,
  );
  const aggregate = {
    cases: cases.length,
    runs: runs.length,
    pass_rate: pct(runs.filter((r) => r.pass).length, runs.length),
    recall: pct(sum('matched'), sum('expected')),
    required_recall: pct(requiredTotal - sum('required_missed'), requiredTotal),
    severity_accuracy: pct(sum('severity_ok'), sum('matched')),
    scope_accuracy: pct(sum('scope_ok'), sum('scope_checked')),
    must_not_hits: sum('must_not_hits'),
    false_blocking: sum('unexpected_blocking'),
    unexpected_per_run: runs.length ? Number((sum('unexpected') / runs.length).toFixed(1)) : null,
  };

  const rows = results.flatMap((r) =>
    r.runs.length
      ? r.runs.map(
          (x) =>
            `| ${r.id} | ${x.run} | ${x.pass ? 'pass' : 'FAIL'} | ${x.matched}/${x.expected} | ` +
            `${x.missed.map((m) => m.id).join(', ') || '—'} | ${x.must_not_hits.length} | ${x.unexpected.length} ` +
            `(${x.unexpected_blocking} blocking) |`,
        )
      : [`| ${r.id} | — | no results | | | | |`],
  );
  console.log(
    [
      '| Case | Run | Result | Matched | Missed | Must-not hits | Unexpected |',
      '|---|---|---|---|---|---|---|',
      ...rows,
      '',
      `**Pass rate** ${fmt(aggregate.pass_rate)} · **recall** ${fmt(aggregate.recall)} · **required recall** ` +
        `${fmt(aggregate.required_recall)} · **severity accuracy** ${fmt(aggregate.severity_accuracy)} · **scope accuracy** ` +
        `${fmt(aggregate.scope_accuracy)} · **must-not hits** ${aggregate.must_not_hits} · **false blocking** ` +
        `${aggregate.false_blocking} · **unexpected/run** ${aggregate.unexpected_per_run}`,
    ].join('\n'),
  );

  const report = { at: new Date().toISOString(), label: opts.label ?? null, aggregate, results };
  if (opts.out) writeFileSync(opts.out, JSON.stringify(report, null, 2));
  if (opts.history) appendFileSync(opts.history, JSON.stringify({ at: report.at, label: report.label, aggregate }) + '\n');
}

try {
  main();
} catch (e) {
  console.error(e.message);
  process.exit(1);
}
