from __future__ import annotations


DEFAULT_MEDICAL_WARNING = (
    "Machine translation may contain errors. For medical decisions, consult a doctor."
)


def quality_warning(provider: str, medical_mode: bool, low_quality: bool = False) -> str:
    if not medical_mode:
        return "Automatic translation may contain errors."
    if low_quality:
        return (
            "This is a fallback machine translation and may not be medically precise. "
            "For medical decisions, consult a doctor."
        )
    if provider == "cache":
        return DEFAULT_MEDICAL_WARNING
    return DEFAULT_MEDICAL_WARNING

