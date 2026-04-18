# CodexGauge for Windows

This folder contains a Windows implementation of CodexGauge that does not modify the existing macOS Swift app.

## What It Does

- Tracks Codex account quota from local `auth.json` state
- Runs as a Windows tray app with a dashboard window
- Supports add account, refresh, reauthenticate, open folder, and remove
- Persists accounts and cached snapshots under `%APPDATA%\\CodexGauge`
- Reuses the same live-read verification strategy as the macOS app

## Run Locally

```powershell
python -m pip install -r .\windows\requirements.txt
python .\windows\CodexGaugeWindows.pyw
```

Build a standalone EXE:

```powershell
powershell -ExecutionPolicy Bypass -File .\windows\build.ps1
```

Install the built EXE to `%LocalAppData%\Programs\CodexGauge` and register startup:

```powershell
powershell -ExecutionPolicy Bypass -File .\windows\install.ps1 -EnableStartup -Launch
```

If you prefer to keep a console open while debugging, run:

```powershell
python .\windows\CodexGaugeWindows.pyw
```

## Notes

- The app looks for `codex` on `PATH` first, then checks common Windows install locations.
- Managed accounts are stored under `%APPDATA%\\CodexGauge\\managed-homes`.
- Cached snapshots are restored on startup for faster first paint.
- The installer registers a startup shortcut with `--hidden`, so CodexGauge starts in the tray when Windows signs in.

## Tests

```powershell
$env:PYTHONPATH = (Resolve-Path .\windows)
python -m unittest discover .\windows\tests
```
