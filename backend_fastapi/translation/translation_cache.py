from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

try:
    from ..storage import DATA_DIR, ensure_data_files
except ImportError:  # pragma: no cover
    from storage import DATA_DIR, ensure_data_files  # type: ignore

from .medical_glossary import MEDICAL_GLOSSARY_VERSION


CACHE_PROVIDER_VERSION = "hybrid-router-2026-06-03"
CACHE_PATH = DATA_DIR / "translation_cache.json"
CACHEABLE_CONTENT_TYPES = {"article", "education", "caption", "public_notice"}


def is_cacheable_content(content_type: str) -> bool:
    return content_type.strip().lower() in CACHEABLE_CONTENT_TYPES


def translation_hash(
    *,
    source_lang: str,
    target_lang: str,
    normalized_text: str,
    provider_version: str = CACHE_PROVIDER_VERSION,
    medical_glossary_version: str = MEDICAL_GLOSSARY_VERSION,
) -> str:
    digest = hashlib.sha256()
    digest.update(source_lang.encode("utf-8"))
    digest.update(b"|")
    digest.update(target_lang.encode("utf-8"))
    digest.update(b"|")
    digest.update(normalized_text.encode("utf-8"))
    digest.update(b"|")
    digest.update(provider_version.encode("utf-8"))
    digest.update(b"|")
    digest.update(medical_glossary_version.encode("utf-8"))
    return digest.hexdigest()


def _load_cache() -> dict[str, Any]:
    ensure_data_files()
    if not CACHE_PATH.exists():
        CACHE_PATH.write_text("{}", encoding="utf-8")
    try:
        return json.loads(CACHE_PATH.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}


def _save_cache(cache: dict[str, Any]) -> None:
    ensure_data_files()
    CACHE_PATH.write_text(json.dumps(cache, indent=2, default=str), encoding="utf-8")


def get_cached_translation(cache_key: str) -> dict[str, Any] | None:
    return _load_cache().get(cache_key)


def save_cached_translation(cache_key: str, record: dict[str, Any]) -> None:
    cache = _load_cache()
    now = datetime.now(timezone.utc).isoformat()
    current = cache.get(cache_key, {})
    cache[cache_key] = {
        **current,
        **record,
        "updatedAt": now,
        "createdAt": current.get("createdAt", now),
        "reviewedByDoctor": current.get("reviewedByDoctor", False),
        "warningShown": True,
    }
    _save_cache(cache)

