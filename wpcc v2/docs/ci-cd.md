# CI/CD

Automated checks and deploys run on GitHub Actions. The workflows live in the
repository root, `.github/workflows/` (GitHub only reads workflows from there,
not from `wpcc v2/.github/`).

| Workflow | Runs when | What it does |
| --- | --- | --- |
| `wpcc-v2-ci.yml` | Every pull request and every push to `v2` or `dev` that touches `wpcc v2/`; also called by the deploy workflow | Analyze (errors fail, lints and warnings do not), browser script tests, `flutter test`, a release web build, and the media worker's type check and tests |
| `wpcc-v2-deploy.yml` | Push to `v2` that touches `wpcc v2/`, or run by hand | Runs the CI workflow, then publishes the build that passed to https://my.wisdompowercc.org on Vercel, and checks the live site |
| `wpcc-v2-media-worker-deploy.yml` | Push to `v2` that touches `wpcc v2/cloudflare/media-sync/` or the shared Cloudflare scripts, or run by hand | Type check and tests, the Cloudflare account guard, D1 migrations, then `wrangler deploy`, then checks the live API |

## Code and dependency analysis

| Check | Where | What it finds |
| --- | --- | --- |
| `flutter analyze` | `wpcc-v2-ci.yml` | Dart errors, unused code, style problems in the app (errors fail the build; lints and warnings are reported) |
| `tsc` | `wpcc-v2-ci.yml` | Type errors in the media worker |
| `npm audit --omit=dev` | `wpcc-v2-ci.yml` | Known high-severity vulnerabilities in the libraries the worker ships with |
| CodeQL | `wpcc-v2-codeql.yml` | Security problems (injection, unsafe input handling, leaked secrets) in the JavaScript and TypeScript: the media worker, `web/` scripts and `tool/`. On pull requests, pushes to `v2`, and weekly. Results are under Security, Code scanning. CodeQL does not support Dart, so the Flutter app is covered by `flutter analyze` |
| Dependabot | `.github/dependabot.yml` | Weekly pull requests for newer or security-patched versions of the GitHub Actions, the worker's npm packages and the app's Dart packages |

Also worth switching on in the repository settings (Settings, Code security):
secret scanning and push protection (free on public repositories), and
Dependabot alerts.

## Why the build happens in GitHub, not on Vercel

Vercel's build machines do not have Flutter. The pipeline builds the app in
CI, trims it (`tool/trim_web_build.cjs`), stages it as a Vercel prebuilt output
(`tool/stage_vercel_output.mjs`, which also writes the cache headers and the
share-link proxy to the media worker), and uploads that with
`vercel deploy --prebuilt --prod`. The tests run on the Dart VM and cannot see
errors in browser-only code, which is why the release build is part of CI.

## One-time setup (done in GitHub, never in chat)

Add these under **Settings, Secrets and variables, Actions, New repository
secret** (or with `gh secret set <NAME>`, which asks for the value):

| Secret | Where to get it | Used by |
| --- | --- | --- |
| `VERCEL_TOKEN` | https://vercel.com/account/tokens, scoped to the `igbaniangus-gmailcom's projects` team | Vercel deploy |
| `CLOUDFLARE_API_TOKEN` | Cloudflare dashboard, API tokens, for the WPCC account. It needs Workers Scripts edit, D1 edit, R2 edit, Queues edit and Zone read (the same permissions as the token in `cloudflare/.env`) | Media worker deploy |

The app is the Vercel project `wpcc-community` (it replaced the older `web` project, which was part of a microfrontends group that links projects by name and so could not be renamed). The Vercel team and project ids and the Cloudflare account id are identifiers,
not secrets, and are written in the workflow files. The Cloudflare account guard
(`cloudflare/scripts/assert-account.mjs`) still stops the deploy if the token
belongs to a different account.

Both deploy workflows only publish from the `v2` branch: each deploy job has an
`if: github.ref == 'refs/heads/v2'` guard, so starting one by hand from another
branch does nothing. This works on every GitHub plan. Secrets belong to this
repository only; any other repository that deploys needs its own copies.

Optional but recommended:

* **Settings, Environments, `production`**: restrict Deployment branches to `v2`
  and add required reviewers if a person should approve each production deploy.
  Both deploy workflows use this environment. (On a private repository these
  environment rules need a paid GitHub plan; the branch guard above works
  without one.)
* **Settings, Branches, branch protection for `v2`**: require the
  `WPCC v2 CI` checks (`App (analyze, test, build)` and
  `Media worker (types, tests)`) and a pull request before merging, so nothing
  reaches `v2` without passing them.

## Everyday use

1. Work on a branch and open a pull request into `v2`. CI runs on the pull
   request.
2. Merging to `v2` runs CI again, then deploys the app, and deploys the worker
   if its folder changed.
3. To redeploy without a code change, open **Actions**, pick the deploy
   workflow and choose **Run workflow**.
4. To roll back the app, redeploy an earlier deployment from the Vercel
   dashboard (Deployments, the three dots, Promote) or revert the commit.

## What is not automated

* **Supabase migrations** (`supabase/migrations/`) run on the self-hosted
  server and are applied by hand there.
* **Cloudflare Workers other than `media-sync`** (`rewards`, `auto-give-cron`)
  are not deployed in this account (the free plan allows five cron triggers).
* **Pull request preview deployments.** A preview URL is not in the media
  API's allowed origins, so the Media page would not load there. Add it only if
  a preview origin is added to `ALLOWED_ORIGINS`.
* The older `wpcc v2/.github/workflows/flutter_web.yml` is not read by GitHub
  (it is not in the repository root) and is superseded by
  `wpcc-v2-ci.yml`. It can be deleted.
