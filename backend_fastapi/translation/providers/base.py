from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class ProviderResult:
    translated_text: str
    provider: str


class TranslationProvider:
    name = "base"

    def available(self) -> bool:
        raise NotImplementedError

    def translate(
        self,
        *,
        text: str,
        source_lang: str,
        target_lang: str,
        medical_mode: bool,
    ) -> ProviderResult:
        raise NotImplementedError

