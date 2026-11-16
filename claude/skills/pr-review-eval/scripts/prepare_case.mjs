#!/usr/bin/env node
// Builds the git working copy a reviewer will review for one eval case, and prints { id, workdir, base_sha,
// head_sha, intent } as JSON.
//
// Usage: node prepare_case.mjs CASE_DIR WORK_ROOT [--repo REPO_ROOT]
//
// Case layout:
//   case.json   { id, intent, commit_message?, base_ref?, expected: [...], must_not_flag: [...] }
//   base/       files of the base commit (fixture case)   — or base_ref + --repo for a project case
//   change/     files written over the base (new or modified); change/.delete lists paths to remove

import { execFileSync } from 'node:child_process';
import { cpSync, existsSync, mkdirSync, readFileSync, rmSync } from 'node:fs';
import { join, resolve } from 'node:path';

const git = (cwd, ...args) => execFileSync('git', args, { cwd, encoding: 'utf8' }).trim();

function main() {
  const [caseArg, workArg, ...rest] = process.argv.slice(2);
  if (!caseArg || !workArg) throw new Error('Usage: node prepare_case.mjs CASE_DIR WORK_ROOT [--repo REPO_ROOT]');
  const caseDir = resolve(caseArg);
  const spec = JSON.parse(readFileSync(join(caseDir, 'case.json'), 'utf8'));
  const workdir = resolve(workArg, spec.id);
  const repoIdx = rest.indexOf('--repo');
  const repoRoot = repoIdx >= 0 ? resolve(rest[repoIdx + 1]) : null;

  if (existsSync(workdir)) {
    if (repoRoot) execFileSync('git', ['worktree', 'remove', '--force', workdir], { cwd: repoRoot, stdio: 'ignore' });
    rmSync(workdir, { recursive: true, force: true });
  }
  mkdirSync(resolve(workArg), { recursive: true });

  if (existsSync(join(caseDir, 'base'))) {
    mkdirSync(workdir, { recursive: true });
    cpSync(join(caseDir, 'base'), workdir, { recursive: true });
    git(workdir, 'init', '-q', '-b', 'main');
    git(workdir, 'add', '-A');
    git(workdir, '-c', 'user.name=eval', '-c', 'user.email=eval@localhost', 'commit', '-q', '-m', 'Base');
  } else if (spec.base_ref && repoRoot) {
    git(repoRoot, 'worktree', 'add', '-q', '--detach', workdir, spec.base_ref);
  } else {
    throw new Error(`${spec.id}: needs a base/ directory, or base_ref plus --repo`);
  }
  const baseSha = git(workdir, 'rev-parse', 'HEAD');

  const changeDir = join(caseDir, 'change');
  if (existsSync(changeDir)) {
    cpSync(changeDir, workdir, { recursive: true, filter: (src) => !src.endsWith('/.delete') });
    const deleteList = join(changeDir, '.delete');
    if (existsSync(deleteList)) {
      for (const p of readFileSync(deleteList, 'utf8').split('\n').filter(Boolean)) {
        rmSync(join(workdir, p), { force: true, recursive: true });
      }
    }
  }
  git(workdir, 'add', '-A');
  git(
    workdir,
    '-c', 'user.name=eval', '-c', 'user.email=eval@localhost',
    'commit', '-q', '-m', spec.commit_message ?? spec.intent ?? spec.id,
  );

  console.log(
    JSON.stringify({ id: spec.id, workdir, base_sha: baseSha, head_sha: git(workdir, 'rev-parse', 'HEAD'), intent: spec.intent }),
  );
}

try {
  main();
} catch (e) {
  console.error(e.message);
  process.exit(1);
}
