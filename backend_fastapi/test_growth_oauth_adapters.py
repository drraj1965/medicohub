from __future__ import annotations

import base64
import os
import sys
import tempfile
from pathlib import Path
from typing import Any


BACKEND_DIR = Path(__file__).resolve().parent
PROJECT_DIR = BACKEND_DIR.parent
if str(PROJECT_DIR) not in sys.path:
    sys.path.insert(0, str(PROJECT_DIR))


class FakeResponse:
    def __init__(self, payload: dict[str, Any], status_code: int = 200) -> None:
        self._payload = payload
        self.status_code = status_code
        self.text = str(payload)

    def json(self) -> dict[str, Any]:
        return self._payload


def _fake_post(url: str, data: dict[str, Any] | None = None, **kwargs: Any) -> FakeResponse:
    if url.endswith("/oauth/v2/accessToken"):
        assert data and data["client_id"] == "linkedin-client"
        assert data["client_secret"] == "linkedin-secret"
        return FakeResponse({"access_token": "linkedin-access-token", "expires_in": 3600})
    if url == "https://oauth2.googleapis.com/token":
        assert data and data["client_id"] == "google-client"
        assert data["client_secret"] == "google-secret"
        return FakeResponse({"access_token": "google-access-token", "refresh_token": "google-refresh", "expires_in": 3600})
    if url == "https://api.x.com/2/oauth2/token":
        assert kwargs.get("auth") == ("x-client", "x-secret")
        assert data and data["grant_type"] == "authorization_code"
        assert data["code_verifier"]
        assert "client_id" not in data
        return FakeResponse({"access_token": "x-access-token", "refresh_token": "x-refresh", "expires_in": 7200})
    raise AssertionError(f"Unexpected POST {url}")


def _fake_get(url: str, params: dict[str, Any] | None = None, **_: Any) -> FakeResponse:
    if url == "https://api.linkedin.com/v2/userinfo":
        return FakeResponse({"sub": "linkedin-member-1", "name": "MedicoHub Admin"})
    if url == "https://api.linkedin.com/rest/organizationAcls":
        return FakeResponse(
            {
                "elements": [
                    {
                        "role": "ADMINISTRATOR",
                        "state": "APPROVED",
                        "organization": "urn:li:organization:123456",
                        "organization~": {"localizedName": "MedicoHub"},
                    }
                ]
            }
        )
    if url.endswith("/oauth/access_token"):
        assert params and params["client_id"] == "meta-client"
        assert params["client_secret"] == "meta-secret"
        return FakeResponse({"access_token": "meta-user-token", "expires_in": 7200})
    if url == "https://graph.facebook.com/v21.0/me/accounts":
        return FakeResponse(
            {
                "data": [
                    {
                        "id": "fb-page-1",
                        "name": "MedicoHub",
                        "access_token": "meta-page-token",
                        "tasks": ["CREATE_CONTENT", "MANAGE"],
                        "instagram_business_account": {
                            "id": "ig-business-1",
                            "username": "medicohub",
                        },
                    }
                ]
            }
        )
    if url == "https://www.googleapis.com/youtube/v3/channels":
        assert params and params["mine"] == "true"
        return FakeResponse(
            {
                "items": [
                    {
                        "id": "youtube-channel-1",
                        "snippet": {"title": "MedicoHub"},
                    }
                ]
            }
        )
    if url == "https://api.x.com/2/users/me":
        return FakeResponse(
            {
                "data": {
                    "id": "x-user-1",
                    "name": "MedicoHub",
                    "username": "medicohub",
                }
            }
        )
    raise AssertionError(f"Unexpected GET {url}")


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        os.environ["ENABLE_FIRESTORE"] = "0"
        os.environ["MEDICOHUB_PUBLIC_API_BASE_URL"] = "https://medicohub-backend.fly.dev"
        os.environ["MEDICOHUB_PRINCIPAL_ADMIN_USER_ID"] = "owner"
        os.environ["LINKEDIN_CLIENT_ID"] = "linkedin-client"
        os.environ["LINKEDIN_CLIENT_SECRET"] = "linkedin-secret"
        os.environ["META_CLIENT_ID"] = "meta-client"
        os.environ["META_CLIENT_SECRET"] = "meta-secret"
        os.environ["GOOGLE_OAUTH_CLIENT_ID"] = "google-client"
        os.environ["GOOGLE_OAUTH_CLIENT_SECRET"] = "google-secret"
        os.environ["X_CLIENT_ID"] = "x-client"
        os.environ["X_CLIENT_SECRET"] = "x-secret"
        os.environ["MEDICOHUB_TOKEN_ENCRYPTION_KEY"] = base64.urlsafe_b64encode(os.urandom(32)).decode("utf-8")

        from backend_fastapi import config, services, storage
        from backend_fastapi.models import GrowthIntegrationCreate, GrowthIntegrationOAuthStart

        storage.DATA_DIR = Path(tmp)
        storage.DB_PATH = storage.DATA_DIR / "db.json"
        storage.AUDIT_PATH = storage.DATA_DIR / "audit.log.jsonl"
        config.get_settings.cache_clear()
        services.repository._instance = None
        storage.ensure_data_files()
        db = storage.load_db()
        db["users"].append(
            {
                "id": "owner",
                "email": "owner@medicohub.test",
                "role": "admin",
                "permissions": [],
            }
        )
        storage.save_db(db)

        services.requests.post = _fake_post
        services.requests.get = _fake_get

        for provider in ["linkedin", "meta", "youtube", "x"]:
            connection = services.create_growth_integration(
                GrowthIntegrationCreate(
                    actor_id="owner",
                    provider=provider,
                    auth_mode="oauth2",
                )
            )
            start = services.start_growth_integration_oauth(
                connection["id"],
                GrowthIntegrationOAuthStart(actor_id="owner"),
            )
            assert "authorization_url" in start
            assert start["state"]
            if provider == "x":
                assert "code_challenge=" in start["authorization_url"]
                assert "code_challenge_method=S256" in start["authorization_url"]

            result = services.complete_growth_integration_oauth(provider, start["state"], f"{provider}-code")
            assert result["status"] == "connected"
            assert result["available_accounts"], provider
            if provider == "linkedin":
                assert result["available_accounts"][0]["external_account_type"] == "linkedin_organization_page"
            if provider == "x":
                assert result["available_accounts"][0]["external_account_type"] == "x_user"

            records = services.list_growth_integrations("owner")
            updated = next(item for item in records if item["provider"] == provider)
            assert updated["connection_status"] == "connected"
            assert updated["token_status"] == "token_reference_configured"
            assert "token_reference" not in updated
            assert "oauth_state" not in updated
            assert "oauth_code_verifier" not in updated

            health = services.test_growth_integration_connection(connection["id"], "owner")
            assert health["status"] in {"healthy", "needs_attention"}
            assert health["token_ready"] is True

        vault = storage.load_db()["social_token_vault"]
        assert len(vault) == 4
        assert all("access-token" not in item["encrypted_payload"] for item in vault)
        print("Growth OAuth adapter smoke test passed.")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
