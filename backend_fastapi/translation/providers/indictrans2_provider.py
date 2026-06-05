from __future__ import annotations

from .http_json_provider import HttpJsonTranslationProvider


class IndicTrans2Provider(HttpJsonTranslationProvider):
    def __init__(self) -> None:
        super().__init__(
            name="indictrans2",
            endpoint_env="MEDICOHUB_INDICTRANS2_ENDPOINT",
            api_key_env="MEDICOHUB_INDICTRANS2_API_KEY",
        )

