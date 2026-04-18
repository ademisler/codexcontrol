# CodexGauge

Fast, Codex-only quota tracking for macOS.

CodexGauge is a lightweight menu bar app for people who manage multiple Codex accounts and need accurate quota visibility without a heavy multi-provider dashboard.

## What it does

- Tracks Codex accounts only
- Reads quota directly from OpenAI usage endpoints
- Shows separate `5 Saat` and `7 Gün` windows when the account exposes both
- Shows exact reset times for each window
- Refreshes automatically every 5 minutes
- Supports manual refresh
- Lets you add and re-authenticate accounts from inside the app
- Lets you cancel an in-progress login flow from the app

## Why it exists

Most quota tools are either broad multi-provider dashboards or depend on extra browser/dashboard layers. CodexGauge is intentionally narrow:

- one provider
- small UI
- fast refresh path
- local-first account storage

## Accuracy model

CodexGauge fetches live quota data directly from OpenAI using the account's local Codex auth state.

To reduce stale or inconsistent readings:

- network requests use an ephemeral, no-cache session
- live reads are verified across multiple fetches
- inconsistent results are rejected instead of shown as current truth
- stale snapshots are cleared on refresh failures

## Privacy

CodexGauge does not ship your local accounts or tokens anywhere.

- account data stays on your Mac
- the app reads `auth.json` from per-account Codex homes
- repo source does not include any user tokens, account files, or local snapshots

App data is stored under:

- `~/Library/Application Support/CodexGauge`

If you are upgrading from the earlier local build, the app migrates data from:

- `~/Library/Application Support/CodexAccounts`

## Build

```bash
swift build
./Scripts/package_app.sh
open ./Build/CodexGauge.app
```

## Requirements

- macOS 14+
- a working `codex` CLI installation

## License

MIT
