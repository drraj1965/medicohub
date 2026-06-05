from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class LanguageInfo:
    app_code: str
    label: str
    nllb_code: str
    indic_code: str | None = None
    is_indic: bool = False
    is_right_to_left: bool = False


LANGUAGES: dict[str, LanguageInfo] = {
    "en": LanguageInfo("en", "English", "eng_Latn", "eng_Latn"),
    "hi": LanguageInfo("hi", "Hindi", "hin_Deva", "hin_Deva", True),
    "te": LanguageInfo("te", "Telugu", "tel_Telu", "tel_Telu", True),
    "ta": LanguageInfo("ta", "Tamil", "tam_Taml", "tam_Taml", True),
    "ml": LanguageInfo("ml", "Malayalam", "mal_Mlym", "mal_Mlym", True),
    "kn": LanguageInfo("kn", "Kannada", "kan_Knda", "kan_Knda", True),
    "gu": LanguageInfo("gu", "Gujarati", "guj_Gujr", "guj_Gujr", True),
    "bn": LanguageInfo("bn", "Bengali", "ben_Beng", "ben_Beng", True),
    "mr": LanguageInfo("mr", "Marathi", "mar_Deva", "mar_Deva", True),
    "pa": LanguageInfo("pa", "Punjabi", "pan_Guru", "pan_Guru", True),
    "or": LanguageInfo("or", "Odia", "ory_Orya", "ory_Orya", True),
    "as": LanguageInfo("as", "Assamese", "asm_Beng", "asm_Beng", True),
    "ur": LanguageInfo("ur", "Urdu", "urd_Arab", "urd_Arab", True, True),
    "sa": LanguageInfo("sa", "Sanskrit", "san_Deva", "san_Deva", True),
    "ar": LanguageInfo("ar", "Arabic", "arb_Arab", None, False, True),
    "fr": LanguageInfo("fr", "French", "fra_Latn"),
    "es": LanguageInfo("es", "Spanish", "spa_Latn"),
    "zh": LanguageInfo("zh", "Mandarin", "zho_Hans"),
}


def normalize_lang(code: str | None, fallback: str = "en") -> str:
    clean = (code or fallback).strip().lower()
    if clean == "auto":
        return fallback
    if clean in LANGUAGES:
        return clean
    root = clean.split("-")[0].split("_")[0]
    return root if root in LANGUAGES else fallback


def is_indic_pair(source_lang: str, target_lang: str) -> bool:
    source = LANGUAGES.get(normalize_lang(source_lang))
    target = LANGUAGES.get(normalize_lang(target_lang))
    return bool(source and target and (source.is_indic or target.is_indic))


def involves_arabic(source_lang: str, target_lang: str) -> bool:
    return normalize_lang(source_lang) == "ar" or normalize_lang(target_lang) == "ar"

