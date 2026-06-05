from __future__ import annotations

import os
from typing import Any

import requests

from .base import ProviderResult, TranslationProvider
from ..language_map import LANGUAGES, normalize_lang


class HttpJsonTranslationProvider(TranslationProvider):
    def __init__(
        self,
        *,
        name: str,
        endpoint_env: str,
        api_key_env: str | None = None,
        timeout_seconds: int = 25,
        libretranslate_payload: bool = False,
    ) -> None:
        self.name = name
        self.endpoint_env = endpoint_env
        self.api_key_env = api_key_env
        self.timeout_seconds = timeout_seconds
        self.libretranslate_payload = libretranslate_payload

    @property
    def endpoint(self) -> str:
        return os.getenv(self.endpoint_env, "").strip()

    @property
    def api_key(self) -> str:
        return os.getenv(self.api_key_env or "", "").strip()

    def available(self) -> bool:
        return bool(self.endpoint)

    def translate(
        self,
        *,
        text: str,
        source_lang: str,
        target_lang: str,
        medical_mode: bool,
    ) -> ProviderResult:
        source = normalize_lang(source_lang)
        target = normalize_lang(target_lang)
        source_info = LANGUAGES[source]
        target_info = LANGUAGES[target]
        if self.libretranslate_payload:
            payload: dict[str, Any] = {
                "q": text,
                "source": source,
                "target": target,
                "format": "text",
            }
            if self.api_key:
                payload["api_key"] = self.api_key
        else:
            payload = {
                "text": text,
                "sourceLang": source,
                "targetLang": target,
                "sourceCode": source_info.indic_code or source_info.nllb_code,
                "targetCode": target_info.indic_code or target_info.nllb_code,
                "nllbSourceCode": source_info.nllb_code,
                "nllbTargetCode": target_info.nllb_code,
                "medicalMode": medical_mode,
            }
        headers = {"Content-Type": "application/json"}
        if self.api_key and not self.libretranslate_payload:
            headers["Authorization"] = f"Bearer {self.api_key}"
        response = requests.post(
            self.endpoint,
            json=payload,
            headers=headers,
            timeout=self.timeout_seconds,
        )
        response.raise_for_status()
        decoded = response.json()
        translated = (
            decoded.get("translatedText")
            or decoded.get("translation")
            or decoded.get("text")
            or decoded.get("result")
        )
        if not isinstance(translated, str) or not translated.strip():
            raise ValueError(f"{self.name} returned no translated text")
        return ProviderResult(translated.strip(), self.name)

