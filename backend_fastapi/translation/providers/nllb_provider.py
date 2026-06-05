from __future__ import annotations

from .http_json_provider import HttpJsonTranslationProvider


class NllbProvider(HttpJsonTranslationProvider):
    def __init__(self) -> None:
        super().__init__(
            name="nllb",
            endpoint_env="MEDICOHUB_NLLB_ENDPOINT",
            api_key_env="MEDICOHUB_NLLB_API_KEY",
        )

