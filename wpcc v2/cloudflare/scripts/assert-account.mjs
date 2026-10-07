#!/usr/bin/env node
// Refuses to continue unless Wrangler will act on the Cloudflare account this
// Worker is pinned to. Run from a Worker folder (npm runs it as `predeploy`).
//
// It checks, in order:
//   1. the Wrangler config pins `account_id`;
//   2. the one shared cloudflare/.env (and no per-Worker .env) sets
//      CLOUDFLARE_API_TOKEN and a CLOUDFLARE_ACCOUNT_ID that equals the pinned ID,
//      so Wrangler cannot fall back to the global `wrangler login` session, which
//      may be another account;
//   3. the token really works on the pinned account.
// Token values are never printed.

import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const cwd = process.cwd();
// One shared credentials file for every Worker: cloudflare/.env
const sharedEnvPath = join(dirname(fileURLToPath(import.meta.url)), '..', '.env');
const fail = (message) => {
  console.error(`\nAccount guard: ${message}\nNothing was deployed.\n`);
  process.exit(1);
};

/** Removes // and /* comments and trailing commas outside of strings. */
function stripJsonc(text) {
  let out = '';
  let inString = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    const n = text[i + 1];
    if (inString) {
      out += c;
      if (c === '\\') out += text[++i];
      else if (c === '"') inString = false;
    } else if (c === '"') {
      inString = true;
      out += c;
    } else if (c === '/' && n === '/') {
      while (i < text.length && text[i] !== '\n') i++;
      out += '\n';
    } else if (c === '/' && n === '*') {
      i += 2;
      while (i < text.length && !(text[i] === '*' && text[i + 1] === '/')) i++;
      i++;
    } else out += c;
  }
  return out.replace(/,(\s*[}\]])/g, '$1');
}

function pinnedAccountId() {
  for (const name of ['wrangler.jsonc', 'wrangler.json']) {
    const path = join(cwd, name);
    if (!existsSync(path)) continue;
    try {
      return JSON.parse(stripJsonc(readFileSync(path, 'utf8'))).account_id;
    } catch (error) {
      fail(`could not read ${name}: ${error.message}`);
    }
  }
  const toml = join(cwd, 'wrangler.toml');
  if (existsSync(toml)) {
    return /^\s*account_id\s*=\s*"([^"]+)"/m.exec(readFileSync(toml, 'utf8'))?.[1];
  }
  return fail('no wrangler.jsonc, wrangler.json or wrangler.toml in this folder.');
}

function readDotEnv() {
  const values = {};
  if (!existsSync(sharedEnvPath)) return values;
  for (const line of readFileSync(sharedEnvPath, 'utf8').split(/\r?\n/)) {
    if (line.trim().startsWith('#')) continue;
    const match = /^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/.exec(line);
    if (match) values[match[1]] = match[2].replace(/^(['"])(.*)\1$/, '$2');
  }
  return values;
}

const pinned = pinnedAccountId();
if (!pinned) {
  fail('the Wrangler config has no "account_id". Pin the account before deploying.');
}

if (existsSync(join(cwd, '.env'))) {
  fail(
    'this Worker folder has its own .env. Credentials live in one shared file, ' +
      `${sharedEnvPath}. Delete the per-Worker .env so two files cannot disagree.`,
  );
}
if (!existsSync(sharedEnvPath)) {
  fail(`the shared credentials file is missing: ${sharedEnvPath}`);
}

const dotenv = readDotEnv();
const token = process.env.CLOUDFLARE_API_TOKEN || dotenv.CLOUDFLARE_API_TOKEN;
const envAccount = process.env.CLOUDFLARE_ACCOUNT_ID || dotenv.CLOUDFLARE_ACCOUNT_ID;

if (!token) {
  fail(
    `CLOUDFLARE_API_TOKEN is empty. Add the WPCC account's token to ${sharedEnvPath}; ` +
      'otherwise Wrangler would use the global login, which may be a different account.',
  );
}
if (token === pinned || token === envAccount || /^[0-9a-f]{32}$/.test(token)) {
  fail(
    'CLOUDFLARE_API_TOKEN looks like an account or zone ID (32 hex characters), not an API ' +
      'token. Paste the API token itself (about 40 characters) on that line.',
  );
}
if (!envAccount) {
  fail(`CLOUDFLARE_ACCOUNT_ID is not set. Set it to ${pinned} in this folder's .env.`);
}
if (envAccount !== pinned) {
  fail(
    `CLOUDFLARE_ACCOUNT_ID (${envAccount}) does not match the account pinned in the ` +
      `Wrangler config (${pinned}).`,
  );
}

// Use this Worker's Wrangler, or a sibling Worker's when this folder has not run
// `npm install` yet, so the guard never downloads a different version.
const cloudflareRoot = dirname(sharedEnvPath);
const wranglerHome = [cwd, ...readdirSync(cloudflareRoot).map((name) => join(cloudflareRoot, name))].find(
  (folder) => existsSync(join(folder, 'node_modules', 'wrangler', 'package.json')),
);
if (!wranglerHome) {
  fail('Wrangler is not installed. Run `npm install` in a Worker folder first.');
}

// Run Wrangler's own entry point with node directly (no shell), so paths that
// contain spaces are passed through intact on every platform.
const wranglerBin = join(wranglerHome, 'node_modules', 'wrangler', 'bin', 'wrangler.js');
const run = (args) =>
  spawnSync(process.execPath, [wranglerBin, ...args, '--env-file', sharedEnvPath], {
    cwd: wranglerHome,
    encoding: 'utf8',
  });

const whoami = run(['whoami', '--json']);
if (whoami.status === 0) {
  let info;
  try {
    info = JSON.parse(whoami.stdout.slice(whoami.stdout.indexOf('{')));
  } catch {
    fail('could not read the output of wrangler whoami --json.');
  }
  const authType = String(info.authType ?? '').toLowerCase();
  if (authType && !authType.includes('api token')) {
    fail(`Wrangler is using "${info.authType}", not the API token from .env.`);
  }
  const accounts = Array.isArray(info.accounts) ? info.accounts : [];
  if (!accounts.some((account) => account.id === pinned)) {
    const seen =
      accounts.map((account) => `${account.name ?? 'account'} (${account.id})`).join(', ') ||
      'none';
    fail(`the token cannot access the pinned account ${pinned}. It can access: ${seen}.`);
  }
  const name = accounts.find((account) => account.id === pinned)?.name ?? 'account';
  console.log(`Account guard: OK. Using ${name} (${pinned}) with an API token.`);
} else {
  // Account-owned API tokens cannot be verified through the user endpoint that
  // whoami uses. Probe with a read-only call on the pinned account instead: it
  // only succeeds if the token is valid for exactly that account.
  const probe = run(['r2', 'bucket', 'list']);
  if (probe.status !== 0) {
    fail(
      'the token could not be verified (whoami failed, and a read-only R2 list on the ' +
        'pinned account failed). Check that the token is valid, not expired, and has ' +
        'Workers and R2 permissions for this account.',
    );
  }
  console.log(`Account guard: OK. The token works on the pinned account (${pinned}).`);
}
