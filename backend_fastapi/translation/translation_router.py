from __future__ import annotations

from dataclasses import dataclass
import os

from .language_map import normalize_lang
from .medical_glossary import protect_medical_text, restore_medical_text
from .providers.base import TranslationProvider
from .providers.libretranslate_provider import LibreTranslateProvider
from .providers.microsoft_provider import MicrosoftTranslatorProvider
from .quality_checks import quality_warning
from .translation_cache import (
    CACHE_PROVIDER_VERSION,
    get_cached_translation,
    is_cacheable_content,
    save_cached_translation,
    translation_hash,
)


MAX_TRANSLATION_CHARS = 5000


@dataclass(frozen=True)
class TranslationPayload:
    text: str
    source_lang: str
    target_lang: str
    content_type: str
    medical_mode: bool = True
    allow_paid_fallback: bool = False


def provider_chain(payload: TranslationPayload) -> list[TranslationProvider]:
    chain: list[TranslationProvider] = [MicrosoftTranslatorProvider()]
    if os.getenv("ENABLE_LIBRETRANSLATE_FALLBACK", "").strip().lower() == "true":
        chain.append(LibreTranslateProvider())
    return chain


def translate_payload(payload: TranslationPayload) -> dict:
    source_lang = normalize_lang(payload.source_lang)
    target_lang = normalize_lang(payload.target_lang)
    normalized_text = " ".join(payload.text.strip().split())
    if not normalized_text:
        return _response("", "none", source_lang, target_lang, "", "", False)
    if len(normalized_text) > MAX_TRANSLATION_CHARS:
        return _response(
            "",
            "none",
            source_lang,
            target_lang,
            "Please translate shorter sections at a time.",
            "Please translate shorter sections at a time.",
            False,
        )
    if source_lang == target_lang:
        return _response(payload.text, "none", source_lang, target_lang, "", "", False)

    cache_key = translation_hash(
        source_lang=source_lang,
        target_lang=target_lang,
        normalized_text=normalized_text,
        provider_version=CACHE_PROVIDER_VERSION,
    )
    cacheable = is_cacheable_content(payload.content_type)
    if cacheable:
        cached = get_cached_translation(cache_key)
        if cached and cached.get("translatedText"):
            provider = str(cached.get("provider") or "microsoft")
            return _response(
                str(cached["translatedText"]),
                provider,
                source_lang,
                target_lang,
                quality_warning(provider, payload.medical_mode),
                "",
                True,
            )

    protected = protect_medical_text(payload.text)
    errors: list[str] = []
    configured_providers = [provider for provider in provider_chain(payload) if provider.available()]
    if not configured_providers:
        microsoft = MicrosoftTranslatorProvider()
        error = microsoft.configuration_error()
        if not error:
            error = "Translation backend is not configured. Please add Microsoft Translator credentials."
        return _response("", "none", source_lang, target_lang, error, error, False)
    for provider in configured_providers:
        try:
            result = provider.translate(
                text=protected.text,
                source_lang=source_lang,
                target_lang=target_lang,
                medical_mode=payload.medical_mode,
            )
            translated = restore_medical_text(result.translated_text, protected.placeholders)
            if _same_text(translated, payload.text):
                error = "Translation failed: provider returned unchanged text."
                return _response(
                    translated,
                    result.provider,
                    source_lang,
                    target_lang,
                    error,
                    error,
                    False,
                )
            warning = quality_warning(
                result.provider,
                payload.medical_mode,
                low_quality=result.provider == "libretranslate",
            )
            if cacheable:
                save_cached_translation(
                    cache_key,
                    {
                        "originalTextHash": cache_key,
                        "sourceLang": source_lang,
                        "targetLang": target_lang,
                        "translatedText": translated,
                        "provider": result.provider,
                        "contentType": payload.content_type,
                    },
                )
            return _response(translated, result.provider, source_lang, target_lang, warning, "", False)
        except Exception as exc:  # noqa: BLE001 - providers are intentionally isolated.
            errors.append(f"{provider.name}: {exc}")

    warning = (
        "Translation failed. Microsoft Translator is configured, but the provider request did not complete."
    )
    if errors:
        warning = f"{warning} Last provider error: {errors[-1]}"
    return _response("", "microsoft", source_lang, target_lang, warning, warning, False)


def _same_text(translated_text: str, original_text: str) -> bool:
    return " ".join(translated_text.strip().split()).casefold() == " ".join(
        original_text.strip().split()
    ).casefold()


def _response(
    translated_text: str,
    provider: str,
    source_lang: str,
    target_lang: str,
    warning: str,
    error_message: str,
    cached: bool,
) -> dict:
    return {
        "translatedText": translated_text,
        "provider": provider,
        "sourceLang": source_lang,
        "targetLang": target_lang,
        "qualityWarning": warning,
        "errorMessage": error_message,
        "cached": cached,
    }
