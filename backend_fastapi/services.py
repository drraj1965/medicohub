from __future__ import annotations

import os
import random
import secrets
import smtplib
import hashlib
import base64
import json
from html import escape
from datetime import datetime, timedelta, timezone
from email.message import EmailMessage
from urllib.parse import parse_qs, quote, urlencode, urlparse

from fastapi import HTTPException, UploadFile
from cryptography.fernet import Fernet, InvalidToken
import requests

try:
    from .models import (
        AdCampaignCreate,
        AdCampaignRecord,
        AdCampaignUpdate,
        AppSettings,
        AppSettingsUpdate,
        AttachmentCreate,
        AttachmentRecord,
        AuditEvent,
        BlogArticleCreate,
        BlogArticleCommentCreate,
        BlogArticleCommentRecord,
        BlogArticleRecord,
        BlogArticleLikeRequest,
        BlogArticleSectionRecord,
        BlogArticleUpdate,
        CommunicationPreferencesUpdate,
        ContentShareReport,
        ContentShareRequest,
        DEFAULT_QUESTION_TOPICS,
        DoctorInviteCreate,
        DoctorResponseInput,
        DoctorResponseRecord,
        EducationItem,
        GrowthCampaignCreate,
        GrowthCampaignRecord,
        GrowthCampaignUpdate,
        GrowthContentDerivativeCreate,
        GrowthContentDerivativeRecord,
        GrowthEventInput,
        GrowthEventRecord,
        GrowthIntegrationApprovalUpdate,
        GrowthIntegrationCreate,
        GrowthIntegrationOAuthStart,
        GrowthIntegrationRecord,
        GrowthIntegrationSelectionUpdate,
        GrowthOpportunityCreate,
        GrowthOpportunityRecord,
        GrowthPublishingApprovalUpdate,
        GrowthPublishingRequestCreate,
        GrowthPublishingRequestRecord,
        NotificationEvent,
        NotificationSettings,
        NotificationSettingsUpdate,
        OtpRequestInput,
        OtpRequestRecord,
        OtpVerifyInput,
        PaymentIntentRequest,
        PaymentIntentResponse,
        QuestionCreate,
        QuestionDeleteRequest,
        ResponseDeleteRequest,
        QuestionRecord,
        ThreadMessageInput,
        ThreadMessageModerationRequest,
        ThreadMessageRecord,
        SectionTranslationRequest,
        SectionTranslationResponse,
        TranslationRequest,
        TranslationResponse,
        QuestionUpdateRequest,
        TitleTemplate,
        TitleTemplateCreate,
        User,
        UserDeleteRequest,
        UserProfileUpsertRequest,
        UnsubscribeRequest,
        make_id,
        utc_now,
    )
    from .config import get_settings
    from .pdf_ingestion import PdfIngestionService
    from .providers import get_file_storage_provider, get_repository
    from .storage import append_audit
except ImportError:
    from models import (  # type: ignore
        AdCampaignCreate,
        AdCampaignRecord,
        AdCampaignUpdate,
        AppSettings,
        AppSettingsUpdate,
        AttachmentCreate,
        AttachmentRecord,
        AuditEvent,
        BlogArticleCreate,
        BlogArticleCommentCreate,
        BlogArticleCommentRecord,
        BlogArticleRecord,
        BlogArticleLikeRequest,
        BlogArticleSectionRecord,
        BlogArticleUpdate,
        CommunicationPreferencesUpdate,
        ContentShareReport,
        ContentShareRequest,
        DEFAULT_QUESTION_TOPICS,
        DoctorInviteCreate,
        DoctorResponseInput,
        DoctorResponseRecord,
        EducationItem,
        GrowthCampaignCreate,
        GrowthCampaignRecord,
        GrowthCampaignUpdate,
        GrowthContentDerivativeCreate,
        GrowthContentDerivativeRecord,
        GrowthEventInput,
        GrowthEventRecord,
        GrowthIntegrationApprovalUpdate,
        GrowthIntegrationCreate,
        GrowthIntegrationOAuthStart,
        GrowthIntegrationRecord,
        GrowthIntegrationSelectionUpdate,
        GrowthOpportunityCreate,
        GrowthOpportunityRecord,
        GrowthPublishingApprovalUpdate,
        GrowthPublishingRequestCreate,
        GrowthPublishingRequestRecord,
        NotificationEvent,
        NotificationSettings,
        NotificationSettingsUpdate,
        OtpRequestInput,
        OtpRequestRecord,
        OtpVerifyInput,
        PaymentIntentRequest,
        PaymentIntentResponse,
        QuestionCreate,
        QuestionDeleteRequest,
        ResponseDeleteRequest,
        QuestionRecord,
        ThreadMessageInput,
        ThreadMessageModerationRequest,
        ThreadMessageRecord,
        SectionTranslationRequest,
        SectionTranslationResponse,
        TranslationRequest,
        TranslationResponse,
        QuestionUpdateRequest,
        TitleTemplate,
        TitleTemplateCreate,
        User,
        UserDeleteRequest,
        UserProfileUpsertRequest,
        UnsubscribeRequest,
        make_id,
        utc_now,
    )
    from config import get_settings  # type: ignore
    from pdf_ingestion import PdfIngestionService  # type: ignore
    from providers import get_file_storage_provider, get_repository  # type: ignore
    from storage import append_audit  # type: ignore


class _LazyRepository:
    def __init__(self) -> None:
        self._instance = None

    def _get(self):
        if self._instance is None:
            self._instance = get_repository()
        return self._instance

    def __getattr__(self, name: str):
        return getattr(self._get(), name)


class _LazyFileStorage:
    def __init__(self) -> None:
        self._instance = None

    def _get(self):
        if self._instance is None:
            self._instance = get_file_storage_provider()
        return self._instance

    def __getattr__(self, name: str):
        return getattr(self._get(), name)


repository = _LazyRepository()
file_storage = _LazyFileStorage()
pdf_ingestion = PdfIngestionService()


ARTICLE_SECTION_LABELS = {
    "summary": "Summary",
    "patients": "For Patients",
    "doctors": "For Doctors",
    "citations": "Citations / References",
    "notes": "Additional Notes",
    "faq": "FAQ",
    "takeaways": "Key Takeaways",
    "disclaimer": "Disclaimer",
}

GROWTH_ADMIN_ROLES = {
    "superAdmin",
    "admin",
    "growthManager",
    "analyticsViewer",
}
GROWTH_MANAGER_ROLES = {"superAdmin", "admin", "growthManager"}
SOCIAL_ACCOUNTS_MANAGE_PERMISSION = "socialAccounts.manage"
SOCIAL_CONNECTIONS_COLLECTION = "social_connections"
SOCIAL_TOKEN_VAULT_COLLECTION = "social_token_vault"
GROWTH_SENSITIVE_METADATA_KEYS = {
    "question_text",
    "body",
    "message",
    "medical_notes",
    "diagnosis",
    "medications",
    "medicine",
    "symptoms",
    "symptom_text",
    "name",
    "email",
    "phone",
    "mobile",
    "address",
}
GROWTH_ACTIVATION_EVENTS = {
    "article_saved",
    "specialty_followed",
    "doctor_followed",
    "question_submitted",
    "article_comment_created",
    "comment_created",
    "migraine_entry_created",
    "vestibular_module_started",
    "digest_subscribed",
    "patient_profile_completed",
    "article_shared",
    "referral_created",
}
GROWTH_SOCIAL_CHANNELS: dict[str, dict] = {
    "manual_export": {
        "label": "Manual export",
        "auth_mode": "manual_export",
        "scopes": [],
        "supports_api_publish": False,
        "recommended": True,
        "notes": "Safest first step: copy, review, and post through the platform UI.",
    },
    "linkedin": {
        "label": "LinkedIn",
        "auth_mode": "oauth2",
        "auth_url": "https://www.linkedin.com/oauth/v2/authorization",
        "env_client_id": "LINKEDIN_CLIENT_ID",
        "env_client_secret": "LINKEDIN_CLIENT_SECRET",
        "token_url": "https://www.linkedin.com/oauth/v2/accessToken",
        "scopes": ["openid", "profile", "email"],
        "supports_api_publish": True,
        "recommended": True,
        "notes": "Connect the official LinkedIn identity first. Posting permissions can be added after LinkedIn product access or review is approved.",
    },
    "meta": {
        "label": "Meta: Facebook Page + Instagram",
        "auth_mode": "oauth2",
        "auth_url": "https://www.facebook.com/v21.0/dialog/oauth",
        "env_client_id": "META_CLIENT_ID",
        "env_client_secret": "META_CLIENT_SECRET",
        "token_url": "https://graph.facebook.com/v21.0/oauth/access_token",
        "scopes": ["pages_show_list"],
        "supports_api_publish": True,
        "recommended": True,
        "notes": "Connect the official Facebook account first. Page and Instagram publishing permissions can be added after Meta app setup and review.",
    },
    "youtube": {
        "label": "YouTube",
        "auth_mode": "oauth2",
        "auth_url": "https://accounts.google.com/o/oauth2/v2/auth",
        "env_client_id": "GOOGLE_OAUTH_CLIENT_ID",
        "env_client_secret": "GOOGLE_OAUTH_CLIENT_SECRET",
        "token_url": "https://oauth2.googleapis.com/token",
        "scopes": [
            "https://www.googleapis.com/auth/youtube.upload",
            "https://www.googleapis.com/auth/youtube.readonly",
        ],
        "supports_api_publish": True,
        "recommended": True,
        "notes": "Good for approved explainer videos and Shorts; publishing should stay approval-gated.",
    },
    "tiktok": {
        "label": "TikTok",
        "auth_mode": "oauth2",
        "auth_url": "https://www.tiktok.com/v2/auth/authorize/",
        "env_client_id": "TIKTOK_CLIENT_KEY",
        "scopes": ["video.upload", "video.publish"],
        "supports_api_publish": True,
        "recommended": False,
        "notes": "Later-phase integration because medical content and API review are stricter.",
    },
    "google_business": {
        "label": "Google Business Profile",
        "auth_mode": "oauth2",
        "auth_url": "https://accounts.google.com/o/oauth2/v2/auth",
        "env_client_id": "GOOGLE_OAUTH_CLIENT_ID",
        "env_client_secret": "GOOGLE_OAUTH_CLIENT_SECRET",
        "token_url": "https://oauth2.googleapis.com/token",
        "scopes": ["https://www.googleapis.com/auth/business.manage"],
        "supports_api_publish": True,
        "recommended": False,
        "notes": "Useful for clinic profile updates, not broad community discussions.",
    },
    "reddit": {
        "label": "Reddit",
        "auth_mode": "oauth2",
        "auth_url": "https://www.reddit.com/api/v1/authorize",
        "env_client_id": "REDDIT_CLIENT_ID",
        "scopes": ["identity", "submit", "read"],
        "supports_api_publish": True,
        "recommended": False,
        "notes": "Consider for careful AMA-style education; subreddit rules and moderation matter.",
    },
    "x": {
        "label": "X / Twitter",
        "auth_mode": "oauth2",
        "auth_url": "https://x.com/i/oauth2/authorize",
        "env_client_id": "X_CLIENT_ID",
        "env_client_secret": "X_CLIENT_SECRET",
        "token_url": "https://api.x.com/2/oauth2/token",
        "scopes": ["tweet.read", "tweet.write", "users.read", "offline.access"],
        "supports_api_publish": True,
        "recommended": False,
        "notes": "Useful for short updates; API access level and pricing may limit automation. Posting stays approval-gated.",
    },
    "threads": {
        "label": "Threads",
        "auth_mode": "oauth2",
        "auth_url": "https://threads.net/oauth/authorize",
        "env_client_id": "THREADS_CLIENT_ID",
        "scopes": ["threads_basic", "threads_content_publish"],
        "supports_api_publish": True,
        "recommended": False,
        "notes": "Good for lightweight public conversation once Meta approval is in place.",
    },
    "whatsapp": {
        "label": "WhatsApp",
        "auth_mode": "manual_export",
        "scopes": [],
        "supports_api_publish": False,
        "recommended": True,
        "notes": "Use manual export or approved broadcast tooling; avoid unsolicited health marketing.",
    },
    "newsletter": {
        "label": "Newsletter / Email",
        "auth_mode": "manual_export",
        "scopes": [],
        "supports_api_publish": False,
        "recommended": True,
        "notes": "Already fits MedicoHub retention digests and consent-based campaigns.",
    },
}


def _require_growth_access(actor_id: str, *, manage: bool = False) -> dict:
    actor = repository.get_user(actor_id)
    allowed_roles = GROWTH_MANAGER_ROLES if manage else GROWTH_ADMIN_ROLES
    if actor is None or actor.get("role") not in allowed_roles:
        raise HTTPException(status_code=403, detail="Growth Studio access requires an authorised admin or growth role.")
    return actor


def _has_social_accounts_manage(actor: dict | None) -> bool:
    if not actor:
        return False
    principal_ids = {
        item.strip()
        for item in os.getenv("MEDICOHUB_PRINCIPAL_ADMIN_USER_ID", "").split(",")
        if item.strip()
    }
    principal_emails = {
        item.strip().lower()
        for item in os.getenv("MEDICOHUB_PRINCIPAL_ADMIN_EMAIL", "").split(",")
        if item.strip()
    }
    return (
        actor.get("role") == "superAdmin"
        or SOCIAL_ACCOUNTS_MANAGE_PERMISSION in set(actor.get("permissions") or [])
        or actor.get("id") in principal_ids
        or str(actor.get("email", "")).lower() in principal_emails
    )


def _require_social_accounts_manage(actor_id: str) -> dict:
    actor = _require_growth_access(actor_id, manage=True)
    if not _has_social_accounts_manage(actor):
        raise HTTPException(
            status_code=403,
            detail="Only superAdmin users or users with socialAccounts.manage can connect, replace, disconnect, or test official social accounts.",
        )
    return actor


def _list_social_connections() -> list[dict]:
    records = repository.list_growth_collection(SOCIAL_CONNECTIONS_COLLECTION)
    if records:
        return records
    legacy = repository.list_growth_collection("growth_integrations")
    migrated = []
    for item in legacy:
        record = _normalize_social_connection_record(item)
        migrated.append(record)
        try:
            repository.create_growth_record(SOCIAL_CONNECTIONS_COLLECTION, record)
        except Exception:
            pass
    return migrated


def _update_social_connection(record_id: str, updates: dict) -> dict | None:
    updated = repository.update_growth_record(SOCIAL_CONNECTIONS_COLLECTION, record_id, updates)
    if updated is not None:
        return updated
    return repository.update_growth_record("growth_integrations", record_id, updates)


def _normalize_social_connection_record(record: dict) -> dict:
    normalized = dict(record)
    provider = normalized.get("provider", "")
    config = GROWTH_SOCIAL_CHANNELS.get(provider, {})
    if (
        normalized.get("auth_mode") == "oauth2"
        and normalized.get("connection_status") == "oauth_not_configured"
        and os.getenv(config.get("env_client_id", ""), "").strip()
    ):
        normalized["connection_status"] = "oauth_pending"
    normalized.setdefault("owner_type", "organisation")
    normalized.setdefault("owner_id", "medicohub")
    normalized.setdefault("connected_by_user_id", normalized.get("created_by", ""))
    normalized.setdefault("external_account_id", "")
    normalized.setdefault("external_account_name", normalized.get("display_name", ""))
    normalized.setdefault("external_account_type", "")
    normalized.setdefault("page_id", "")
    normalized.setdefault("instagram_business_account_id", "")
    normalized.setdefault("channel_id", "")
    normalized.setdefault("available_accounts", [])
    normalized.setdefault("token_expires_at", None)
    normalized.pop("token_reference", None)
    normalized.pop("oauth_state", None)
    normalized.pop("oauth_code_verifier", None)
    return normalized


def _token_fernet() -> Fernet:
    raw_key = os.getenv("MEDICOHUB_TOKEN_ENCRYPTION_KEY", "").strip()
    if raw_key:
        return Fernet(raw_key.encode("utf-8"))
    fallback_seed = (
        os.getenv("GOOGLE_SERVICE_ACCOUNT_JSON_B64")
        or os.getenv("GOOGLE_SERVICE_ACCOUNT_JSON")
        or os.getenv("MEDICOHUB_PRINCIPAL_ADMIN_USER_ID")
        or "medicohub-local-token-vault"
    )
    digest = hashlib.sha256(fallback_seed.encode("utf-8")).digest()
    return Fernet(base64.urlsafe_b64encode(digest))


def _store_social_token_payload(connection_id: str, provider: str, payload: dict) -> str:
    token_id = f"stok_{hashlib.sha256(f'{provider}:{connection_id}'.encode('utf-8')).hexdigest()[:20]}"
    encrypted = _token_fernet().encrypt(json.dumps(payload, default=str).encode("utf-8")).decode("utf-8")
    record = {
        "id": token_id,
        "connection_id": connection_id,
        "provider": provider,
        "encrypted_payload": encrypted,
        "created_at": utc_now().isoformat(),
        "updated_at": utc_now().isoformat(),
    }
    existing = next(
        (item for item in repository.list_growth_collection(SOCIAL_TOKEN_VAULT_COLLECTION) if item.get("id") == token_id),
        None,
    )
    if existing:
        repository.update_growth_record(SOCIAL_TOKEN_VAULT_COLLECTION, token_id, record)
    else:
        repository.create_growth_record(SOCIAL_TOKEN_VAULT_COLLECTION, record)
    return token_id


def _load_social_token_payload(token_reference: str) -> dict | None:
    if not token_reference:
        return None
    record = next(
        (item for item in repository.list_growth_collection(SOCIAL_TOKEN_VAULT_COLLECTION) if item.get("id") == token_reference),
        None,
    )
    if not record:
        return None
    try:
        decrypted = _token_fernet().decrypt(str(record.get("encrypted_payload", "")).encode("utf-8"))
    except (InvalidToken, ValueError):
        return None
    return json.loads(decrypted.decode("utf-8"))


def _provider_secret(provider: str, key: str) -> str:
    config = GROWTH_SOCIAL_CHANNELS.get(provider, {})
    env_name = config.get(key, "")
    return os.getenv(env_name, "").strip()


def _parse_token_expiry(token_response: dict) -> str:
    expires_in = token_response.get("expires_in")
    if not expires_in:
        return ""
    try:
        return (utc_now() + timedelta(seconds=int(expires_in))).isoformat()
    except (TypeError, ValueError):
        return ""


def _oauth_code_verifier() -> str:
    return secrets.token_urlsafe(48)[:96]


def _oauth_code_challenge(verifier: str) -> str:
    digest = hashlib.sha256(verifier.encode("utf-8")).digest()
    return base64.urlsafe_b64encode(digest).decode("utf-8").rstrip("=")


def _exchange_oauth_code_and_discover(provider: str, code: str, redirect_uri: str, connection_id: str) -> dict:
    if provider == "linkedin":
        return _exchange_linkedin_oauth_code(code, redirect_uri, connection_id)
    if provider == "meta":
        return _exchange_meta_oauth_code(code, redirect_uri, connection_id)
    if provider in {"youtube", "google_business"}:
        return _exchange_google_oauth_code(provider, code, redirect_uri, connection_id)
    if provider == "x":
        return _exchange_x_oauth_code(code, redirect_uri, connection_id)
    raise HTTPException(status_code=400, detail=f"OAuth exchange is not implemented for {provider}.")


def _exchange_linkedin_oauth_code(code: str, redirect_uri: str, connection_id: str) -> dict:
    client_id = _provider_secret("linkedin", "env_client_id")
    client_secret = _provider_secret("linkedin", "env_client_secret")
    token_response = requests.post(
        GROWTH_SOCIAL_CHANNELS["linkedin"]["token_url"],
        data={
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirect_uri,
            "client_id": client_id,
            "client_secret": client_secret,
        },
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        timeout=20,
    )
    if token_response.status_code >= 400:
        raise HTTPException(status_code=502, detail=f"LinkedIn token exchange failed: {token_response.text[:400]}")
    token_payload = token_response.json()
    access_token = token_payload.get("access_token", "")
    userinfo = {}
    organization_acls = {}
    if access_token:
        profile_response = requests.get(
            "https://api.linkedin.com/v2/userinfo",
            headers={"Authorization": f"Bearer {access_token}"},
            timeout=20,
        )
        if profile_response.status_code < 400:
            userinfo = profile_response.json()
        org_response = requests.get(
            "https://api.linkedin.com/rest/organizationAcls",
            params={"q": "roleAssignee", "role": "ADMINISTRATOR", "state": "APPROVED", "count": 100},
            headers={
                "Authorization": f"Bearer {access_token}",
                "LinkedIn-Version": "202606",
                "X-Restli-Protocol-Version": "2.0.0",
            },
            timeout=20,
        )
        if org_response.status_code < 400:
            organization_acls = org_response.json()
    account_id = str(userinfo.get("sub") or "")
    account_name = str(userinfo.get("name") or userinfo.get("localizedFirstName") or "LinkedIn account")
    available_accounts = []
    for acl in organization_acls.get("elements", []):
        organization_urn = str(acl.get("organization") or acl.get("organizationTarget") or "")
        if not organization_urn:
            continue
        organization_id = organization_urn.rsplit(":", 1)[-1]
        organization_detail = acl.get("organization~") or acl.get("organizationTarget~") or {}
        organization_name = (
            organization_detail.get("localizedName")
            or organization_detail.get("vanityName")
            or f"LinkedIn organisation {organization_id}"
        )
        available_accounts.append(
            {
                "external_account_id": organization_id,
                "external_account_name": organization_name,
                "external_account_type": "linkedin_organization_page",
                "provider": "linkedin",
                "organization_urn": organization_urn,
                "role": acl.get("role", "ADMINISTRATOR"),
            }
        )
    available_accounts.append(
        {
            "external_account_id": account_id,
            "external_account_name": account_name,
            "external_account_type": "linkedin_member",
            "provider": "linkedin",
        }
    )
    first = available_accounts[0] if available_accounts else {}
    token_reference = _store_social_token_payload(
        connection_id,
        "linkedin",
        {"token_response": token_payload, "userinfo": userinfo, "organization_acls": organization_acls},
    )
    return {
        "token_reference": token_reference,
        "token_expires_at": _parse_token_expiry(token_payload),
        "available_accounts": available_accounts,
        "external_account_id": first.get("external_account_id", account_id),
        "external_account_name": first.get("external_account_name", account_name),
        "external_account_type": first.get("external_account_type", "linkedin_member"),
    }


def _exchange_meta_oauth_code(code: str, redirect_uri: str, connection_id: str) -> dict:
    client_id = _provider_secret("meta", "env_client_id")
    client_secret = _provider_secret("meta", "env_client_secret")
    token_response = requests.get(
        GROWTH_SOCIAL_CHANNELS["meta"]["token_url"],
        params={
            "client_id": client_id,
            "client_secret": client_secret,
            "redirect_uri": redirect_uri,
            "code": code,
        },
        timeout=20,
    )
    if token_response.status_code >= 400:
        raise HTTPException(status_code=502, detail=f"Meta token exchange failed: {token_response.text[:400]}")
    token_payload = token_response.json()
    access_token = token_payload.get("access_token", "")
    pages_payload = {}
    available_accounts: list[dict] = []
    page_tokens: dict[str, str] = {}
    if access_token:
        pages_response = requests.get(
            "https://graph.facebook.com/v21.0/me/accounts",
            params={
                "fields": "id,name,access_token,tasks,instagram_business_account{id,username,name}",
                "access_token": access_token,
            },
            timeout=20,
        )
        if pages_response.status_code < 400:
            pages_payload = pages_response.json()
            for page in pages_payload.get("data", []):
                page_id = str(page.get("id") or "")
                page_tokens[page_id] = page.get("access_token", "")
                instagram = page.get("instagram_business_account") or {}
                available_accounts.append(
                    {
                        "external_account_id": page_id,
                        "external_account_name": page.get("name") or "Facebook Page",
                        "external_account_type": "facebook_page",
                        "provider": "meta",
                        "page_id": page_id,
                        "instagram_business_account_id": str(instagram.get("id") or ""),
                        "instagram_username": instagram.get("username") or instagram.get("name") or "",
                    }
                )
    first = available_accounts[0] if available_accounts else {}
    token_reference = _store_social_token_payload(
        connection_id,
        "meta",
        {"token_response": token_payload, "pages": pages_payload, "page_tokens": page_tokens},
    )
    return {
        "token_reference": token_reference,
        "token_expires_at": _parse_token_expiry(token_payload),
        "available_accounts": available_accounts,
        "external_account_id": first.get("external_account_id", ""),
        "external_account_name": first.get("external_account_name", "Meta account"),
        "external_account_type": first.get("external_account_type", "facebook_page" if first else ""),
        "page_id": first.get("page_id", ""),
        "instagram_business_account_id": first.get("instagram_business_account_id", ""),
    }


def _exchange_google_oauth_code(provider: str, code: str, redirect_uri: str, connection_id: str) -> dict:
    client_id = _provider_secret(provider, "env_client_id")
    client_secret = _provider_secret(provider, "env_client_secret")
    token_response = requests.post(
        GROWTH_SOCIAL_CHANNELS[provider]["token_url"],
        data={
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirect_uri,
            "client_id": client_id,
            "client_secret": client_secret,
        },
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        timeout=20,
    )
    if token_response.status_code >= 400:
        raise HTTPException(status_code=502, detail=f"Google token exchange failed: {token_response.text[:400]}")
    token_payload = token_response.json()
    access_token = token_payload.get("access_token", "")
    available_accounts: list[dict] = []
    channels_payload = {}
    if provider == "youtube" and access_token:
        channels_response = requests.get(
            "https://www.googleapis.com/youtube/v3/channels",
            params={"part": "id,snippet", "mine": "true"},
            headers={"Authorization": f"Bearer {access_token}"},
            timeout=20,
        )
        if channels_response.status_code < 400:
            channels_payload = channels_response.json()
            for channel in channels_payload.get("items", []):
                snippet = channel.get("snippet") or {}
                available_accounts.append(
                    {
                        "external_account_id": channel.get("id") or "",
                        "external_account_name": snippet.get("title") or "YouTube channel",
                        "external_account_type": "youtube_channel",
                        "provider": "youtube",
                        "channel_id": channel.get("id") or "",
                    }
                )
    first = available_accounts[0] if available_accounts else {}
    token_reference = _store_social_token_payload(
        connection_id,
        provider,
        {"token_response": token_payload, "channels": channels_payload},
    )
    return {
        "token_reference": token_reference,
        "token_expires_at": _parse_token_expiry(token_payload),
        "available_accounts": available_accounts,
        "external_account_id": first.get("external_account_id", ""),
        "external_account_name": first.get("external_account_name", "Google account"),
        "external_account_type": first.get("external_account_type", provider),
        "channel_id": first.get("channel_id", ""),
    }


def _exchange_x_oauth_code(code: str, redirect_uri: str, connection_id: str) -> dict:
    client_id = _provider_secret("x", "env_client_id")
    client_secret = _provider_secret("x", "env_client_secret")
    integration = next((item for item in _list_social_connections() if item.get("id") == connection_id), None)
    code_verifier = str((integration or {}).get("oauth_code_verifier") or "")
    if not code_verifier:
        raise HTTPException(status_code=400, detail="Missing X OAuth PKCE verifier. Start OAuth again.")
    token_response = requests.post(
        GROWTH_SOCIAL_CHANNELS["x"]["token_url"],
        data={
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirect_uri,
            "code_verifier": code_verifier,
        },
        auth=(client_id, client_secret),
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        timeout=20,
    )
    if token_response.status_code >= 400:
        raise HTTPException(status_code=502, detail=f"X token exchange failed: {token_response.text[:400]}")
    token_payload = token_response.json()
    access_token = token_payload.get("access_token", "")
    user_payload = {}
    if access_token:
        user_response = requests.get(
            "https://api.x.com/2/users/me",
            params={"user.fields": "id,name,username,profile_image_url,verified,verified_type"},
            headers={"Authorization": f"Bearer {access_token}"},
            timeout=20,
        )
        if user_response.status_code < 400:
            user_payload = user_response.json()
    user = user_payload.get("data") or {}
    username = str(user.get("username") or "")
    account_name = str(user.get("name") or (f"@{username}" if username else "X account"))
    account_id = str(user.get("id") or "")
    available_accounts = [
        {
            "external_account_id": account_id,
            "external_account_name": account_name,
            "external_account_type": "x_user",
            "provider": "x",
            "username": username,
        }
    ]
    token_reference = _store_social_token_payload(
        connection_id,
        "x",
        {"token_response": token_payload, "user": user_payload},
    )
    return {
        "token_reference": token_reference,
        "token_expires_at": _parse_token_expiry(token_payload),
        "available_accounts": available_accounts,
        "external_account_id": account_id,
        "external_account_name": account_name,
        "external_account_type": "x_user",
    }


def _pseudonymous_key(user_id: str | None) -> str | None:
    if not user_id:
        return None
    salt = os.getenv("MEDICOHUB_ANALYTICS_SALT", "medicohub-local-analytics")
    return hashlib.sha256(f"{salt}:{user_id}".encode("utf-8")).hexdigest()[:24]


def _safe_growth_metadata(metadata: dict) -> dict:
    clean: dict = {}
    for raw_key, raw_value in metadata.items():
        key = str(raw_key).strip()
        if not key:
            continue
        lowered = key.lower()
        if lowered in GROWTH_SENSITIVE_METADATA_KEYS or any(token in lowered for token in ["diagnos", "symptom", "medication", "email", "phone"]):
            raise HTTPException(status_code=400, detail=f"Sensitive analytics metadata is not allowed: {key}")
        if isinstance(raw_value, str) and len(raw_value) > 160:
            raise HTTPException(status_code=400, detail=f"Analytics metadata value is too long: {key}")
        clean[key] = raw_value
    return clean


def _growth_channel_catalog() -> list[dict]:
    catalog = []
    for provider, config in GROWTH_SOCIAL_CHANNELS.items():
        client_id = os.getenv(config.get("env_client_id", ""), "")
        client_secret = os.getenv(config.get("env_client_secret", ""), "") if config.get("env_client_secret") else ""
        auth_mode = config.get("auth_mode", "manual_export")
        oauth_configured = auth_mode != "oauth2" or bool(client_id)
        if auth_mode == "oauth2" and config.get("env_client_secret"):
            oauth_configured = bool(client_id and client_secret and client_id != client_secret)
        catalog.append(
            {
                "provider": provider,
                "label": config["label"],
                "auth_mode": auth_mode,
                "oauth_configured": oauth_configured,
                "scopes": config.get("scopes", []),
                "supports_api_publish": config.get("supports_api_publish", False),
                "recommended": config.get("recommended", False),
                "notes": config.get("notes", ""),
            }
        )
    return catalog


def _public_api_base_url() -> str:
    return os.getenv("MEDICOHUB_PUBLIC_API_BASE_URL", "https://medicohub-backend.fly.dev").rstrip("/")


def _growth_oauth_callback_url(provider: str) -> str:
    provider = provider.strip().lower()
    if provider == "meta":
        return f"{_public_api_base_url()}/api/integrations/meta/callback"
    return f"{_public_api_base_url()}/api/growth/oauth/{provider}/callback"


ARTICLE_TRANSLATION_PROVIDER_VERSION = "microsoft-azure-v1"
ARTICLE_TRANSLATION_WARNING = (
    "Machine translation may contain errors. Please consult a doctor for medical decisions."
)


def _plain_from_rich_text(value: str) -> str:
    return " ".join((value or "").replace("\r", "\n").split())


def _content_hash(value: str) -> str:
    normalized = " ".join((value or "").split())
    return hashlib.sha256(normalized.encode("utf-8")).hexdigest()[:24]


def _translation_key(
    *,
    article_id: str,
    section_id: str,
    source_lang: str,
    target_lang: str,
    content_hash: str,
) -> str:
    raw = f"{article_id}:{section_id}:{source_lang}:{target_lang}:{content_hash}:{ARTICLE_TRANSLATION_PROVIDER_VERSION}"
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def _normalize_article_sections(
    sections: dict | None,
    section_order: list[str] | None,
    *,
    legacy_summary: str = "",
    legacy_body: str = "",
) -> tuple[dict[str, dict], list[str]]:
    now = utc_now()
    normalized: dict[str, dict] = {}
    order: list[str] = []
    raw_sections = sections or {}
    requested_order = section_order or list(raw_sections.keys())
    for index, section_id in enumerate(requested_order):
        raw = raw_sections.get(section_id)
        if raw is None:
            continue
        data = raw.model_dump() if hasattr(raw, "model_dump") else dict(raw)
        clean_id = (data.get("id") or section_id).strip() or f"section_{index + 1}"
        rich_text = (data.get("richTextHtml") or "").strip()
        plain_text = (data.get("plainText") or _plain_from_rich_text(rich_text)).strip()
        if not rich_text and not plain_text:
            continue
        record = BlogArticleSectionRecord(
            id=clean_id,
            label=(data.get("label") or ARTICLE_SECTION_LABELS.get(clean_id, "Custom Section")).strip(),
            customTitle=(data.get("customTitle") or "").strip(),
            order=len(order) + 1,
            richTextHtml=rich_text or plain_text,
            plainText=plain_text,
            quillDeltaJson=data.get("quillDeltaJson") or [],
            createdAt=now,
            updatedAt=now,
        ).model_dump(mode="json")
        normalized[clean_id] = record
        order.append(clean_id)
    if normalized:
        return normalized, order

    fallback_sections: dict[str, dict] = {}
    fallback_order: list[str] = []
    if legacy_summary.strip():
        fallback_sections["summary"] = BlogArticleSectionRecord(
            id="summary",
            label="Summary",
            order=1,
            richTextHtml=legacy_summary.strip(),
            plainText=_plain_from_rich_text(legacy_summary),
            createdAt=now,
            updatedAt=now,
        ).model_dump(mode="json")
        fallback_order.append("summary")
    if legacy_body.strip():
        fallback_sections["body"] = BlogArticleSectionRecord(
            id="body",
            label="Article",
            order=len(fallback_order) + 1,
            richTextHtml=legacy_body.strip(),
            plainText=_plain_from_rich_text(legacy_body),
            createdAt=now,
            updatedAt=now,
        ).model_dump(mode="json")
        fallback_order.append("body")
    return fallback_sections, fallback_order


def _decorate_article_sections(article: dict) -> dict:
    sections = article.get("sections") or {}
    order = article.get("section_order") or []
    if sections and order:
        return article
    fallback_sections, fallback_order = _normalize_article_sections(
        {},
        [],
        legacy_summary=article.get("summary") or "",
        legacy_body=article.get("body") or "",
    )
    return {
        **article,
        "sections": sections or fallback_sections,
        "section_order": order or fallback_order,
        "default_language": article.get("default_language") or "en",
    }
settings = get_settings()
NOTIFICATION_REQUEST_TIMEOUT_SECONDS = 5
PUBLIC_APP_URL = os.getenv("MEDICOHUB_PUBLIC_APP_URL", "https://mediconverse.web.app/").rstrip("/")

ADMIN_SEED = [
    {
        "email": "doctornerves@gmail.com",
        "display_name": "Dr. Rajshekher Garikapati",
        "phone_number": "+971501802970",
        "languages": ["English", "Hindi", "Telugu"],
        "specialties": ["Neurology"],
    },
    {
        "email": "ponnusankar100@gmail.com",
        "display_name": "Dr. Ponnu Sankaran Pillai",
        "phone_number": "+971502794643",
        "languages": ["English", "Tamil", "Malayalam"],
        "specialties": ["Neurology"],
    },
    {
        "email": "dr.ukzain@gmail.com",
        "display_name": "Dr. Ummul Kiram Zain Ul Abedin",
        "phone_number": "+971507196737",
        "languages": ["English", "Hindi", "Urdu"],
        "specialties": ["Neurology"],
    },
]

DEVELOPMENT_PATIENT_SEED = {
    "email": "drphaniraj1965@gmail.com",
    "display_name": "Rajshekher Garikapati",
    "phone_number": "+919000611048",
    "languages": ["English", "Hindi", "Telugu"],
}


def _normalize_email(value: str | None) -> str:
    return (value or "").strip().lower()


def _normalize_phone(value: str | None) -> str:
    return "".join(char for char in (value or "") if char.isdigit() or char == "+")


def _normalize_phone_part(value: str | None) -> str:
    return "".join(char for char in (value or "") if char.isdigit())


def _compose_phone_number(country_code: str | None, national_number: str | None) -> str | None:
    code = _normalize_phone_part(country_code)
    national = _normalize_phone_part(national_number)
    if not code or not national:
        return None
    return f"+{code}{national}"


def _generate_otp_code() -> str:
    return f"{random.randint(0, 999999):06d}"


def _latest_pending_otp(*, destination: str, channel: str, purpose: str) -> dict | None:
    normalized_destination = (
        _normalize_email(destination) if channel == "email" else _normalize_phone(destination)
    )
    for otp_request in sorted(
        repository.list_otp_requests(),
        key=lambda item: item.get("created_at", ""),
        reverse=True,
    ):
        otp_destination = (
            _normalize_email(otp_request.get("destination"))
            if channel == "email"
            else _normalize_phone(otp_request.get("destination"))
        )
        if (
            otp_destination == normalized_destination
            and otp_request.get("channel") == channel
            and otp_request.get("purpose") == purpose
            and otp_request.get("status") == "pending"
        ):
            return otp_request
    return None


def _is_expired(iso_timestamp: str | None) -> bool:
    if not iso_timestamp:
        return True
    return utc_now().isoformat() > iso_timestamp


def _send_email_message(destination: str, subject: str, body: str) -> bool:
    sender_email = (
        settings.sendgrid_sender_email
        or settings.smtp_sender_email
        or settings.smtp_username
    )
    if settings.sendgrid_api_key and sender_email:
        response = requests.post(
            "https://api.sendgrid.com/v3/mail/send",
            headers={
                "Authorization": f"Bearer {settings.sendgrid_api_key}",
                "Content-Type": "application/json",
            },
            json={
                "personalizations": [{"to": [{"email": destination}]}],
                "from": {"email": sender_email},
                "subject": subject,
                "content": [{"type": "text/plain", "value": body}],
            },
            timeout=NOTIFICATION_REQUEST_TIMEOUT_SECONDS,
        )
        response.raise_for_status()
        return True

    if not (
        settings.smtp_host
        and settings.smtp_username
        and settings.smtp_password
        and sender_email
    ):
        return False
    message = EmailMessage()
    message["From"] = sender_email
    message["To"] = destination
    message["Subject"] = subject
    message.set_content(body)
    with smtplib.SMTP(
        settings.smtp_host,
        settings.smtp_port,
        timeout=NOTIFICATION_REQUEST_TIMEOUT_SECONDS,
    ) as server:
        if settings.enable_smtp_tls:
            server.starttls()
        server.login(settings.smtp_username, settings.smtp_password)
        server.send_message(message)
    return True


def _send_email_otp(destination: str, subject: str, body: str) -> bool:
    return _send_email_message(destination, subject, body)


def _send_sms_otp(destination: str, body: str) -> bool:
    if not (
        settings.twilio_account_sid
        and settings.twilio_auth_token
        and settings.twilio_from_phone
    ):
        return False
    response = requests.post(
        f"https://api.twilio.com/2010-04-01/Accounts/{settings.twilio_account_sid}/Messages.json",
        auth=(settings.twilio_account_sid, settings.twilio_auth_token),
        data={
            "From": settings.twilio_from_phone,
            "To": destination,
            "Body": body,
        },
        timeout=NOTIFICATION_REQUEST_TIMEOUT_SECONDS,
    )
    response.raise_for_status()
    return True


def _send_whatsapp_message(destination: str, body: str) -> bool:
    if not (
        settings.twilio_account_sid
        and settings.twilio_auth_token
        and settings.twilio_whatsapp_number
    ):
        return False
    from_number = settings.twilio_whatsapp_number
    if not from_number.startswith("whatsapp:"):
        from_number = f"whatsapp:{from_number}"
    to_number = destination
    if not to_number.startswith("whatsapp:"):
        to_number = f"whatsapp:{destination}"
    response = requests.post(
        f"https://api.twilio.com/2010-04-01/Accounts/{settings.twilio_account_sid}/Messages.json",
        auth=(settings.twilio_account_sid, settings.twilio_auth_token),
        data={
            "From": from_number,
            "To": to_number,
            "Body": body,
        },
        timeout=NOTIFICATION_REQUEST_TIMEOUT_SECONDS,
    )
    response.raise_for_status()
    return True


def _phone_parts_match(
    user: dict,
    *,
    country_code: str | None,
    national_number: str | None,
) -> bool:
    expected_code = _normalize_phone_part(country_code)
    expected_national = _normalize_phone_part(national_number)
    if not expected_code or not expected_national:
        return False
    stored_code = _normalize_phone_part(user.get("phone_country_code"))
    stored_national = _normalize_phone_part(user.get("phone_national_number"))
    if stored_code and stored_national:
        return stored_code == expected_code and stored_national == expected_national
    # Legacy users may only have the old combined E.164-style field. Compare the
    # exact recomposed number while they are gradually upgraded on next profile save.
    return _normalize_phone(user.get("phone_number")) == f"+{expected_code}{expected_national}"


def _find_user_by_email_or_phone(
    email: str | None,
    phone_number: str | None,
    *,
    phone_country_code: str | None = None,
    phone_national_number: str | None = None,
) -> dict | None:
    normalized_email = _normalize_email(email)
    normalized_phone = _normalize_phone(phone_number)
    for user in repository.list_users():
        if normalized_email and _normalize_email(user.get("email")) == normalized_email:
            return user
        if _phone_parts_match(
            user,
            country_code=phone_country_code,
            national_number=phone_national_number,
        ):
            return user
        if normalized_phone and _normalize_phone(user.get("phone_number")) == normalized_phone:
            return user
    return None


def _serialize_user(user: dict) -> dict:
    clean = dict(user)
    clean.pop("password", None)
    clean.setdefault("communication_preferences", _default_communication_preferences())
    clean.setdefault("email_subscribed", True)
    clean.setdefault("unsubscribed_at", None)
    clean.setdefault("resubscribed_at", None)
    clean.setdefault("permissions", [])
    return clean


def _default_communication_preferences() -> dict[str, bool]:
    return {
        "emailArticles": True,
        "emailQuestions": True,
        "emailAnswers": True,
        "emailFollowUps": True,
        "emailComments": True,
        "emailAnnouncements": True,
    }


def _communication_preferences(user: dict) -> dict[str, bool]:
    preferences = _default_communication_preferences()
    raw = user.get("communication_preferences") or user.get("communicationPreferences") or {}
    if isinstance(raw, dict):
        for key, value in raw.items():
            if key in preferences:
                preferences[key] = bool(value)
    return preferences


def _email_allowed(user: dict, preference_key: str) -> bool:
    if not user.get("email_subscribed", user.get("emailSubscribed", True)):
        return False
    return _communication_preferences(user).get(preference_key, True)


def _notification_preference_key(event_type: str) -> str:
    if event_type == "question_created":
        return "emailQuestions"
    if event_type == "question_answered":
        return "emailAnswers"
    if event_type == "followup_posted":
        return "emailFollowUps"
    if event_type == "comment_posted":
        return "emailComments"
    return "emailAnnouncements"


def _mailto_link(*, to_email: str, subject: str, body: str) -> str:
    encoded_subject = quote(subject)
    encoded_body = quote(body)
    return f"mailto:{to_email}?subject={encoded_subject}&body={encoded_body}"


def _whatsapp_link(*, phone_number: str, body: str) -> str:
    digits = "".join(character for character in phone_number if character.isdigit())
    return f"https://wa.me/{digits}?text={quote(body)}"


def _app_open_url() -> str:
    return PUBLIC_APP_URL or "https://mediconverse.web.app"


def _unsubscribe_token(user_id: str, email: str) -> str:
    secret = settings.firebase_project_id or "medicohub"
    digest = hashlib.sha256(f"{user_id}:{_normalize_email(email)}:{secret}".encode("utf-8")).hexdigest()
    return f"{user_id}.{digest[:24]}"


def _verify_unsubscribe_token(token: str) -> dict | None:
    try:
        user_id, _ = token.split(".", 1)
    except ValueError:
        return None
    user = repository.get_user(user_id)
    if user is None:
        return None
    expected = _unsubscribe_token(user["id"], user.get("email", ""))
    return user if expected == token else None


def _manage_preferences_url(user: dict) -> str:
    return f"{_app_open_url()}/settings?uid={quote(user['id'])}"


def _unsubscribe_url(user: dict) -> str:
    return f"{_app_open_url()}/unsubscribe?token={quote(_unsubscribe_token(user['id'], user.get('email', '')))}"


def _append_open_app_footer(body: str) -> str:
    if "Open the App for the full answer" in body:
        return body
    return (
        f"{body.rstrip()}\n\n"
        f"Open the App for the full answer:\n{_app_open_url()}"
    )


def _append_email_footer(*, body: str, user: dict | None) -> str:
    if user is None:
        return body
    return (
        f"{body.rstrip()}\n\n"
        "Manage email preferences:\n"
        f"{_manage_preferences_url(user)}\n\n"
        "Unsubscribe from MedicoHub email notifications:\n"
        f"{_unsubscribe_url(user)}"
    )


def _queue_firebase_trigger_email(
    *,
    to_email: str,
    subject: str,
    body: str,
    user: dict | None = None,
    metadata: dict | None = None,
) -> bool:
    try:
        body_with_footer = _append_email_footer(body=body, user=user)
        escaped_body = escape(body_with_footer).replace("\n", "<br>")
        repository.create_mail_message(
            {
                "id": make_id("mail"),
                "to": [to_email],
                "message": {
                    "subject": subject,
                    "text": body_with_footer,
                    "html": f"<div>{escaped_body}</div>",
                },
                **(metadata or {}),
                "created_at": utc_now().isoformat(),
                "source": "medicohub-backend",
            }
        )
        return True
    except Exception:
        return False


def _queue_notification_pair(
    *,
    event_type: str,
    recipient: dict,
    subject: str,
    body: str,
) -> None:
    recipient_email = recipient.get("email")
    recipient_phone = recipient.get("phone_number")
    recipient_name = recipient.get("display_name", "MedicoHub user")
    if recipient_email:
        preference_key = _notification_preference_key(event_type)
        if not _email_allowed(recipient, preference_key):
            repository.create_notification(
                NotificationEvent(
                    event_type=event_type,  # type: ignore[arg-type]
                    channel="email",
                    recipient_user_id=recipient["id"],
                    recipient_name=recipient_name,
                    recipient_email=recipient_email,
                    subject=subject,
                    body=body,
                    status="skipped",
                ).model_dump(mode="json")
            )
            return
        email_sent = False
        firebase_email_queued = False
        try:
            email_sent = _send_email_message(recipient_email, subject, body)
        except Exception:
            email_sent = False
        if not email_sent:
            firebase_email_queued = _queue_firebase_trigger_email(
                to_email=recipient_email,
                subject=subject,
                body=body,
                user=recipient,
                metadata={
                    "type": event_type,
                    "toUid": recipient["id"],
                    "toEmail": recipient_email,
                    "status": "pending",
                },
            )
        repository.create_notification(
            NotificationEvent(
                event_type=event_type,  # type: ignore[arg-type]
                channel="email",
                recipient_user_id=recipient["id"],
                recipient_name=recipient_name,
                recipient_email=recipient_email,
                subject=subject,
                body=body,
                deep_link=_mailto_link(to_email=recipient_email, subject=subject, body=body),
                status="sent" if email_sent else "queued" if firebase_email_queued else "preview_ready",
            ).model_dump(mode="json")
        )
    if recipient_phone:
        whatsapp_sent = False
        try:
            whatsapp_sent = _send_whatsapp_message(recipient_phone, body)
        except Exception:
            whatsapp_sent = False
        repository.create_notification(
            NotificationEvent(
                event_type=event_type,  # type: ignore[arg-type]
                channel="whatsapp",
                recipient_user_id=recipient["id"],
                recipient_name=recipient_name,
                recipient_phone_number=recipient_phone,
                subject=subject,
                body=body,
                deep_link=_whatsapp_link(phone_number=recipient_phone, body=body),
                status="sent" if whatsapp_sent else "preview_ready",
            ).model_dump(mode="json")
        )


def _safe_queue_notification_pair(
    *,
    event_type: str,
    recipient: dict,
    subject: str,
    body: str,
) -> None:
    try:
        _queue_notification_pair(
            event_type=event_type,
            recipient=recipient,
            subject=subject,
            body=body,
        )
    except Exception:
        # Question delivery should not fail because downstream notification
        # providers or notification persistence are temporarily unavailable.
        return


def get_notification_settings() -> dict:
    existing = repository.get_notification_settings()
    if existing:
        return existing
    default_settings = NotificationSettings(
        whatsapp_activation_target=settings.twilio_whatsapp_number or "+14155238886",
        updated_by="system",
    ).model_dump(mode="json")
    repository.upsert_notification_settings(default_settings)
    return default_settings


def update_notification_settings(payload: NotificationSettingsUpdate) -> dict:
    actor = repository.get_user(payload.actor_id)
    if actor is None:
        raise HTTPException(status_code=404, detail="Actor not found.")
    if actor.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Only administrators can update notification settings.")

    normalized_target = payload.whatsapp_activation_target.strip()
    if normalized_target and not normalized_target.startswith("+"):
        normalized_target = f"+{normalized_target}"

    updated = NotificationSettings(
        whatsapp_activation_enabled=payload.whatsapp_activation_enabled,
        whatsapp_activation_target=normalized_target,
        whatsapp_activation_phrase=payload.whatsapp_activation_phrase.strip(),
        email_status_note=payload.email_status_note.strip() or "Email notifications are coming later.",
        updated_by=payload.actor_id,
        updated_at=utc_now(),
    ).model_dump(mode="json")
    repository.upsert_notification_settings(updated)
    emit_audit("notification_settings", updated["id"], "updated", payload.actor_id, updated)
    return updated


def get_app_settings() -> dict:
    existing = repository.get_app_settings()
    if existing:
        if not existing.get("question_topics"):
            existing["question_topics"] = list(DEFAULT_QUESTION_TOPICS)
            repository.upsert_app_settings(existing)
        return existing
    default_settings = AppSettings(updated_by="system").model_dump(mode="json")
    repository.upsert_app_settings(default_settings)
    return default_settings


def update_app_settings(payload: AppSettingsUpdate) -> dict:
    actor = repository.get_user(payload.actor_id)
    if actor is None:
        raise HTTPException(status_code=404, detail="Actor not found.")
    if actor.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Only administrators can update app settings.")

    current = get_app_settings()
    next_topics = current.get("question_topics", list(DEFAULT_QUESTION_TOPICS))
    if payload.question_topics is not None:
        cleaned_topics: list[str] = []
        for item in payload.question_topics:
            topic = item.strip()
            if topic and topic not in cleaned_topics:
                cleaned_topics.append(topic)
        next_topics = cleaned_topics or list(DEFAULT_QUESTION_TOPICS)

    next_disclaimers = current.get("disclaimer_documents", {})
    if payload.disclaimer_documents is not None:
        next_disclaimers = {
            language.strip() or "English": {
                "title": document.title.strip(),
                "body": document.body.strip(),
            }
            for language, document in payload.disclaimer_documents.items()
            if language.strip() and document.title.strip() and document.body.strip()
        } or next_disclaimers

    updated = AppSettings(
        question_topics=next_topics,
        disclaimer_documents=next_disclaimers,
        default_region_note=(
            payload.default_region_note.strip()
            if payload.default_region_note and payload.default_region_note.strip()
            else current.get("default_region_note")
            or "This notice is educational and operational. It is not a substitute for country-specific legal advice."
        ),
        updated_by=payload.actor_id,
        updated_at=utc_now(),
    ).model_dump(mode="json")
    repository.upsert_app_settings(updated)
    emit_audit("app_settings", updated["id"], "updated", payload.actor_id, updated)
    return updated


def list_ad_campaigns() -> list[dict]:
    campaigns = repository.list_ad_campaigns()
    return sorted(
        campaigns,
        key=lambda item: (
            0 if item.get("active", True) else 1,
            -(item.get("priority", 50) or 50),
            item.get("updated_at", ""),
        ),
    )


def create_ad_campaign(payload: AdCampaignCreate) -> dict:
    actor = repository.get_user(payload.actor_id)
    if actor is None:
        raise HTTPException(status_code=404, detail="Actor not found.")
    if actor.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Only administrators can create ad campaigns.")

    campaign = AdCampaignRecord(
        sponsor_name=payload.sponsor_name.strip() or "Sponsored",
        title=payload.title.strip(),
        subtitle=payload.subtitle.strip(),
        cta_label=payload.cta_label.strip() or "Learn more",
        target_url=payload.target_url.strip(),
        keywords=[item.strip().lower() for item in payload.keywords if item.strip()],
        categories=[item.strip() for item in payload.categories if item.strip()],
        placements=payload.placements or ["home"],
        languages=[item.strip() for item in payload.languages if item.strip()],
        priority=payload.priority,
        created_by=payload.actor_id,
    ).model_dump(mode="json")
    repository.create_ad_campaign(campaign)
    emit_audit("ad_campaign", campaign["id"], "created", payload.actor_id, campaign)
    return campaign


def update_ad_campaign(campaign_id: str, payload: AdCampaignUpdate) -> dict:
    actor = repository.get_user(payload.actor_id)
    if actor is None:
        raise HTTPException(status_code=404, detail="Actor not found.")
    if actor.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Only administrators can update ad campaigns.")

    updates = {
        "updated_at": utc_now().isoformat(),
    }
    for field in [
        "sponsor_name",
        "title",
        "subtitle",
        "cta_label",
        "target_url",
        "keywords",
        "categories",
        "placements",
        "languages",
        "priority",
        "active",
    ]:
        value = getattr(payload, field)
        if value is None:
            continue
        if isinstance(value, str):
            cleaned = value.strip()
            if cleaned:
                updates[field] = cleaned
        elif isinstance(value, list):
            updates[field] = [
                item.strip().lower() if field == "keywords" else item.strip()
                for item in value
                if str(item).strip()
            ]
        else:
            updates[field] = value
    updated = repository.update_ad_campaign(campaign_id, updates)
    if updated is None:
        raise HTTPException(status_code=404, detail="Ad campaign not found.")
    emit_audit("ad_campaign", campaign_id, "updated", payload.actor_id, updated)
    return updated


def ingest_growth_event(payload: GrowthEventInput) -> dict:
    metadata = _safe_growth_metadata(payload.metadata)
    event = GrowthEventRecord(
        **payload.model_dump(exclude={"metadata"}),
        metadata=metadata,
        pseudonymous_user_key=_pseudonymous_key(payload.user_id),
    ).model_dump(mode="json")
    if any(existing.get("id") == event["id"] for existing in repository.list_growth_collection("growth_events")):
        return event
    repository.create_growth_record("growth_events", event)
    if payload.campaign_id:
        campaigns = repository.list_growth_collection("growth_campaigns")
        for campaign in campaigns:
            if campaign.get("id") == payload.campaign_id:
                counters = dict(campaign.get("event_counts") or {})
                counters[payload.event_name] = int(counters.get(payload.event_name, 0)) + 1
                repository.update_growth_record(
                    "growth_campaigns",
                    payload.campaign_id,
                    {"event_counts": counters, "updated_at": utc_now().isoformat()},
                )
                break
    return event


def list_growth_campaigns(actor_id: str) -> list[dict]:
    _require_growth_access(actor_id)
    return repository.list_growth_collection("growth_campaigns")


def create_growth_campaign(payload: GrowthCampaignCreate) -> dict:
    actor = _require_growth_access(payload.actor_id, manage=True)
    if not payload.hypothesis.strip() or not payload.target_audience.strip() or not payload.primary_cta.strip():
        raise HTTPException(status_code=400, detail="Campaigns require a hypothesis, target audience, and primary CTA.")
    if payload.primary_metric.strip() == "registration_completed":
        raise HTTPException(status_code=400, detail="Registration alone cannot be the Growth Studio activation metric.")
    campaign = GrowthCampaignRecord(
        **payload.model_dump(exclude={"actor_id", "owner_id"}),
        owner_id=payload.owner_id or actor["id"],
        created_by=payload.actor_id,
    ).model_dump(mode="json")
    repository.create_growth_record("growth_campaigns", campaign)
    emit_audit("growth_campaign", campaign["id"], "created", payload.actor_id, campaign)
    return campaign


def update_growth_campaign(campaign_id: str, payload: GrowthCampaignUpdate) -> dict:
    _require_growth_access(payload.actor_id, manage=True)
    updates = payload.model_dump(exclude_none=True, exclude={"actor_id"})
    if "primary_metric" in updates and updates["primary_metric"] == "registration_completed":
        raise HTTPException(status_code=400, detail="Registration alone cannot be the Growth Studio activation metric.")
    updates["updated_at"] = utc_now().isoformat()
    updated = repository.update_growth_record("growth_campaigns", campaign_id, updates)
    if updated is None:
        raise HTTPException(status_code=404, detail="Growth campaign not found.")
    emit_audit("growth_campaign", campaign_id, "updated", payload.actor_id, updated)
    return updated


def list_growth_opportunities(actor_id: str) -> list[dict]:
    _require_growth_access(actor_id)
    opportunities = repository.list_growth_collection("growth_opportunities")
    if opportunities:
        return opportunities
    generated: list[dict] = []
    public_questions = [q for q in repository.list_questions() if q.get("is_public") and q.get("status") != "deleted"]
    answered_titles = {
        article.get("title", "").strip().lower()
        for article in repository.list_blog_articles()
        if article.get("status") == "published"
    }
    for question in public_questions[:8]:
        title = question.get("title") or "Unanswered patient question"
        generated.append(
            GrowthOpportunityRecord(
                actor_id=actor_id,
                title=f"Answer recurring question: {title}",
                source="medicohub_questions",
                specialty=question.get("heading_group") or "General Health",
                audience="patient",
                language=question.get("language") or "English",
                estimated_value=70 if title.strip().lower() not in answered_titles else 35,
                urgency="high" if not question.get("responses") else "medium",
                medical_risk="medium",
                source_reliability="high",
                existing_coverage="No title-level published match found." if title.strip().lower() not in answered_titles else "Possible published coverage exists.",
                proposed_formats=["article", "FAQ", "discussion prompt"],
                recommended_cta="Save this answer and follow the specialty for updates.",
            ).model_dump(mode="json")
        )
    return generated


def create_growth_opportunity(payload: GrowthOpportunityCreate) -> dict:
    _require_growth_access(payload.actor_id, manage=True)
    opportunity = GrowthOpportunityRecord(**payload.model_dump()).model_dump(mode="json")
    repository.create_growth_record("growth_opportunities", opportunity)
    emit_audit("growth_opportunity", opportunity["id"], "created", payload.actor_id, opportunity)
    return opportunity


def list_growth_derivatives(actor_id: str, source_article_id: str | None = None) -> list[dict]:
    _require_growth_access(actor_id)
    records = repository.list_growth_collection("growth_content_derivatives")
    if source_article_id:
        records = [record for record in records if record.get("source_article_id") == source_article_id]
    return records


def create_growth_derivative(payload: GrowthContentDerivativeCreate) -> dict:
    _require_growth_access(payload.actor_id, manage=True)
    article = next((item for item in repository.list_blog_articles() if item.get("id") == payload.source_article_id), None)
    if article is None:
        raise HTTPException(status_code=404, detail="Source article not found.")
    if article.get("status", "published") != "published":
        raise HTTPException(status_code=400, detail="Promotional derivatives can only be created from approved/published articles.")
    derivative = GrowthContentDerivativeRecord(
        **payload.model_dump(),
        source_article_version=article.get("updated_at") or article.get("created_at") or "",
        source_article_review_status=article.get("status", "published"),
        source_article_review_date=article.get("updated_at") or article.get("created_at") or "",
    ).model_dump(mode="json")
    repository.create_growth_record("growth_content_derivatives", derivative)
    emit_audit("growth_derivative", derivative["id"], "created", payload.actor_id, derivative)
    return derivative


def mark_growth_derivatives_review_required(source_article_id: str, actor_id: str) -> None:
    derivatives = repository.list_growth_collection("growth_content_derivatives")
    for derivative in derivatives:
        if derivative.get("source_article_id") != source_article_id:
            continue
        if derivative.get("publication_status") == "published":
            continue
        repository.update_growth_record(
            "growth_content_derivatives",
            derivative["id"],
            {
                "approval_status": "review_required",
                "outdated_reason": "Source article was materially updated; verify derivative claims before scheduling.",
                "updated_at": utc_now().isoformat(),
            },
        )
        emit_audit("growth_derivative", derivative["id"], "review_required", actor_id, derivative)


def list_growth_integration_catalog(actor_id: str) -> list[dict]:
    actor = _require_growth_access(actor_id)
    existing = {
        item.get("provider"): _normalize_social_connection_record(item)
        for item in _list_social_connections()
        if item.get("provider")
    }
    catalog = []
    for item in _growth_channel_catalog():
        current = existing.get(item["provider"])
        callback_url = ""
        if item.get("auth_mode") == "oauth2":
            callback_url = _growth_oauth_callback_url(item["provider"])
        catalog.append(
            {
                **item,
                "integration_id": current.get("id", "") if current else "",
                "connection_status": current.get("connection_status", "not_connected") if current else "not_connected",
                "approval_status": current.get("approval_status", "draft") if current else "draft",
                "publishing_mode": current.get("publishing_mode", "manual_export") if current else "manual_export",
                "callback_url": callback_url,
                "can_manage_social_accounts": _has_social_accounts_manage(actor),
            }
        )
    return catalog


def list_growth_integrations(actor_id: str) -> list[dict]:
    _require_growth_access(actor_id)
    records = [_normalize_social_connection_record(item) for item in _list_social_connections()]
    return sorted(records, key=lambda item: item.get("updated_at", ""), reverse=True)


def create_growth_integration(payload: GrowthIntegrationCreate) -> dict:
    actor = _require_social_accounts_manage(payload.actor_id)
    provider = payload.provider.strip().lower()
    config = GROWTH_SOCIAL_CHANNELS.get(provider)
    if config is None:
        raise HTTPException(status_code=400, detail="Unsupported growth integration provider.")
    existing = [
        item
        for item in _list_social_connections()
        if item.get("provider") == provider
        and item.get("owner_type", "organisation") == "organisation"
        and item.get("owner_id", "medicohub") == "medicohub"
        and item.get("connection_status") != "disabled"
    ]
    if existing:
        return _normalize_social_connection_record(existing[0])
    auth_mode = payload.auth_mode if payload.auth_mode != "not_available" else config.get("auth_mode", "manual_export")
    if auth_mode == "oauth2" and config.get("auth_mode") != "oauth2":
        raise HTTPException(status_code=400, detail="This provider is not configured for OAuth publishing.")
    connection_status = "manual_export_ready" if auth_mode == "manual_export" else "oauth_not_configured"
    if auth_mode == "oauth2" and os.getenv(config.get("env_client_id", ""), ""):
        connection_status = "oauth_pending"
    publishing_mode = "manual_export" if auth_mode == "manual_export" else "approval_required_api"
    integration = GrowthIntegrationRecord(
        actor_id=payload.actor_id,
        provider=provider,
        display_name=payload.display_name or config["label"],
        account_handle=payload.account_handle,
        account_url=payload.account_url,
        auth_mode=auth_mode,
        scopes=payload.scopes or config.get("scopes", []),
        notes=payload.notes,
        owner_type="organisation",
        owner_id="medicohub",
        connected_by_user_id=actor["id"],
        external_account_name=payload.display_name or config["label"],
        connection_status=connection_status,
        publishing_mode=publishing_mode,
        callback_url=_growth_oauth_callback_url(provider),
        created_by=actor["id"],
    ).model_dump(mode="json")
    repository.create_growth_record(SOCIAL_CONNECTIONS_COLLECTION, integration)
    emit_audit("growth_integration", integration["id"], "created", payload.actor_id, _redact_growth_integration(integration))
    return _normalize_social_connection_record(integration)


def start_growth_integration_oauth(integration_id: str, payload: GrowthIntegrationOAuthStart) -> dict:
    _require_social_accounts_manage(payload.actor_id)
    integrations = _list_social_connections()
    integration = next((item for item in integrations if item.get("id") == integration_id), None)
    if integration is None:
        raise HTTPException(status_code=404, detail="Growth integration not found.")
    provider = integration.get("provider", "")
    config = GROWTH_SOCIAL_CHANNELS.get(provider)
    if config is None or config.get("auth_mode") != "oauth2":
        raise HTTPException(status_code=400, detail="This provider does not use OAuth.")
    client_id = os.getenv(config.get("env_client_id", ""), "")
    if not client_id:
        raise HTTPException(status_code=409, detail=f"Configure {config.get('env_client_id')} on the backend before starting OAuth.")
    client_secret = os.getenv(config.get("env_client_secret", ""), "").strip() if config.get("env_client_secret") else ""
    if config.get("env_client_secret") and not client_secret:
        raise HTTPException(status_code=409, detail=f"Configure {config.get('env_client_secret')} on the backend before starting OAuth.")
    if config.get("env_client_secret") and client_id.strip() == client_secret:
        raise HTTPException(
            status_code=409,
            detail=(
                f"{config.get('env_client_id')} and {config.get('env_client_secret')} are identical. "
                "Re-import the provider's OAuth 2.0 Client ID and Client Secret as two different values."
            ),
        )
    redirect_uri = payload.redirect_uri or _growth_oauth_callback_url(provider)
    state = make_id("oauth")
    # Use the current provider scope policy for OAuth starts. Older connection
    # records can contain scopes that were later removed after provider review
    # feedback, and reusing them can make every reconnect fail.
    requested_scopes = config.get("scopes", []) or integration.get("scopes", [])
    params = {
        "client_id": client_id,
        "redirect_uri": redirect_uri,
        "response_type": "code",
        "scope": " ".join(requested_scopes),
        "state": state,
    }
    oauth_code_verifier = ""
    if provider == "x":
        oauth_code_verifier = _oauth_code_verifier()
        params["code_challenge"] = _oauth_code_challenge(oauth_code_verifier)
        params["code_challenge_method"] = "S256"
    if provider in {"youtube", "google_business"}:
        params["access_type"] = "offline"
        params["prompt"] = "consent"
        params["include_granted_scopes"] = "true"
    if provider == "reddit":
        params["duration"] = "permanent"
    updates = {
        "oauth_state": state,
        "callback_url": redirect_uri,
        "scopes": requested_scopes,
        "oauth_code_verifier": oauth_code_verifier,
        "connection_status": "oauth_pending",
        "updated_at": utc_now().isoformat(),
    }
    updated = _update_social_connection(integration_id, updates)
    emit_audit("growth_integration", integration_id, "oauth_started", payload.actor_id, _redact_growth_integration(updated or updates))
    return {
        "authorization_url": f"{config['auth_url']}?{urlencode(params, quote_via=quote)}",
        "callback_url": redirect_uri,
        "state": state,
        "provider": provider,
    }


def complete_growth_integration_oauth(provider: str, state: str | None, code: str | None, error: str | None = None) -> dict:
    provider = provider.strip().lower()
    if not state:
        raise HTTPException(status_code=400, detail="Missing OAuth state.")
    integrations = _list_social_connections()
    integration = next(
        (item for item in integrations if item.get("provider") == provider and item.get("oauth_state") == state),
        None,
    )
    if integration is None:
        raise HTTPException(status_code=404, detail="OAuth state not recognised.")
    if error:
        updates = {
            "connection_status": "needs_reauth",
            "token_status": "none",
            "notes": f"OAuth callback error: {error}",
            "oauth_code_verifier": "",
            "updated_at": utc_now().isoformat(),
        }
        updated = _update_social_connection(integration["id"], updates)
        emit_audit("growth_integration", integration["id"], "oauth_failed", integration.get("created_by", "system"), _redact_growth_integration(updated or updates))
        return {"status": "failed", "provider": provider, "detail": error}
    if not code:
        raise HTTPException(status_code=400, detail="Missing OAuth code.")
    redirect_uri = integration.get("callback_url") or _growth_oauth_callback_url(provider)
    discovery = _exchange_oauth_code_and_discover(provider, code, redirect_uri, integration["id"])
    updates = {
        "connection_status": "connected" if discovery.get("token_reference") else "oauth_callback_received",
        "token_status": "token_reference_configured" if discovery.get("token_reference") else "pending_exchange",
        "token_reference": discovery.get("token_reference", ""),
        "token_expires_at": discovery.get("token_expires_at") or None,
        "available_accounts": discovery.get("available_accounts", []),
        "external_account_id": discovery.get("external_account_id", ""),
        "external_account_name": discovery.get("external_account_name", integration.get("display_name", "")),
        "external_account_type": discovery.get("external_account_type", ""),
        "page_id": discovery.get("page_id", ""),
        "instagram_business_account_id": discovery.get("instagram_business_account_id", ""),
        "channel_id": discovery.get("channel_id", ""),
        "oauth_state": "",
        "oauth_code_verifier": "",
        "last_connected_at": utc_now().isoformat(),
        "last_health_check_at": utc_now().isoformat(),
        "updated_at": utc_now().isoformat(),
    }
    updated = _update_social_connection(integration["id"], updates)
    emit_audit("growth_integration", integration["id"], "oauth_callback_received", integration.get("created_by", "system"), _redact_growth_integration(updated or updates))
    return {
        "status": "connected",
        "provider": provider,
        "connection_id": integration["id"],
        "available_accounts": updates["available_accounts"],
        "next_step": "Return to MedicoHub Growth Studio and select/approve the official destination if needed.",
    }


def update_growth_integration_approval(integration_id: str, payload: GrowthIntegrationApprovalUpdate) -> dict:
    _require_social_accounts_manage(payload.actor_id)
    integration = next(
        (item for item in _list_social_connections() if item.get("id") == integration_id),
        None,
    )
    if integration is None:
        raise HTTPException(status_code=404, detail="Growth integration not found.")
    updates = {
        "approval_status": payload.approval_status,
        "approved_by": payload.actor_id if payload.approval_status == "approved" else "",
        "approved_at": utc_now().isoformat() if payload.approval_status == "approved" else None,
        "notes": payload.notes or integration.get("notes", ""),
        "updated_at": utc_now().isoformat(),
    }
    if payload.approval_status in {"disabled", "rejected"}:
        updates["connection_status"] = "disabled" if payload.approval_status == "disabled" else integration.get("connection_status", "not_connected")
    updated = _update_social_connection(integration_id, updates)
    emit_audit("growth_integration", integration_id, "approval_updated", payload.actor_id, _redact_growth_integration(updated or updates))
    return _normalize_social_connection_record(updated or updates)


def update_growth_integration_selection(integration_id: str, payload: GrowthIntegrationSelectionUpdate) -> dict:
    _require_social_accounts_manage(payload.actor_id)
    integration = next(
        (item for item in _list_social_connections() if item.get("id") == integration_id),
        None,
    )
    if integration is None:
        raise HTTPException(status_code=404, detail="Social connection not found.")
    updates = {
        "external_account_id": payload.external_account_id,
        "external_account_name": payload.external_account_name,
        "external_account_type": payload.external_account_type,
        "page_id": payload.page_id,
        "instagram_business_account_id": payload.instagram_business_account_id,
        "channel_id": payload.channel_id,
        "notes": payload.notes or integration.get("notes", ""),
        "updated_at": utc_now().isoformat(),
    }
    updated = _update_social_connection(integration_id, updates)
    emit_audit("social_connection", integration_id, "destination_selected", payload.actor_id, _redact_growth_integration(updated or updates))
    return _normalize_social_connection_record(updated or updates)


def test_growth_integration_connection(integration_id: str, actor_id: str) -> dict:
    _require_social_accounts_manage(actor_id)
    integration = next(
        (item for item in _list_social_connections() if item.get("id") == integration_id),
        None,
    )
    if integration is None:
        raise HTTPException(status_code=404, detail="Social connection not found.")
    config = GROWTH_SOCIAL_CHANNELS.get(integration.get("provider", ""), {})
    oauth_ready = integration.get("auth_mode") != "oauth2" or bool(os.getenv(config.get("env_client_id", ""), ""))
    token_payload = _load_social_token_payload(str(integration.get("token_reference", "")))
    token_ready = integration.get("auth_mode") != "oauth2" or token_payload is not None
    destination_ready = integration.get("auth_mode") == "manual_export" or any(
        integration.get(key) for key in ["external_account_id", "page_id", "channel_id"]
    )
    status = "healthy" if oauth_ready and token_ready and destination_ready else "needs_attention"
    updates = {
        "last_health_check_at": utc_now().isoformat(),
        "updated_at": utc_now().isoformat(),
    }
    updated = _update_social_connection(integration_id, updates) or integration
    emit_audit(
        "social_connection",
        integration_id,
        "health_checked",
        actor_id,
        {"status": status, "oauth_ready": oauth_ready, "token_ready": token_ready, "destination_ready": destination_ready},
    )
    return {
        "status": status,
        "provider": integration.get("provider"),
        "connection_status": updated.get("connection_status"),
        "approval_status": updated.get("approval_status"),
        "oauth_ready": oauth_ready,
        "token_ready": token_ready,
        "destination_ready": destination_ready,
        "last_health_check_at": updates["last_health_check_at"],
    }


def list_growth_publishing_requests(actor_id: str) -> list[dict]:
    _require_growth_access(actor_id)
    records = repository.list_growth_collection("growth_publishing_requests")
    return sorted(records, key=lambda item: item.get("updated_at", ""), reverse=True)


def create_growth_publishing_request(payload: GrowthPublishingRequestCreate) -> dict:
    _require_growth_access(payload.actor_id, manage=True)
    integration = next(
        (item for item in _list_social_connections() if item.get("id") == payload.integration_id),
        None,
    )
    if integration is None:
        raise HTTPException(status_code=404, detail="Growth integration not found.")
    if integration.get("approval_status") != "approved":
        raise HTTPException(status_code=400, detail="Approve the integration before creating publish requests.")
    request = GrowthPublishingRequestRecord(**payload.model_dump()).model_dump(mode="json")
    repository.create_growth_record("growth_publishing_requests", request)
    emit_audit("growth_publish_request", request["id"], "created", payload.actor_id, request)
    return request


def update_growth_publishing_request(publish_id: str, payload: GrowthPublishingApprovalUpdate) -> dict:
    if payload.status in {"approved", "exported", "published", "failed"}:
        _require_social_accounts_manage(payload.actor_id)
    else:
        _require_growth_access(payload.actor_id, manage=True)
    updates = {
        "status": payload.status,
        "approval_notes": payload.notes,
        "updated_at": utc_now().isoformat(),
    }
    if payload.status in {"approved", "rejected"}:
        updates["approved_by"] = payload.actor_id
        updates["approved_at"] = utc_now().isoformat()
    if payload.status in {"exported", "published", "failed"}:
        updates["published_by"] = payload.actor_id
        updates["published_at"] = utc_now().isoformat()
        updates["external_post_id"] = payload.external_post_id
    updated = repository.update_growth_record("growth_publishing_requests", publish_id, updates)
    if updated is None:
        raise HTTPException(status_code=404, detail="Growth publishing request not found.")
    emit_audit("growth_publish_request", publish_id, "status_updated", payload.actor_id, updated)
    return updated


def _redact_growth_integration(record: dict) -> dict:
    clean = dict(record)
    if clean.get("token_reference"):
        clean["token_reference"] = "[stored-reference]"
    if clean.get("oauth_state"):
        clean["oauth_state"] = "[oauth-state]"
    if clean.get("oauth_code_verifier"):
        clean["oauth_code_verifier"] = "[pkce-verifier]"
    return clean


def _placeholder_discovered_accounts(provider: str) -> list[dict]:
    if provider == "meta":
        return [
            {
                "external_account_type": "facebook_page",
                "selection_required": True,
                "note": "After token exchange, populate controlled Facebook Pages here and select the official MedicoHub Page.",
            },
            {
                "external_account_type": "instagram_business_account",
                "selection_required": True,
                "note": "After selecting a Facebook Page, populate the linked Instagram professional account here.",
            },
        ]
    if provider == "youtube":
        return [
            {
                "external_account_type": "youtube_channel",
                "selection_required": True,
                "note": "After token exchange, populate the authenticated YouTube channels here.",
            }
        ]
    if provider == "linkedin":
        return [
            {
                "external_account_type": "linkedin_member_or_organisation",
                "selection_required": True,
                "note": "After token exchange, select the official LinkedIn account or organisation Page.",
            }
        ]
    if provider == "x":
        return [
            {
                "external_account_type": "x_user",
                "selection_required": True,
                "note": "After token exchange, select the official X account.",
            }
        ]
    return []


def growth_overview(actor_id: str) -> dict:
    _require_growth_access(actor_id)
    users = repository.list_users()
    questions = repository.list_questions()
    articles = repository.list_blog_articles()
    events = repository.list_growth_collection("growth_events")
    campaigns = repository.list_growth_collection("growth_campaigns")
    referrals = repository.list_growth_collection("growth_referrals")
    now = utc_now()

    def within_days(value: str | None, days: int) -> bool:
        if not value:
            return False
        try:
            parsed = datetime.fromisoformat(str(value).replace("Z", "+00:00"))
        except ValueError:
            return False
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=timezone.utc)
        return now - parsed <= timedelta(days=days)

    event_counts: dict[str, int] = {}
    sources: dict[str, int] = {}
    content: dict[str, int] = {}
    activated_keys: set[str] = set()
    for event in events:
        name = event.get("event_name", "")
        event_counts[name] = event_counts.get(name, 0) + 1
        source = event.get("source") or event.get("utm_source") or "direct"
        sources[source] = sources.get(source, 0) + 1
        content_id = event.get("content_id")
        if content_id:
            content[content_id] = content.get(content_id, 0) + 1
        if name in GROWTH_ACTIVATION_EVENTS:
            key = event.get("pseudonymous_user_key") or event.get("anonymous_id")
            if key:
                activated_keys.add(key)

    registered_users = [user for user in users if user.get("role") != "admin"]
    meaningful_comments = sum(
        len([comment for comment in article.get("comments", []) if comment.get("moderation_state", "visible") == "visible"])
        for article in articles
    )
    seven_day_returning = len([event for event in events if event.get("event_name") == "return_session" and within_days(event.get("timestamp"), 7)])
    thirty_day_returning = len([event for event in events if event.get("event_name") == "return_session" and within_days(event.get("timestamp"), 30)])
    return {
        "date_range": "all_available",
        "sample_size": {
            "users": len(registered_users),
            "events": len(events),
            "campaigns": len(campaigns),
            "articles": len(articles),
            "questions": len(questions),
        },
        "metrics": {
            "new_registrations": len(registered_users),
            "activated_users": len(activated_keys),
            "activation_rate": round((len(activated_keys) / len(registered_users)) * 100, 1) if registered_users else 0,
            "daily_active_users": len({event.get("pseudonymous_user_key") for event in events if within_days(event.get("timestamp"), 1) and event.get("pseudonymous_user_key")}),
            "weekly_active_users": len({event.get("pseudonymous_user_key") for event in events if within_days(event.get("timestamp"), 7) and event.get("pseudonymous_user_key")}),
            "monthly_active_users": len({event.get("pseudonymous_user_key") for event in events if within_days(event.get("timestamp"), 30) and event.get("pseudonymous_user_key")}),
            "seven_day_retention": seven_day_returning,
            "thirty_day_retention": thirty_day_returning,
            "articles_viewed": event_counts.get("article_viewed", 0),
            "articles_saved": event_counts.get("article_saved", 0),
            "meaningful_comments": meaningful_comments,
            "questions_submitted": len([q for q in questions if q.get("status") != "deleted"]),
            "doctor_contributions": len([article for article in articles if article.get("author_id")]),
            "shares": event_counts.get("article_shared", 0) + event_counts.get("referral_shared", 0),
            "referral_registrations": event_counts.get("referred_registration", 0),
            "referral_activations": event_counts.get("referred_activation", 0),
        },
        "top_sources": sorted(sources.items(), key=lambda item: item[1], reverse=True)[:8],
        "top_content": sorted(content.items(), key=lambda item: item[1], reverse=True)[:8],
        "campaigns": campaigns,
        "referrals_sample_size": len(referrals),
        "small_sample_warning": len(events) < 100,
    }


def _normalize_question(question: dict) -> dict:
    normalized = dict(question)
    normalized.setdefault("target_doctor_id", "")
    normalized.setdefault("heading_group", "General")
    normalized.setdefault("type", "forum")
    normalized.setdefault("language", "English")
    normalized.setdefault("tags", [])
    normalized.setdefault("premium", False)
    normalized.setdefault("status", "open")
    normalized.setdefault("bookmark_count", 0)
    normalized.setdefault("upvote_count", 0)
    normalized.setdefault("attachment_ids", [])
    normalized.setdefault("responses", [])
    normalized.setdefault("thread_messages", [])
    normalized.setdefault("is_public", False)
    normalized.setdefault("ai_summary", "")
    return normalized


def _decorate_question(question: dict) -> dict:
    decorated = _normalize_question(question)
    author = repository.get_user(decorated.get("author_id", ""))
    target_doctor_id = decorated.get("target_doctor_id", "")
    target_doctor = repository.get_user(target_doctor_id) if target_doctor_id else None
    decorated["author_name"] = author.get("display_name") if author else "Unknown user"
    decorated["author_email"] = author.get("email") if author else None
    decorated["target_doctor_name"] = (
        target_doctor.get("display_name") if target_doctor else "Unknown doctor"
    )
    decorated["target_doctor_email"] = target_doctor.get("email") if target_doctor else None
    users = {user["id"]: user for user in repository.list_users()}
    decorated["thread_messages"] = [
        {
            **message,
            "actor_name": users.get(message.get("actor_id"), {}).get("display_name", "Unknown user"),
        }
        for message in decorated.get("thread_messages", [])
    ]
    return decorated


def seed_if_needed() -> None:
    existing_users = repository.list_users()
    for admin_seed in ADMIN_SEED:
        existing_admin = _find_user_by_email_or_phone(
            admin_seed["email"],
            admin_seed["phone_number"],
        )
        admin_payload = {
            "id": existing_admin["id"] if existing_admin else make_id("usr"),
            "email": admin_seed["email"],
            "password": existing_admin.get("password", "Passw0rd!") if existing_admin else "Passw0rd!",
            "display_name": admin_seed["display_name"],
            "phone_number": admin_seed["phone_number"],
            "role": "admin",
            "verified": True,
            "languages": admin_seed["languages"],
            "specialties": admin_seed["specialties"],
            "doctor_status": "active",
            "can_manage_doctors": True,
            "can_moderate_content": True,
            "invited_by": existing_admin.get("invited_by") if existing_admin else None,
            "created_at": existing_admin.get("created_at") if existing_admin else utc_now(),
        }
        if existing_admin and existing_admin.get("consent"):
            admin_payload["consent"] = existing_admin["consent"]
        admin_user = User(**admin_payload).model_dump(mode="json")
        repository.upsert_user(admin_user)

    existing_patient = _find_user_by_email_or_phone(
        DEVELOPMENT_PATIENT_SEED["email"],
        DEVELOPMENT_PATIENT_SEED["phone_number"],
    )
    patient_payload = {
        "id": existing_patient["id"] if existing_patient else make_id("usr"),
        "email": DEVELOPMENT_PATIENT_SEED["email"],
        "password": existing_patient.get("password", "Passw0rd!") if existing_patient else "Passw0rd!",
        "display_name": DEVELOPMENT_PATIENT_SEED["display_name"],
        "phone_number": DEVELOPMENT_PATIENT_SEED["phone_number"],
        "role": "patient",
        "verified": True,
        "languages": DEVELOPMENT_PATIENT_SEED["languages"],
        "created_at": existing_patient.get("created_at") if existing_patient else utc_now(),
    }
    if existing_patient and existing_patient.get("consent"):
        patient_payload["consent"] = existing_patient["consent"]
    development_patient = User(**patient_payload).model_dump(mode="json")
    repository.upsert_user(development_patient)

    existing_users = repository.list_users()

    repository.seed_education(
        [
            EducationItem(
                title="Understanding Migraine Red Flags",
                category="Neurology",
                summary="Patient-friendly overview of warning signs worth discussing with your doctor.",
                url="https://example.com/education/migraine-red-flags",
            ).model_dump(mode="json"),
            EducationItem(
                title="How to Prepare for a Second Opinion Visit",
                category="General Health",
                type="video",
                summary="Checklist covering reports, medications, and questions to bring.",
                duration_minutes=8,
                url="https://example.com/education/second-opinion-checklist",
            ).model_dump(mode="json"),
        ]
    )

    if not repository.list_questions():
        patient = next((user for user in existing_users if user["role"] == "patient"), existing_users[0])
        doctor = next((user for user in existing_users if user["role"] in {"doctor", "admin"}), existing_users[0])
        sample = QuestionRecord.from_create(
            QuestionCreate(
                author_id=patient["id"],
                target_doctor_id=doctor["id"],
                type="forum",
                heading_group="Related to my test results",
                title="How should I organize MRI reports before a neurology review?",
                body="I have scans from two clinics and want to ask a clearer question.",
                tags=["Neurology", "General health", "Related to my test results"],
                language="English",
                premium=False,
                is_public=False,
            )
        )
        repository.seed_questions([sample.model_dump(mode="json")])

    if not repository.list_title_templates():
        admin_user = next((user for user in existing_users if user["role"] == "admin"), existing_users[0])
        for template in [
            TitleTemplate(
                title="I want to understand whether this is related to stroke recovery",
                specialty="Neurology",
                created_by=admin_user["id"],
            ),
            TitleTemplate(
                title="Can you explain these test results in simple words?",
                specialty="General Health",
                created_by=admin_user["id"],
            ),
            TitleTemplate(
                title="Are these symptoms possibly related to Parkinson's disease?",
                specialty="Neurology",
                created_by=admin_user["id"],
            ),
            TitleTemplate(
                title="Mujhe apni report ke baare mein doctor se kya poochna chahiye?",
                specialty="General Health",
                language="Hindi",
                created_by=admin_user["id"],
            ),
        ]:
            repository.create_title_template(template.model_dump(mode="json"))

    if not repository.list_blog_articles():
        admin_author = next((user for user in repository.list_users() if user["role"] == "admin"), None)
        if admin_author is not None:
            repository.create_blog_article(
                BlogArticleRecord(
                    author_id=admin_author["id"],
                    title="How to organize your stroke follow-up questions",
                    summary="A patient-friendly guide to preparing medication, BP, and report questions before your next visit.",
                    body=(
                        "Bring your latest discharge summary, medication list, blood pressure readings, and one page "
                        "of your top questions. Use simple terms such as stroke, weakness, memory, or tremor so the "
                        "doctor can respond clearly and efficiently."
                    ),
                    category="Neurology",
                    language="English",
                ).model_dump(mode="json")
            )

    repository.upsert_notification_settings(get_notification_settings())
    repository.upsert_app_settings(get_app_settings())


def should_seed_demo_data() -> bool:
    return settings.app_env.strip().lower() != "production"


def emit_audit(entity_type: str, entity_id: str, action: str, actor_id: str, payload: dict) -> None:
    append_audit(
        AuditEvent(
            entity_type=entity_type,
            entity_id=entity_id,
            action=action,
            actor_id=actor_id,
            payload=payload,
        ).model_dump(mode="json")
    )


def safe_emit_audit(entity_type: str, entity_id: str, action: str, actor_id: str, payload: dict) -> None:
    try:
        emit_audit(entity_type, entity_id, action, actor_id, payload)
    except Exception:
        return


def authenticate(email: str, password: str) -> dict:
    for user in repository.list_users():
        if _normalize_email(user["email"]) == _normalize_email(email) and user["password"] == password:
            return _serialize_user(user)
    raise HTTPException(status_code=401, detail="Invalid email or password.")


def request_otp(payload: OtpRequestInput) -> dict:
    user = _find_user_by_email_or_phone(
        payload.destination if payload.channel == "email" else None,
        payload.destination if payload.channel == "sms" else None,
    )
    if user is None:
        raise HTTPException(status_code=404, detail="No MedicoHub account matches this email or phone number.")

    code = _generate_otp_code()
    expires_at = datetime.fromtimestamp(
        utc_now().timestamp() + (settings.otp_code_ttl_minutes * 60),
        timezone.utc,
    )
    preview_message = (
        f"Your MedicoHub OTP is {code}. It expires in {settings.otp_code_ttl_minutes} minutes."
    )
    sent = False
    delivery_error = None
    try:
        if payload.channel == "email":
            sent = _send_email_otp(
                payload.destination,
                "MedicoHub OTP",
                preview_message,
            )
        else:
            sent = _send_sms_otp(payload.destination, preview_message)
    except Exception as exc:
        delivery_error = str(exc)
        sent = False

    otp_request = OtpRequestRecord(
        destination=payload.destination,
        channel=payload.channel,
        purpose=payload.purpose,
        code=code,
        expires_at=expires_at,
        preview_message=None if sent else preview_message,
    ).model_dump(mode="json")
    repository.create_otp_request(otp_request)
    emit_audit("otp", otp_request["id"], "requested", user["id"], otp_request)
    return {
        "otp_request_id": otp_request["id"],
        "delivery_status": "sent" if sent else "preview_only",
        "channel": payload.channel,
        "destination_hint": payload.destination if not sent else "***",
        "preview_message": None if sent else preview_message,
        "expires_at": otp_request["expires_at"],
        "delivery_error": delivery_error,
    }


def verify_otp(payload: OtpVerifyInput) -> dict:
    otp_request = _latest_pending_otp(
        destination=payload.destination,
        channel=payload.channel,
        purpose=payload.purpose,
    )
    if otp_request is None:
        raise HTTPException(status_code=404, detail="No pending OTP request was found.")
    if _is_expired(otp_request.get("expires_at")):
        repository.update_otp_request(otp_request["id"], {"status": "expired"})
        raise HTTPException(status_code=400, detail="This OTP has expired.")
    if otp_request.get("code") != payload.code.strip():
        raise HTTPException(status_code=401, detail="The OTP code is incorrect.")

    repository.update_otp_request(
        otp_request["id"],
        {
            "status": "verified",
            "verified_at": utc_now().isoformat(),
        },
    )
    user = _find_user_by_email_or_phone(
        payload.destination if payload.channel == "email" else None,
        payload.destination if payload.channel == "sms" else None,
    )
    if user is None:
        raise HTTPException(status_code=404, detail="No MedicoHub account matches this email or phone number.")
    emit_audit("otp", otp_request["id"], "verified", user["id"], {"destination": payload.destination})
    return AuthResponse(
        access_token=f"otp-token-{user['id']}",
        user=_serialize_user(user),
    ).model_dump(mode="json")


def list_users() -> list[dict]:
    return [_serialize_user(user) for user in repository.list_users()]


def update_communication_preferences(user_id: str, payload: CommunicationPreferencesUpdate) -> dict:
    user = repository.get_user(user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found.")
    actor = repository.get_user(payload.actor_id)
    if actor is None:
        raise HTTPException(status_code=404, detail="Actor not found.")
    if actor["id"] != user_id and actor.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Only the account owner or an admin can update preferences.")
    preferences = _communication_preferences(user)
    for key, value in payload.communication_preferences.items():
        if key in preferences:
            preferences[key] = bool(value)
    now = utc_now().isoformat()
    updates = {
        **user,
        "communication_preferences": preferences,
        "email_subscribed": payload.email_subscribed,
        "updated_at": now,
    }
    if payload.email_subscribed and not user.get("email_subscribed", True):
        updates["resubscribed_at"] = now
    if not payload.email_subscribed and user.get("email_subscribed", True):
        updates["unsubscribed_at"] = now
    repository.upsert_user(updates)
    emit_audit("user", user_id, "communication_preferences_updated", payload.actor_id, _serialize_user(updates))
    return _serialize_user(updates)


def unsubscribe_email(payload: UnsubscribeRequest) -> dict:
    user = _verify_unsubscribe_token(payload.token)
    if user is None:
        raise HTTPException(status_code=400, detail="Invalid unsubscribe token.")
    now = utc_now().isoformat()
    updated = {
        **user,
        "email_subscribed": False,
        "unsubscribed_at": now,
        "updated_at": now,
    }
    repository.upsert_user(updated)
    emit_audit("user", user["id"], "unsubscribed", user["id"], {"email": user.get("email")})
    return {"success": True, "message": "You have been unsubscribed from MedicoHub email notifications."}


def _content_url(content_type: str, content_id: str, content: dict) -> str:
    base = _app_open_url().rstrip("/")
    if content_type == "article":
        slug = content.get("slug") or content.get("id") or content_id
        return f"{base}/articles/{quote(str(slug))}"
    if content_type in {"question", "answer"}:
        question_id = content.get("question_id") or content.get("id") or content_id
        return f"{base}/questions/{quote(str(question_id))}"
    if content_type == "video":
        return f"{base}/videos/{quote(content_id)}"
    if content_type == "livestream":
        return f"{base}/live/{quote(content_id)}"
    return base


def _resolve_share_content(content_type: str, content_id: str) -> dict:
    if content_type == "article":
        article = next((item for item in repository.list_blog_articles() if item.get("id") == content_id), None)
        if article is None:
            raise HTTPException(status_code=404, detail="Article not found.")
        return {
            "title": article.get("title", "MedicoHub article"),
            "summary": article.get("summary") or article.get("body", "")[:700],
            "content": article,
        }
    if content_type == "question":
        question = next((item for item in repository.list_questions() if item.get("id") == content_id), None)
        if question is None:
            raise HTTPException(status_code=404, detail="Question not found.")
        return {
            "title": question.get("title", "MedicoHub question"),
            "summary": question.get("ai_summary") or question.get("body", "")[:700],
            "content": question,
        }
    if content_type == "answer":
        for question in repository.list_questions():
            for response in question.get("responses", []):
                if response.get("id") == content_id:
                    return {
                        "title": f"Answer: {question.get('title', 'MedicoHub question')}",
                        "summary": response.get("full_text") or response.get("key_points", ""),
                        "content": {**response, "question_id": question.get("id")},
                    }
        raise HTTPException(status_code=404, detail="Answer not found.")
    raise HTTPException(status_code=400, detail="This content type is not shareable yet.")


def _share_preference_key(content_type: str) -> str:
    if content_type == "article":
        return "emailArticles"
    if content_type == "question":
        return "emailQuestions"
    if content_type == "answer":
        return "emailAnswers"
    if content_type == "livestream":
        return "emailAnnouncements"
    return "emailAnnouncements"


def _email_subject(content_type: str, title: str) -> str:
    label = {
        "article": "Article",
        "question": "Question",
        "answer": "Answer",
        "announcement": "Announcement",
        "livestream": "Livestream",
    }.get(content_type, "MedicoHub")
    return f"[{label}] {title[:120]}"


def _email_body(*, user: dict, content_type: str, title: str, summary: str, content_url: str, custom_message: str) -> str:
    first_name = (user.get("display_name") or "there").split(" ")[0]
    intro = {
        "article": "A MedicoHub article may interest you.",
        "question": "A MedicoHub question may interest you.",
        "answer": "A MedicoHub answer may interest you.",
    }.get(content_type, "A MedicoHub update may interest you.")
    parts = [
        f"Hello {first_name},",
        "",
        intro,
        "",
        f"Title: {title}",
    ]
    if custom_message.strip():
        parts.extend(["", "Message from MedicoHub:", custom_message.strip()])
    if summary.strip():
        parts.extend(["", "Summary:", summary.strip()[:1200]])
    parts.extend(["", "Click below to read:", content_url, "", "Regards,", "MedicoHub Team"])
    return "\n".join(parts)


def _check_share_rate_limits(actor_id: str, recipient_count: int, content_type: str, content_id: str) -> None:
    now = utc_now()
    one_hour_ago = (now.replace(tzinfo=timezone.utc).timestamp() - 3600)
    today = now.date().isoformat()
    recent_campaigns = []
    daily_recipients = 0
    for campaign in repository.list_email_campaigns():
        if campaign.get("created_by") != actor_id:
            continue
        created = datetime.fromisoformat(str(campaign.get("created_at")).replace("Z", "+00:00"))
        if created.timestamp() >= one_hour_ago:
            recent_campaigns.append(campaign)
        if str(campaign.get("created_at", "")).startswith(today):
            daily_recipients += int(campaign.get("queued_count") or campaign.get("total_recipients") or 0)
    if len(recent_campaigns) >= 10:
        raise HTTPException(status_code=429, detail="Campaign hourly limit reached.")
    if recipient_count > 1000:
        raise HTTPException(status_code=429, detail="Recipient limit per campaign is 1000.")
    if daily_recipients + recipient_count > 3000:
        raise HTTPException(status_code=429, detail="Daily recipient limit reached.")


def _recent_delivery_exists(user_id: str, content_type: str, content_id: str) -> bool:
    cutoff = utc_now().timestamp() - 24 * 3600
    for delivery in repository.list_email_deliveries():
        if (
            delivery.get("to_uid") != user_id
            and delivery.get("toUid") != user_id
        ):
            continue
        if delivery.get("content_type") != content_type or delivery.get("content_id") != content_id:
            continue
        raw = delivery.get("queued_at") or delivery.get("created_at") or ""
        try:
            created = datetime.fromisoformat(str(raw).replace("Z", "+00:00"))
        except ValueError:
            continue
        if created.timestamp() >= cutoff:
            return True
    return False


def share_content(payload: ContentShareRequest) -> ContentShareReport:
    actor = repository.get_user(payload.actor_id)
    if actor is None:
        raise HTTPException(status_code=404, detail="Actor not found.")
    if actor.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Only administrators can share content by email.")
    if not payload.send_email:
        raise HTTPException(status_code=400, detail="Only email sharing is implemented.")
    unique_recipient_ids = list(dict.fromkeys(payload.recipient_ids))
    if not unique_recipient_ids:
        raise HTTPException(status_code=400, detail="Select at least one recipient.")
    _check_share_rate_limits(payload.actor_id, len(unique_recipient_ids), payload.content_type, payload.content_id)
    resolved = _resolve_share_content(payload.content_type, payload.content_id)
    title = resolved["title"]
    summary = resolved["summary"]
    content = resolved["content"]
    content_url = _content_url(payload.content_type, payload.content_id, content)
    subject = _email_subject(payload.content_type, title)
    preference_key = _share_preference_key(payload.content_type)
    campaign_id = make_id("emc")
    now = utc_now().isoformat()
    skipped_unsubscribed = 0
    skipped_preference = 0
    skipped_missing_email = 0
    duplicate_skipped = 0
    queued = 0
    seen_pairs = set()
    campaign = {
        "id": campaign_id,
        "campaignId": campaign_id,
        "content_type": payload.content_type,
        "content_id": payload.content_id,
        "created_by": payload.actor_id,
        "created_at": now,
        "custom_message": payload.custom_message,
        "total_recipients": len(unique_recipient_ids),
        "queued_count": 0,
        "sent_count": 0,
        "failed_count": 0,
        "skipped_unsubscribed_count": 0,
        "subject": subject,
    }
    repository.create_email_campaign(campaign)
    for user_id in unique_recipient_ids:
        user = repository.get_user(user_id)
        if user is None:
            skipped_missing_email += 1
            continue
        email = user.get("email", "").strip()
        if not email:
            skipped_missing_email += 1
            continue
        if not user.get("email_subscribed", user.get("emailSubscribed", True)):
            skipped_unsubscribed += 1
            continue
        if not _communication_preferences(user).get(preference_key, True):
            skipped_preference += 1
            continue
        pair = (user_id, payload.content_type, payload.content_id)
        if pair in seen_pairs:
            duplicate_skipped += 1
            continue
        seen_pairs.add(pair)
        if _recent_delivery_exists(user_id, payload.content_type, payload.content_id):
            duplicate_skipped += 1
            continue
        delivery_id = make_id("emd")
        body = _email_body(
            user=user,
            content_type=payload.content_type,
            title=title,
            summary=summary,
            content_url=content_url,
            custom_message=payload.custom_message,
        )
        queued_ok = _queue_firebase_trigger_email(
            to_email=email,
            subject=subject,
            body=body,
            user=user,
            metadata={
                "type": f"{payload.content_type}_share",
                "toUid": user_id,
                "toEmail": email,
                "contentType": payload.content_type,
                "contentId": payload.content_id,
                "contentUrl": content_url,
                "campaignId": campaign_id,
                "deliveryId": delivery_id,
                "status": "pending",
            },
        )
        status = "queued" if queued_ok else "failed"
        if queued_ok:
            queued += 1
        repository.create_email_delivery(
            {
                "id": delivery_id,
                "campaign_id": campaign_id,
                "campaignId": campaign_id,
                "to_uid": user_id,
                "toUid": user_id,
                "to_email": email,
                "toEmail": email,
                "content_type": payload.content_type,
                "content_id": payload.content_id,
                "status": status,
                "queued_at": now,
                "sent_at": None,
                "failure_reason": None if queued_ok else "Could not create mail queue document.",
            }
        )
    repository.update_email_campaign(
        campaign_id,
        {
            "queued_count": queued,
            "failed_count": len(unique_recipient_ids) - queued - skipped_unsubscribed - skipped_preference - skipped_missing_email - duplicate_skipped,
            "skipped_unsubscribed_count": skipped_unsubscribed,
            "skipped_preference_count": skipped_preference,
            "skipped_missing_email_count": skipped_missing_email,
            "duplicate_skipped_count": duplicate_skipped,
        },
    )
    emit_audit("email_campaign", campaign_id, "created", payload.actor_id, {
        "content_type": payload.content_type,
        "content_id": payload.content_id,
        "queued_count": queued,
    })
    return ContentShareReport(
        campaign_id=campaign_id,
        content_type=payload.content_type,
        content_id=payload.content_id,
        content_url=content_url,
        subject=subject,
        total_requested=len(unique_recipient_ids),
        queued_count=queued,
        skipped_unsubscribed_count=skipped_unsubscribed,
        skipped_preference_count=skipped_preference,
        skipped_missing_email_count=skipped_missing_email,
        duplicate_skipped_count=duplicate_skipped,
    )


def list_email_campaigns() -> list[dict]:
    return sorted(repository.list_email_campaigns(), key=lambda item: item.get("created_at", ""), reverse=True)


def lookup_user_by_email(email: str) -> dict | None:
    user = _find_user_by_email_or_phone(email, None)
    if user is None:
        return None
    return _serialize_user(user)


def lookup_user_by_phone(
    phone_number: str | None = None,
    phone_country_code: str | None = None,
    phone_national_number: str | None = None,
) -> dict | None:
    user = _find_user_by_email_or_phone(
        None,
        phone_number,
        phone_country_code=phone_country_code,
        phone_national_number=phone_national_number,
    )
    if user is None:
        return None
    if (
        phone_country_code
        and phone_national_number
        and not user.get("phone_country_code")
        and not user.get("phone_national_number")
        and _phone_parts_match(
            user,
            country_code=phone_country_code,
            national_number=phone_national_number,
        )
    ):
        user = {
            **user,
            "phone_country_code": phone_country_code,
            "phone_national_number": phone_national_number,
        }
        repository.upsert_user(user)
    return _serialize_user(user)


def list_doctors() -> list[dict]:
    doctors = [
        _serialize_user(user)
        for user in repository.list_users()
        if user["role"] in {"doctor", "admin"}
    ]
    return sorted(doctors, key=lambda item: item.get("display_name", ""))


def get_user_profile(user_id: str) -> dict:
    user = repository.get_user(user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found.")
    return _serialize_user(user)


def upsert_user_profile(payload: UserProfileUpsertRequest) -> dict:
    existing = repository.get_user(payload.id)
    phone_number = (
        _compose_phone_number(payload.phone_country_code, payload.phone_national_number)
        or payload.phone_number
    )
    existing_by_identity = _find_user_by_email_or_phone(
        payload.email,
        phone_number,
        phone_country_code=payload.phone_country_code,
        phone_national_number=payload.phone_national_number,
    )
    existing_consent = existing.get("consent") if existing else None
    existing_created_at = existing.get("created_at") if existing else utc_now()
    existing_password = existing.get("password", "Passw0rd!") if existing else "Passw0rd!"
    existing_permissions = existing.get("permissions", []) if existing else []
    allowlisted_admin = next(
        (
            admin
            for admin in ADMIN_SEED
            if _normalize_email(admin["email"]) == _normalize_email(payload.email)
            or _normalize_phone(admin["phone_number"]) == _normalize_phone(phone_number)
        ),
        None,
    )

    role = "admin" if allowlisted_admin is not None else payload.role
    verified = bool(payload.verified)
    can_manage_doctors = False
    can_moderate_content = False
    doctor_status = "not_applicable"
    invited_by = existing.get("invited_by") if existing else None
    display_name = payload.display_name.strip()
    phone_country_code = payload.phone_country_code
    phone_national_number = payload.phone_national_number
    specialties = payload.specialties or []

    if role == "admin":
        if allowlisted_admin is None:
            raise HTTPException(
                status_code=403,
                detail="This email or phone number is not on the MedicoHub admin allowlist.",
            )
        verified = True
        can_manage_doctors = True
        can_moderate_content = True
        doctor_status = "active"
        display_name = allowlisted_admin["display_name"]
        phone_number = allowlisted_admin["phone_number"]
        phone_country_code = allowlisted_admin.get("phone_country_code")
        phone_national_number = allowlisted_admin.get("phone_national_number")
        specialties = allowlisted_admin["specialties"]
        languages = allowlisted_admin["languages"]
    elif role == "doctor":
        invited_record = None
        if existing_by_identity is not None and existing_by_identity["role"] in {"doctor", "admin"}:
            invited_record = existing_by_identity
        if invited_record is None:
            raise HTTPException(
                status_code=403,
                detail="Doctors must be invited or added by an administrator before signing in.",
            )
        verified = invited_record.get("verified", False) or verified
        doctor_status = "active"
        can_moderate_content = True
        invited_by = invited_record.get("invited_by")
        display_name = invited_record.get("display_name", display_name)
        phone_number = invited_record.get("phone_number", phone_number)
        phone_country_code = invited_record.get("phone_country_code", phone_country_code)
        phone_national_number = invited_record.get("phone_national_number", phone_national_number)
        specialties = invited_record.get("specialties", specialties)
        languages = invited_record.get("languages", payload.languages or ["English"])
    else:
        languages = payload.languages or ["English"]

    if role == "patient":
        verified = True

    user_payload = {
        "id": payload.id,
        "email": payload.email,
        "password": existing_password if existing else "Passw0rd!",
        "display_name": display_name,
        "phone_number": phone_number,
        "phone_country_code": phone_country_code,
        "phone_national_number": phone_national_number,
        "role": role,
        "verified": verified,
        "languages": languages,
        "specialties": specialties,
        "doctor_status": doctor_status,
        "can_manage_doctors": can_manage_doctors,
        "can_moderate_content": can_moderate_content,
        "permissions": existing_permissions,
        "invited_by": invited_by,
        "created_at": existing_created_at,
        "communication_preferences": _communication_preferences(existing or {}),
        "email_subscribed": (existing or {}).get("email_subscribed", True),
        "unsubscribed_at": (existing or {}).get("unsubscribed_at"),
        "resubscribed_at": (existing or {}).get("resubscribed_at"),
        "updated_at": utc_now(),
    }
    if existing_consent is not None:
        user_payload["consent"] = existing_consent

    user = User(**user_payload).model_dump(mode="json")
    repository.upsert_user(user)
    emit_audit("user", user["id"], "upserted", user["id"], _serialize_user(user))
    return _serialize_user(user)


def delete_user_account(user_id: str, payload: UserDeleteRequest) -> dict:
    actor = repository.get_user(payload.actor_id)
    if payload.actor_id != user_id and not (actor and actor.get("role") == "admin"):
        raise HTTPException(
            status_code=403,
            detail="Only the account owner or an admin can delete this account.",
        )
    removed = repository.delete_user(user_id)
    if removed is None:
        raise HTTPException(status_code=404, detail="User not found.")
    emit_audit(
        "user",
        user_id,
        "deleted",
        payload.actor_id,
        {"id": user_id, "email": removed.get("email")},
    )
    return {"user_id": user_id, "deleted": True}


def invite_doctor(payload: DoctorInviteCreate) -> dict:
    actor = repository.get_user(payload.actor_id)
    if actor is None or actor.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Only administrators can add doctors.")

    existing = _find_user_by_email_or_phone(payload.email, payload.phone_number)
    doctor = User(
        id=existing["id"] if existing else make_id("usr"),
        email=payload.email,
        password=existing.get("password", "Passw0rd!") if existing else "Passw0rd!",
        display_name=payload.display_name,
        phone_number=payload.phone_number,
        role="doctor",
        verified=True,
        languages=payload.languages or ["English"],
        specialties=payload.specialties or ["General Health"],
        doctor_status="active",
        can_moderate_content=True,
        invited_by=payload.actor_id,
        created_at=existing.get("created_at") if existing else utc_now(),
    ).model_dump(mode="json")
    repository.upsert_user(doctor)
    emit_audit("doctor", doctor["id"], "invited", payload.actor_id, _serialize_user(doctor))
    return _serialize_user(doctor)


def list_questions() -> list[dict]:
    questions = [
        _decorate_question(question)
        for question in repository.list_questions()
        if question.get("status") != "deleted"
    ]
    return sorted(questions, key=lambda item: item.get("updated_at", ""), reverse=True)


def create_question(payload: QuestionCreate) -> dict:
    author = repository.get_user(payload.author_id)
    target_doctor = repository.get_user(payload.target_doctor_id)
    if author is None:
        raise HTTPException(status_code=404, detail="Author not found.")
    if target_doctor is None or target_doctor.get("role") not in {"doctor", "admin"}:
        raise HTTPException(status_code=404, detail="Target doctor not found.")

    question = QuestionRecord.from_create(payload).model_dump(mode="json")
    for message in question.get("thread_messages", []):
        message["question_id"] = question["id"]
    repository.create_question(question)
    subject = f"MedicoHub question: {question['title']}"
    question_preview = (
        f"A new educational question has been posted in MedicoHub.\n\n"
        f"Title: {question['title']}\n"
        f"Heading: {question['heading_group']}\n"
        f"Language: {question['language']}\n"
        f"Asked by: {author.get('display_name')}\n"
        f"Target doctor: {target_doctor.get('display_name')}\n\n"
        f"Question preview:\n{question['body'][:500]}"
    )
    _safe_queue_notification_pair(
        event_type="question_created",
        recipient=author,
        subject=subject,
        body=question_preview,
    )
    _safe_queue_notification_pair(
        event_type="question_created",
        recipient=target_doctor,
        subject=subject,
        body=question_preview,
    )
    safe_emit_audit("question", question["id"], "created", payload.author_id, question)
    return _decorate_question(question)


def update_question(question_id: str, payload: QuestionUpdateRequest) -> dict:
    current = next((item for item in repository.list_questions() if item["id"] == question_id), None)
    if current is None or current.get("status") == "deleted":
        raise HTTPException(status_code=404, detail="Question not found.")

    actor = repository.get_user(payload.actor_id)
    if actor is None:
        raise HTTPException(status_code=404, detail="Actor not found.")
    if payload.actor_id != current["author_id"] and actor.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Only the author or an admin can edit this question.")

    updates = {
        "updated_at": utc_now().isoformat(),
    }
    for field in ["title", "body", "heading_group", "language", "symptoms_summary", "is_public", "attachment_ids"]:
        value = getattr(payload, field)
        if value is not None:
            updates[field] = value
    updated = repository.update_question(question_id, updates)
    if updated is None:
        raise HTTPException(status_code=404, detail="Question not found.")
    emit_audit("question", question_id, "updated", payload.actor_id, updated)
    return _decorate_question(updated)


def delete_question(question_id: str, payload: QuestionDeleteRequest) -> dict:
    current = next((item for item in repository.list_questions() if item["id"] == question_id), None)
    if current is None or current.get("status") == "deleted":
        raise HTTPException(status_code=404, detail="Question not found.")

    actor = repository.get_user(payload.actor_id)
    if actor is None:
        raise HTTPException(status_code=404, detail="Actor not found.")
    if payload.actor_id != current["author_id"] and actor.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Only the author or an admin can delete this question.")

    updated = repository.update_question(
        question_id,
        {
            "status": "deleted",
            "updated_at": utc_now().isoformat(),
        },
    )
    if updated is None:
        raise HTTPException(status_code=404, detail="Question not found.")
    emit_audit("question", question_id, "deleted", payload.actor_id, updated)
    return {"question_id": question_id, "deleted": True}


def create_attachment(owner_id: str, payload: AttachmentCreate) -> dict:
    attachment = AttachmentRecord.from_create(owner_id, payload).model_dump(mode="json")
    repository.create_attachment(attachment)
    emit_audit("attachment", attachment["id"], "created", owner_id, attachment)
    return attachment


async def upload_attachment_file(
    *,
    owner_id: str,
    expiry_option: str,
    file: UploadFile,
) -> dict:
    content = await file.read()
    if not content:
        raise HTTPException(status_code=400, detail="Uploaded file is empty.")

    payload = AttachmentCreate(
        file_name=file.filename or "uploaded_file",
        mime_type=file.content_type or "application/octet-stream",
        expiry_option=expiry_option,  # type: ignore[arg-type]
    )
    record = AttachmentRecord.from_create(owner_id, payload)

    try:
        storage_info = file_storage.upload_bytes(
            owner_id=owner_id,
            file_name=record.file_name,
            mime_type=record.mime_type,
            content=content,
        )
    except Exception as exc:
        raise HTTPException(
            status_code=503,
            detail=(
                "File storage is not ready. Confirm the configured provider is enabled and that the "
                "MedicoHub backend service account has access to the target storage resource."
            ),
        ) from exc

    preview = None
    if record.mime_type == "application/pdf":
        try:
            preview = pdf_ingestion.extract_text_preview(content)
        except Exception:
            preview = None

    attachment = record.model_copy(
        update={
            "storage_provider": storage_info["storage_provider"],
            "storage_id": storage_info["storage_id"],
            "storage_path": storage_info["storage_path"],
            "temporary_url": storage_info["temporary_url"],
            "extracted_text_preview": preview,
        }
    ).model_dump(mode="json")

    repository.create_attachment(attachment)
    emit_audit("attachment", attachment["id"], "uploaded", owner_id, attachment)
    return attachment


def revoke_attachment(attachment_id: str, actor_id: str) -> dict:
    attachment = next((item for item in repository.list_attachments() if item["id"] == attachment_id), None)
    if attachment is None:
        raise HTTPException(status_code=404, detail="Attachment not found.")

    if attachment.get("revoked_at") is None:
        storage_id = attachment.get("storage_id")
        if storage_id:
            try:
                file_storage.revoke(storage_id=storage_id)
            except Exception:
                pass
        attachment = repository.update_attachment(
            attachment_id,
            {"revoked_at": utc_now().isoformat()},
        )
        if attachment is None:
            raise HTTPException(status_code=404, detail="Attachment not found.")
        emit_audit("attachment", attachment_id, "revoked", actor_id, attachment)
    return attachment


def add_response(payload: DoctorResponseInput) -> dict:
    doctor = repository.get_user(payload.doctor_id)
    if doctor is None or doctor.get("role") not in {"doctor", "admin"}:
        raise HTTPException(status_code=403, detail="Only doctors and admins can answer questions.")
    question = next((item for item in repository.list_questions() if item["id"] == payload.question_id), None)
    if question is None:
        raise HTTPException(status_code=404, detail="Question not found.")

    response = DoctorResponseRecord(
        question_id=payload.question_id,
        doctor_id=payload.doctor_id,
        key_points=payload.key_points,
        what_it_means=payload.what_it_means,
        what_to_discuss_with_doctor=payload.what_to_discuss_with_doctor,
        full_text=payload.full_text,
        response_mode=payload.response_mode,
    ).model_dump(mode="json")
    created = repository.add_response(payload.question_id, response)
    if created is None:
        raise HTTPException(status_code=404, detail="Question not found.")
    author = repository.get_user(question["author_id"])
    subject = f"MedicoHub answer: {question['title']}"
    response_preview = (
        f"A MedicoHub educational reply has been posted.\n\n"
        f"Question: {question['title']}\n"
        f"Responding doctor: {doctor.get('display_name')}\n\n"
        f"Key points:\n{payload.key_points}\n\n"
        f"What it means:\n{payload.what_it_means}\n\n"
        f"What to discuss with your doctor:\n{payload.what_to_discuss_with_doctor}"
    )
    response_preview = _append_open_app_footer(response_preview)
    if author is not None:
        _queue_notification_pair(
            event_type="question_answered",
            recipient=author,
            subject=subject,
            body=response_preview,
        )
    _queue_notification_pair(
        event_type="question_answered",
        recipient=doctor,
        subject=subject,
        body=response_preview,
    )
    emit_audit("response", response["id"], "created", payload.doctor_id, response)
    return response


def delete_responses(question_id: str, payload: ResponseDeleteRequest) -> dict:
    actor = repository.get_user(payload.actor_id)
    if actor is None:
        raise HTTPException(status_code=404, detail="Actor not found.")
    if actor.get("role") not in {"doctor", "admin"} and not actor.get("can_moderate_content"):
        raise HTTPException(status_code=403, detail="Only doctors and admins can delete doctor responses.")
    if not payload.response_ids:
        raise HTTPException(status_code=400, detail="Select at least one response to delete.")

    question = next((item for item in repository.list_questions() if item["id"] == question_id), None)
    if question is None:
        raise HTTPException(status_code=404, detail="Question not found.")

    removed = repository.delete_responses(question_id, payload.response_ids)
    if removed is None:
        raise HTTPException(status_code=404, detail="Question not found.")
    for response in removed:
        emit_audit("response", response.get("id", "unknown"), "deleted", payload.actor_id, response)
    return {
        "question_id": question_id,
        "deleted_response_ids": [item.get("id") for item in removed],
    }


def add_thread_message(payload: ThreadMessageInput) -> dict:
    question = next((item for item in repository.list_questions() if item["id"] == payload.question_id), None)
    if question is None:
        raise HTTPException(status_code=404, detail="Question not found.")

    actor = repository.get_user(payload.actor_id)
    if actor is None:
        raise HTTPException(status_code=404, detail="Actor not found.")

    is_author = payload.actor_id == question["author_id"]
    is_target_doctor = payload.actor_id == question["target_doctor_id"]
    is_admin = actor.get("role") == "admin"
    if not (is_author or is_target_doctor or is_admin):
        raise HTTPException(status_code=403, detail="Only the thread author, assigned doctor, or an admin can comment.")

    message = ThreadMessageRecord(
        question_id=payload.question_id,
        actor_id=payload.actor_id,
        actor_role=actor["role"],
        body=payload.body.strip(),
        message_mode=payload.message_mode,
        attachment_ids=payload.attachment_ids,
    ).model_dump(mode="json")
    reopen = actor.get("role") == "patient"
    created = repository.add_thread_message(payload.question_id, message, reopen=reopen)
    if created is None:
        raise HTTPException(status_code=404, detail="Question not found.")

    subject = f"MedicoHub thread update: {question['title']}"
    preview = (
        f"A new thread message was posted in MedicoHub.\n\n"
        f"Question: {question['title']}\n"
        f"From: {actor.get('display_name')}\n\n"
        f"Message:\n{payload.body.strip()[:500]}"
    )
    author = repository.get_user(question["author_id"])
    target_doctor = repository.get_user(question["target_doctor_id"])
    if actor.get("role") == "patient":
        if target_doctor is not None:
            _queue_notification_pair(
                event_type="question_created",
                recipient=target_doctor,
                subject=subject,
                body=preview,
            )
    else:
        if author is not None:
            _queue_notification_pair(
                event_type="question_answered",
                recipient=author,
                subject=subject,
                body=preview,
            )
    emit_audit("thread_message", message["id"], "created", payload.actor_id, message)
    return {
        **message,
        "actor_name": actor.get("display_name", "Unknown user"),
    }


def moderate_thread_message(
    question_id: str,
    message_id: str,
    payload: ThreadMessageModerationRequest,
) -> dict:
    actor = repository.get_user(payload.actor_id)
    if actor is None:
        raise HTTPException(status_code=404, detail="Actor not found.")
    if actor.get("role") not in {"doctor", "admin"} and not actor.get("can_moderate_content"):
        raise HTTPException(status_code=403, detail="Only doctors and admins can moderate thread messages.")

    question = next((item for item in repository.list_questions() if item["id"] == question_id), None)
    if question is None:
        raise HTTPException(status_code=404, detail="Question not found.")
    if actor.get("role") not in {"doctor", "admin"} and not actor.get("can_moderate_content"):
        raise HTTPException(status_code=403, detail="Only doctors and admins can moderate this thread.")

    moderated = repository.moderate_thread_message(
        question_id,
        message_id,
        payload.moderation_state,
    )
    if moderated is None:
        raise HTTPException(status_code=404, detail="Thread message not found.")
    emit_audit("thread_message", message_id, "moderated", payload.actor_id, moderated)
    return moderated


def list_education() -> list[dict]:
    return repository.list_education()


def list_blog_articles() -> list[dict]:
    articles = repository.list_blog_articles()
    users = {user["id"]: user for user in repository.list_users()}
    decorated = []
    for article in articles:
        article = _decorate_article_sections(article)
        author = users.get(article["author_id"])
        if article.get("youtube_url") and not article.get("youtube_video_id"):
            try:
                _, article["youtube_video_id"] = _normalize_youtube_url(article.get("youtube_url"))
            except HTTPException:
                article["youtube_video_id"] = None
        decorated.append(
            {
                **article,
                "author_name": author.get("display_name") if author else "Unknown doctor",
            }
        )
    return sorted(decorated, key=lambda item: item.get("updated_at", ""), reverse=True)


def _normalize_youtube_url(raw_url: str | None, raw_video_id: str | None = None) -> tuple[str | None, str | None]:
    """Store YouTube videos as original URL plus normalized videoId for safe playback/API use."""
    candidate = (raw_video_id or "").strip()
    if candidate and _is_valid_youtube_video_id(candidate):
        return raw_url.strip() if raw_url else f"https://www.youtube.com/watch?v={candidate}", candidate

    url = (raw_url or "").strip()
    if not url:
        return None, None

    parsed = urlparse(url if "://" in url else f"https://{url}")
    host = parsed.netloc.lower().removeprefix("www.")
    video_id: str | None = None
    if host in {"youtube.com", "m.youtube.com", "music.youtube.com"}:
        video_id = parse_qs(parsed.query).get("v", [None])[0]
        if not video_id and parsed.path.startswith("/shorts/"):
            video_id = parsed.path.split("/")[2] if len(parsed.path.split("/")) > 2 else None
        if not video_id and parsed.path.startswith("/embed/"):
            video_id = parsed.path.split("/")[2] if len(parsed.path.split("/")) > 2 else None
    elif host == "youtu.be":
        video_id = parsed.path.strip("/").split("/")[0]

    if not video_id or not _is_valid_youtube_video_id(video_id):
        raise HTTPException(status_code=400, detail="Enter a valid YouTube video URL.")
    return url, video_id


def _is_valid_youtube_video_id(video_id: str) -> bool:
    return len(video_id) == 11 and all(ch.isalnum() or ch in {"_", "-"} for ch in video_id)


def create_blog_article(payload: BlogArticleCreate) -> dict:
    author = repository.get_user(payload.author_id)
    if author is None:
        raise HTTPException(status_code=404, detail="Author not found.")
    if author.get("role") not in {"doctor", "admin"}:
        raise HTTPException(status_code=403, detail="Only doctors and admins can publish articles.")

    youtube_url, youtube_video_id = _normalize_youtube_url(payload.youtube_url, payload.youtube_video_id)
    sections, section_order = _normalize_article_sections(
        payload.sections,
        payload.section_order,
        legacy_summary=payload.summary,
        legacy_body=payload.body,
    )
    if not sections:
        raise HTTPException(status_code=400, detail="Add at least one non-empty article section before publishing.")
    article = BlogArticleRecord(
        author_id=payload.author_id,
        title=payload.title.strip(),
        summary=payload.summary.strip(),
        body=payload.body.strip(),
        category=payload.category.strip() or "General Health",
        language=payload.language.strip() or "English",
        source_url=payload.source_url,
        image_url=payload.image_url,
        youtube_url=youtube_url,
        youtube_video_id=youtube_video_id,
        body_format=payload.body_format,
        default_language=payload.default_language.strip() or "en",
        section_order=section_order,
        sections=sections,
    ).model_dump(mode="json")
    repository.create_blog_article(article)
    emit_audit("blog_article", article["id"], "created", payload.author_id, article)
    return {
        **article,
        "author_name": author.get("display_name", "Unknown doctor"),
    }


def update_blog_article(article_id: str, payload: BlogArticleUpdate) -> dict:
    actor = repository.get_user(payload.actor_id)
    if actor is None:
        raise HTTPException(status_code=404, detail="Actor not found.")
    current = next((item for item in repository.list_blog_articles() if item.get("id") == article_id), None)
    if current is None:
        raise HTTPException(status_code=404, detail="Article not found.")
    if actor.get("role") not in {"doctor", "admin"}:
        raise HTTPException(status_code=403, detail="Only doctors and admins can edit articles.")
    if actor.get("role") != "admin" and current.get("author_id") != payload.actor_id:
        raise HTTPException(status_code=403, detail="Only the author or an admin can edit this article.")

    updates = {
        key: value.strip() if isinstance(value, str) else value
        for key, value in payload.model_dump(exclude={"actor_id"}, exclude_none=True).items()
    }
    if "sections" in updates or "section_order" in updates:
        sections, section_order = _normalize_article_sections(
            updates.get("sections", current.get("sections")),
            updates.get("section_order", current.get("section_order")),
            legacy_summary=updates.get("summary", current.get("summary") or ""),
            legacy_body=updates.get("body", current.get("body") or ""),
        )
        if not sections:
            raise HTTPException(status_code=400, detail="Add at least one non-empty article section before publishing.")
        updates["sections"] = sections
        updates["section_order"] = section_order
    if "youtube_url" in updates or "youtube_video_id" in updates:
        youtube_url, youtube_video_id = _normalize_youtube_url(
            updates.get("youtube_url"),
            updates.get("youtube_video_id"),
        )
        updates["youtube_url"] = youtube_url
        updates["youtube_video_id"] = youtube_video_id
    updates["updated_at"] = utc_now().isoformat()
    article = repository.update_blog_article(article_id, updates)
    if article is None:
        raise HTTPException(status_code=404, detail="Article not found.")
    emit_audit("blog_article", article_id, "updated", payload.actor_id, updates)
    mark_growth_derivatives_review_required(article_id, payload.actor_id)
    return {
        **article,
        "author_name": repository.get_user(article["author_id"]).get("display_name", "Unknown doctor")
        if repository.get_user(article["author_id"])
        else "Unknown doctor",
    }


def add_blog_article_comment(article_id: str, payload: BlogArticleCommentCreate) -> dict:
    actor = repository.get_user(payload.actor_id)
    if actor is None:
        raise HTTPException(status_code=404, detail="Actor not found.")
    if not payload.body.strip():
        raise HTTPException(status_code=400, detail="Comment body is required.")
    comment = BlogArticleCommentRecord(
        actor_id=payload.actor_id,
        actor_name=actor.get("display_name", "MedicoHub user"),
        actor_role=actor.get("role", "patient"),
        body=payload.body.strip(),
        parent_id=payload.parent_id,
        message_mode=payload.message_mode,
    ).model_dump(mode="json")
    created = repository.add_blog_article_comment(article_id, comment)
    if created is None:
        raise HTTPException(status_code=404, detail="Article not found.")
    emit_audit("blog_article_comment", comment["id"], "created", payload.actor_id, comment)
    return created


def moderate_blog_article_comment(article_id: str, comment_id: str, payload: ThreadMessageModerationRequest) -> dict:
    actor = repository.get_user(payload.actor_id)
    if actor is None:
        raise HTTPException(status_code=404, detail="Actor not found.")
    article = next((item for item in repository.list_blog_articles() if item.get("id") == article_id), None)
    if article is None:
        raise HTTPException(status_code=404, detail="Article not found.")
    comment = next((item for item in article.get("comments", []) if item.get("id") == comment_id), None)
    if comment is None:
        raise HTTPException(status_code=404, detail="Comment not found.")
    can_delete_own = comment.get("actor_id") == payload.actor_id
    can_moderate = actor.get("role") in {"doctor", "admin"} or actor.get("can_moderate_content")
    if not can_delete_own and not can_moderate:
        raise HTTPException(status_code=403, detail="You can only delete your own comment.")
    moderated = repository.moderate_blog_article_comment(
        article_id,
        comment_id,
        payload.moderation_state,
    )
    if moderated is None:
        raise HTTPException(status_code=404, detail="Comment not found.")
    emit_audit("blog_article_comment", comment_id, "moderated", payload.actor_id, moderated)
    return moderated


def like_blog_article(article_id: str, payload: BlogArticleLikeRequest) -> dict:
    actor = repository.get_user(payload.actor_id)
    if actor is None:
        raise HTTPException(status_code=404, detail="Actor not found.")
    article = repository.like_blog_article(article_id, payload.actor_id)
    if article is None:
        raise HTTPException(status_code=404, detail="Article not found.")
    return article


def list_notifications(user_id: str | None = None) -> list[dict]:
    notifications = repository.list_notifications()
    if user_id:
        notifications = [item for item in notifications if item.get("recipient_user_id") == user_id]
    return sorted(notifications, key=lambda item: item.get("created_at", ""), reverse=True)


def list_title_templates() -> list[dict]:
    templates = repository.list_title_templates()
    return sorted(
        [template for template in templates if template.get("active", True)],
        key=lambda item: (item.get("language", ""), item.get("specialty", ""), item.get("title", "")),
    )


def create_title_template(payload: TitleTemplateCreate) -> dict:
    actor = repository.get_user(payload.actor_id)
    if actor is None:
        raise HTTPException(status_code=404, detail="Actor not found.")
    if actor.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Only administrators can add title templates.")

    template = TitleTemplate(
        title=payload.title.strip(),
        specialty=payload.specialty.strip() or "General Health",
        language=payload.language.strip() or "English",
        created_by=payload.actor_id,
    ).model_dump(mode="json")
    repository.create_title_template(template)
    emit_audit("title_template", template["id"], "created", payload.actor_id, template)
    return template


def create_payment_intent(payload: PaymentIntentRequest) -> dict:
    payment = PaymentIntentResponse(
        payment_id=f"pay_{payload.provider}_{payload.question_id[-6:]}",
        provider=payload.provider,
        amount_aed=payload.amount_aed,
        checkout_hint=(
            f"Launch {payload.provider.title()} checkout for question {payload.question_id} "
            f"and mark the thread premium once payment succeeds."
        ),
    ).model_dump(mode="json")
    repository.create_payment(
        {
            **payment,
            "question_id": payload.question_id,
            "user_id": payload.user_id,
        }
    )
    emit_audit("payment", payment["payment_id"], "created", payload.user_id, payment)
    return payment


def translate_text(payload: TranslationRequest) -> TranslationResponse:
    try:
        from .translation.translation_router import TranslationPayload, translate_payload
    except ImportError:
        from translation.translation_router import TranslationPayload, translate_payload  # type: ignore

    result = translate_payload(
        TranslationPayload(
            text=payload.text,
            source_lang=payload.sourceLang,
            target_lang=payload.targetLang,
            content_type=payload.contentType,
            medical_mode=payload.medicalMode,
            allow_paid_fallback=payload.allowPaidFallback,
        )
    )
    return TranslationResponse(**result)


def translate_article_section(payload: SectionTranslationRequest) -> SectionTranslationResponse:
    source_lang = (payload.sourceLang or "en").strip().lower()
    target_lang = (payload.targetLang or "en").strip().lower()
    source_text = (payload.plainText or _plain_from_rich_text(payload.richTextHtml)).strip()
    rich_text = (payload.richTextHtml or source_text).strip()
    content_hash = _content_hash(rich_text or source_text)

    if not source_text:
        return SectionTranslationResponse(
            success=False,
            articleId=payload.articleId,
            sectionId=payload.sectionId,
            sourceLang=source_lang,
            targetLang=target_lang,
            contentHash=content_hash,
            cacheSource="none",
            errorCode="empty_section",
            message="This section is empty.",
        )
    if source_lang == target_lang:
        return SectionTranslationResponse(
            success=True,
            articleId=payload.articleId,
            sectionId=payload.sectionId,
            sourceLang=source_lang,
            targetLang=target_lang,
            contentHash=content_hash,
            translatedRichTextHtml=rich_text,
            translatedPlainText=source_text,
            cacheSource="server",
            warning=ARTICLE_TRANSLATION_WARNING,
        )

    translation_key = _translation_key(
        article_id=payload.articleId,
        section_id=payload.sectionId,
        source_lang=source_lang,
        target_lang=target_lang,
        content_hash=content_hash,
    )
    cached = repository.get_article_translation(translation_key)
    if cached:
        return SectionTranslationResponse(
            success=True,
            articleId=payload.articleId,
            sectionId=payload.sectionId,
            sourceLang=source_lang,
            targetLang=target_lang,
            contentHash=content_hash,
            translatedRichTextHtml=cached.get("translatedRichTextHtml") or "",
            translatedPlainText=cached.get("translatedPlainText") or "",
            provider=cached.get("provider") or "microsoft-azure",
            cacheSource="server",
            warning=ARTICLE_TRANSLATION_WARNING,
        )

    result = translate_text(
        TranslationRequest(
            text=rich_text,
            sourceLang=source_lang,
            targetLang=target_lang,
            contentType="html" if rich_text.lstrip().startswith("<") else payload.contentType,
            medicalMode=True,
            allowPaidFallback=False,
        )
    )
    if result.errorMessage:
        return SectionTranslationResponse(
            success=False,
            articleId=payload.articleId,
            sectionId=payload.sectionId,
            sourceLang=source_lang,
            targetLang=target_lang,
            contentHash=content_hash,
            provider=result.provider or "microsoft-azure",
            cacheSource="none",
            errorCode="provider_failed",
            message="Could not translate now. Please try again later.",
            detailsForAdminOnly=result.errorMessage,
        )

    now = utc_now().isoformat()
    translated_html = result.translatedText
    translated_plain = _plain_from_rich_text(translated_html).strip() or translated_html
    translation_record = {
        "articleId": payload.articleId,
        "sectionId": payload.sectionId,
        "sourceLang": source_lang,
        "targetLang": target_lang,
        "contentHash": content_hash,
        "provider": "microsoft-azure",
        "providerVersion": ARTICLE_TRANSLATION_PROVIDER_VERSION,
        "translatedRichTextHtml": translated_html,
        "translatedPlainText": translated_plain,
        "createdAt": now,
        "updatedAt": now,
        "sourceUpdatedAt": payload.sourceUpdatedAt,
        "createdBy": "system",
        "reviewedByDoctor": False,
    }
    repository.save_article_translation(translation_key, translation_record)
    emit_audit(
        "article_translation",
        translation_key,
        "created",
        "system",
        {
            "articleId": payload.articleId,
            "sectionId": payload.sectionId,
            "sourceLang": source_lang,
            "targetLang": target_lang,
            "provider": "microsoft-azure",
            "characterCount": len(source_text),
        },
    )
    return SectionTranslationResponse(
        success=True,
        articleId=payload.articleId,
        sectionId=payload.sectionId,
        sourceLang=source_lang,
        targetLang=target_lang,
        contentHash=content_hash,
        translatedRichTextHtml=translated_html,
        translatedPlainText=translated_plain,
        provider="microsoft-azure",
        cacheSource="provider",
        warning=ARTICLE_TRANSLATION_WARNING,
    )


def resolve_report_pdf(pmc_id: str, article_url: str | None = None) -> dict:
    return {
        "pmc_id": pmc_id,
        "resolved_pdf_url": pdf_ingestion.resolve_pdf_url(pmc_id=pmc_id, article_url=article_url),
    }
