from __future__ import annotations

import os

from .http_json_provider import HttpJsonTranslationProvider


class PaidFallbackProvider(HttpJsonTranslationProvider):
    def __init__(self) -> None:
        provider = os.getenv("MEDICOHUB_PAID_TRANSLATION_PROVIDER", "microsoft").strip().lower()
        endpoint_env = "MEDICOHUB_MICROSOFT_TRANSLATOR_ENDPOINT"
        key_env = "MEDICOHUB_MICROSOFT_TRANSLATOR_KEY"
        if provider == "google":
            endpoint_env = "MEDICOHUB_GOOGLE_TRANSLATE_ENDPOINT"
            key_env = "MEDICOHUB_GOOGLE_TRANSLATE_KEY"
        super().__init__(
            name=provider if provider in {"microsoft", "google"} else "paid",
            endpoint_env=endpoint_env,
            api_key_env=key_env,
            timeout_seconds=16,
        )

