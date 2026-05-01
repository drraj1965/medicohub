from __future__ import annotations

import io
import re
from typing import Any

import requests
from pypdf import PdfReader


class PdfIngestionService:
    def extract_text_preview(self, content: bytes, max_chars: int = 1500) -> str:
        reader = PdfReader(io.BytesIO(content))
        text_parts: list[str] = []
        for page in reader.pages[:3]:
            try:
                text_parts.append(page.extract_text() or "")
            except Exception:
                continue
        joined = "\n".join(part.strip() for part in text_parts if part.strip())
        return joined[:max_chars]

    def resolve_pdf_url(self, pmc_id: str, article_url: str | None = None) -> str | None:
        pmc_id = pmc_id.strip()
        if not pmc_id:
            return None
        article_url = article_url or f"https://www.ncbi.nlm.nih.gov/pmc/articles/{pmc_id}/"
        html = self._fetch_text(article_url)
        if html:
            extracted = self._extract_pdf_url_from_html(html, pmc_id)
            if extracted:
                return extracted
        return f"https://pmc.ncbi.nlm.nih.gov/articles/{pmc_id}/pdf/main.pdf"

    def _fetch_text(self, url: str) -> str | None:
        try:
            response = requests.get(url, headers={"User-Agent": "Mozilla/5.0"}, timeout=20)
            response.raise_for_status()
            return response.text
        except Exception:
            return None

    def _extract_pdf_url_from_html(self, html: str, pmc_id: str) -> str | None:
        patterns = [
            re.compile(r'href="([^"]*/pdf/[^"]+\.pdf)"', re.IGNORECASE),
            re.compile(r"href='([^']*/pdf/[^']+\.pdf)'", re.IGNORECASE),
            re.compile(r'data-pdf-url="([^"]+\.pdf)"', re.IGNORECASE),
            re.compile(r"data-pdf-url='([^']+\.pdf)'", re.IGNORECASE),
            re.compile(
                rf'https://pmc\.ncbi\.nlm\.nih\.gov/articles/{re.escape(pmc_id)}/pdf/[A-Za-z0-9._-]+\.pdf',
                re.IGNORECASE,
            ),
        ]
        for pattern in patterns:
            match = pattern.search(html)
            if not match:
                continue
            raw = match.group(1) if match.groups() else match.group(0)
            return self._normalize_pdf_url(raw, pmc_id)
        return None

    def _normalize_pdf_url(self, raw: str, pmc_id: str) -> str:
        if raw.startswith(("http://", "https://")):
            return raw
        if raw.startswith("//"):
            return f"https:{raw}"
        if raw.startswith("/"):
            return f"https://pmc.ncbi.nlm.nih.gov{raw}"
        return f"https://pmc.ncbi.nlm.nih.gov/articles/{pmc_id}/{raw}"
