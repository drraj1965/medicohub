from __future__ import annotations

import os
from urllib.parse import urljoin

import requests

from .base import ProviderResult, TranslationProvider


class MicrosoftTranslatorProvider(TranslationProvider):
    name = "microsoft"

    def __init__(self) -> None:
        self._provider = os.getenv("TRANSLATION_PROVIDER", "").strip().lower()
        self._key = os.getenv("AZURE_TRANSLATOR_KEY", "").strip()
        self._region = os.getenv("AZURE_TRANSLATOR_REGION", "").strip()
        self._endpoint = os.getenv(
            "AZURE_TRANSLATOR_ENDPOINT",
            "https://api.cognitive.microsofttranslator.com",
        ).strip()

    def available(self) -> bool:
        return (
            self._provider == "microsoft"
            and bool(self._key)
            and bool(self._region)
            and bool(self._endpoint)
        )

    def configuration_error(self) -> str:
        if self._provider != "microsoft":
            return "Translation backend is not configured. Please add Microsoft Translator credentials."
        missing = []
        if not self._key:
            missing.append("AZURE_TRANSLATOR_KEY")
        if not self._region:
            missing.append("AZURE_TRANSLATOR_REGION")
        if not self._endpoint:
            missing.append("AZURE_TRANSLATOR_ENDPOINT")
        if missing:
            return (
                "Translation backend is not configured. Please add Microsoft Translator credentials. "
                f"Missing: {', '.join(missing)}."
            )
        return ""

    def translate(
        self,
        *,
        text: str,
        source_lang: str,
        target_lang: str,
        medical_mode: bool,
    ) -> ProviderResult:
        if not self.available():
            raise RuntimeError(self.configuration_error())

        endpoint = urljoin(self._endpoint.rstrip("/") + "/", "translate")
        text_type = "html" if text.lstrip().startswith("<") else "plain"
        response = requests.post(
            endpoint,
            params={
                "api-version": "3.0",
                "from": source_lang,
                "to": target_lang,
                "textType": text_type,
            },
            headers={
                "Ocp-Apim-Subscription-Key": self._key,
                "Ocp-Apim-Subscription-Region": self._region,
                "Content-Type": "application/json",
            },
            json=[{"Text": text}],
            timeout=16,
        )
        response.raise_for_status()
        data = response.json()
        try:
            translated = data[0]["translations"][0]["text"]
        except (IndexError, KeyError, TypeError) as exc:
            raise RuntimeError("Microsoft Translator returned an unexpected response.") from exc
        return ProviderResult(translated_text=str(translated), provider=self.name)
