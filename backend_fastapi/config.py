from __future__ import annotations

import os
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parent.parent
load_dotenv(ROOT / ".env")


def _as_bool(value: str | None, default: bool = False) -> bool:
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


@dataclass(frozen=True)
class Settings:
    app_env: str
    backend_host: str
    backend_port: int
    firebase_project_id: str
    google_service_account_json: str
    google_drive_parent_folder_id: str
    firebase_storage_bucket: str
    enable_firestore: bool
    enable_google_drive: bool
    enable_firebase_storage: bool
    smtp_host: str
    smtp_port: int
    smtp_username: str
    smtp_password: str
    smtp_sender_email: str
    email_username: str
    enable_smtp_tls: bool
    sendgrid_api_key: str
    sendgrid_sender_email: str
    twilio_account_sid: str
    twilio_auth_token: str
    twilio_from_phone: str
    twilio_whatsapp_number: str
    otp_code_ttl_minutes: int


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings(
        app_env=os.getenv("APP_ENV", "development"),
        backend_host=os.getenv("BACKEND_HOST", "127.0.0.1"),
        backend_port=int(os.getenv("BACKEND_PORT", "8012")),
        firebase_project_id=os.getenv("FIREBASE_PROJECT_ID", "").strip(),
        google_service_account_json=os.getenv("GOOGLE_SERVICE_ACCOUNT_JSON", "").strip(),
        google_drive_parent_folder_id=os.getenv("GOOGLE_DRIVE_PARENT_FOLDER_ID", "").strip(),
        firebase_storage_bucket=os.getenv("FIREBASE_STORAGE_BUCKET", "").strip(),
        enable_firestore=_as_bool(os.getenv("ENABLE_FIRESTORE"), False),
        enable_google_drive=_as_bool(os.getenv("ENABLE_GOOGLE_DRIVE"), False),
        enable_firebase_storage=_as_bool(os.getenv("ENABLE_FIREBASE_STORAGE"), False),
        smtp_host=os.getenv("SMTP_HOST", "").strip(),
        smtp_port=int(os.getenv("SMTP_PORT", "587")),
        smtp_username=(os.getenv("SMTP_USERNAME") or os.getenv("EMAIL_USERNAME") or "").strip(),
        smtp_password=os.getenv("SMTP_PASSWORD", "").strip(),
        smtp_sender_email=(os.getenv("SMTP_SENDER_EMAIL") or os.getenv("EMAIL_USERNAME") or "").strip(),
        email_username=os.getenv("EMAIL_USERNAME", "").strip(),
        enable_smtp_tls=_as_bool(os.getenv("ENABLE_SMTP_TLS"), True),
        sendgrid_api_key=os.getenv("SENDGRID_API_KEY", "").strip(),
        sendgrid_sender_email=(
            os.getenv("SENDGRID_SENDER_EMAIL")
            or os.getenv("SMTP_SENDER_EMAIL")
            or os.getenv("EMAIL_USERNAME")
            or ""
        ).strip(),
        twilio_account_sid=os.getenv("TWILIO_ACCOUNT_SID", "").strip(),
        twilio_auth_token=os.getenv("TWILIO_AUTH_TOKEN", "").strip(),
        twilio_from_phone=os.getenv("TWILIO_FROM_PHONE", "").strip(),
        twilio_whatsapp_number=os.getenv("TWILIO_WHATSAPP_NUMBER", "").strip(),
        otp_code_ttl_minutes=int(os.getenv("OTP_CODE_TTL_MINUTES", "10")),
    )
