from __future__ import annotations

import sys
from pathlib import Path

from fastapi.testclient import TestClient


BACKEND_DIR = Path(__file__).resolve().parent
PROJECT_DIR = BACKEND_DIR.parent
if str(PROJECT_DIR) not in sys.path:
    sys.path.insert(0, str(PROJECT_DIR))

from backend_fastapi.main import app  # noqa: E402


TEST_TEXT = "This article explains migraine, stroke, epilepsy and vertigo."
TARGET_LANGUAGES = ("hi", "te", "ml", "ta", "ar")


def main() -> int:
    client = TestClient(app)
    failed = False
    for target_lang in TARGET_LANGUAGES:
        response = client.post(
            "/api/translate",
            json={
                "text": TEST_TEXT,
                "sourceLang": "en",
                "targetLang": target_lang,
            },
        )
        print(f"\nEnglish -> {target_lang}")
        print(f"HTTP {response.status_code}")
        data = response.json()
        print(f"provider={data.get('provider')}")
        print(f"cached={data.get('cached')}")
        print(f"sourceLang={data.get('sourceLang')}")
        print(f"targetLang={data.get('targetLang')}")
        if data.get("errorMessage"):
            print(f"errorMessage={data.get('errorMessage')}")
        translated_text = str(data.get("translatedText") or "")
        print(f"translatedText={translated_text}")
        if response.status_code != 200 or data.get("errorMessage"):
            failed = True
        elif not translated_text.strip() or translated_text.strip().casefold() == TEST_TEXT.casefold():
            print("errorMessage=Translation failed: provider returned unchanged text.")
            failed = True
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
