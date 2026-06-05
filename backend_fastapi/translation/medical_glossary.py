from __future__ import annotations

import re
from dataclasses import dataclass


PROTECTED_TERMS = [
    "MedicoHub",
    "MRI",
    "CT scan",
    "EEG",
    "EMG",
    "ECG",
]

MEDICAL_GLOSSARY_VERSION = "2026-06-03"


@dataclass(frozen=True)
class ProtectedText:
    text: str
    placeholders: dict[str, str]


def protect_medical_text(text: str) -> ProtectedText:
    placeholders: dict[str, str] = {}

    def reserve(value: str) -> str:
        key = f"__MH_TERM_{len(placeholders)}__"
        placeholders[key] = value
        return key

    protected = re.sub(r"https?://[^\s)\]]+", lambda match: reserve(match.group(0)), text)
    protected = re.sub(r"\b\d+(?:\.\d+)?\s?(?:mg|mcg|g|ml|kg|cm|mmHg|units?)\b", lambda match: reserve(match.group(0)), protected, flags=re.IGNORECASE)
    for term in PROTECTED_TERMS:
        protected = re.sub(re.escape(term), lambda match: reserve(match.group(0)), protected)
    return ProtectedText(protected, placeholders)


def restore_medical_text(text: str, placeholders: dict[str, str]) -> str:
    restored = text
    for key, value in placeholders.items():
        restored = restored.replace(key, value)
    return restored

