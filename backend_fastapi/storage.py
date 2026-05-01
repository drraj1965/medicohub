from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


if getattr(sys, "frozen", False):
    DATA_DIR = Path(sys.executable).resolve().parent / "backend_data"
else:
    DATA_DIR = Path(__file__).parent / "data"
DB_PATH = DATA_DIR / "db.json"
AUDIT_PATH = DATA_DIR / "audit.log.jsonl"


def ensure_data_files() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    if not DB_PATH.exists():
        DB_PATH.write_text(
            json.dumps(
                {
                    "users": [],
                    "questions": [],
                    "attachments": [],
                    "education": [],
                    "payments": [],
                    "title_templates": [],
                    "blog_articles": [],
                    "notifications": [],
                    "otp_requests": [],
                    "notification_settings": {},
                },
                indent=2,
            ),
            encoding="utf-8",
        )
    if not AUDIT_PATH.exists():
        AUDIT_PATH.write_text("", encoding="utf-8")


def load_db() -> dict[str, Any]:
    ensure_data_files()
    db = json.loads(DB_PATH.read_text(encoding="utf-8"))
    changed = False
    for key in [
        "users",
        "questions",
        "attachments",
        "education",
        "payments",
        "title_templates",
        "blog_articles",
        "notifications",
        "otp_requests",
        "notification_settings",
    ]:
        if key not in db:
            db[key] = {} if key == "notification_settings" else []
            changed = True
    if changed:
        save_db(db)
    return db


def save_db(db: dict[str, Any]) -> None:
    DB_PATH.write_text(json.dumps(db, indent=2, default=str), encoding="utf-8")


def append_audit(event: dict[str, Any]) -> None:
    ensure_data_files()
    with AUDIT_PATH.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(event, default=str) + "\n")


def read_audit(limit: int = 200) -> list[dict[str, Any]]:
    ensure_data_files()
    lines = AUDIT_PATH.read_text(encoding="utf-8").splitlines()
    return [json.loads(line) for line in lines[-limit:]]
