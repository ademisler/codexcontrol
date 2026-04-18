from __future__ import annotations

import os
import shutil
from pathlib import Path


def appdata_directory() -> Path:
    appdata = os.environ.get("APPDATA")
    if appdata:
        return Path(appdata)
    return Path.home() / "AppData" / "Roaming"


APP_SUPPORT_DIRECTORY = appdata_directory() / "CodexGauge"
LEGACY_APP_SUPPORT_DIRECTORY = appdata_directory() / "CodexAccounts"
ACCOUNTS_FILE = APP_SUPPORT_DIRECTORY / "accounts.json"
SNAPSHOTS_FILE = APP_SUPPORT_DIRECTORY / "snapshots.json"
MANAGED_HOMES_DIRECTORY = APP_SUPPORT_DIRECTORY / "managed-homes"
AUTH_BACKUPS_DIRECTORY = APP_SUPPORT_DIRECTORY / "auth-backups"
AMBIENT_CODEX_HOME = Path.home() / ".codex"


def ensure_directories() -> None:
    if not APP_SUPPORT_DIRECTORY.exists() and LEGACY_APP_SUPPORT_DIRECTORY.exists():
        shutil.move(str(LEGACY_APP_SUPPORT_DIRECTORY), str(APP_SUPPORT_DIRECTORY))

    APP_SUPPORT_DIRECTORY.mkdir(parents=True, exist_ok=True)
    MANAGED_HOMES_DIRECTORY.mkdir(parents=True, exist_ok=True)
    AUTH_BACKUPS_DIRECTORY.mkdir(parents=True, exist_ok=True)
