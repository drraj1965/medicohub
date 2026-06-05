from __future__ import annotations

from .http_json_provider import HttpJsonTranslationProvider


class LibreTranslateProvider(HttpJsonTranslationProvider):
    def __init__(self) -> None:
        super().__init__(
            name="libretranslate",
            endpoint_env="MEDICOHUB_LIBRETRANSLATE_ENDPOINT",
            api_key_env="MEDICOHUB_LIBRETRANSLATE_API_KEY",
            timeout_seconds=16,
            libretranslate_payload=True,
        )

