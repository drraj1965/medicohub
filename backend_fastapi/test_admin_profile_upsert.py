from __future__ import annotations

import os
import sys
import tempfile
from pathlib import Path


BACKEND_DIR = Path(__file__).resolve().parent
PROJECT_DIR = BACKEND_DIR.parent
if str(PROJECT_DIR) not in sys.path:
    sys.path.insert(0, str(PROJECT_DIR))


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        os.environ["ENABLE_FIRESTORE"] = "0"

        from backend_fastapi import config, services, storage
        from backend_fastapi.models import UserProfileUpsertRequest

        storage.DATA_DIR = Path(tmp)
        storage.DB_PATH = storage.DATA_DIR / "db.json"
        storage.AUDIT_PATH = storage.DATA_DIR / "audit.log.jsonl"
        config.get_settings.cache_clear()
        services.repository._instance = None
        storage.ensure_data_files()

        first_sync = services.upsert_user_profile(
            UserProfileUpsertRequest(
                id="firebase-admin-uid",
                email="doctornerves@gmail.com",
                display_name="Rajshekher Garikapati",
                role="patient",
                verified=True,
                languages=["English"],
            )
        )

        assert first_sync["role"] == "admin"
        assert first_sync["display_name"] == "Dr. Rajshekher Garikapati"
        assert first_sync["doctor_status"] == "active"
        assert first_sync["can_manage_doctors"] is True
        assert first_sync["can_moderate_content"] is True

        db = storage.load_db()
        db["users"][0]["permissions"] = ["socialAccounts.manage"]
        storage.save_db(db)

        second_sync = services.upsert_user_profile(
            UserProfileUpsertRequest(
                id="firebase-admin-uid",
                email="doctornerves@gmail.com",
                display_name="Rajshekher Garikapati",
                role="patient",
                verified=True,
                languages=["English"],
            )
        )

        assert second_sync["role"] == "admin"
        assert second_sync["permissions"] == ["socialAccounts.manage"]
        print("Admin profile upsert regression test passed.")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
