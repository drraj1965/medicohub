from __future__ import annotations

import random
import smtplib
from datetime import datetime, timezone
from email.message import EmailMessage
from urllib.parse import quote

from fastapi import HTTPException, UploadFile
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
        BlogArticleRecord,
        DEFAULT_QUESTION_TOPICS,
        DoctorInviteCreate,
        DoctorResponseInput,
        DoctorResponseRecord,
        EducationItem,
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
        QuestionRecord,
        ThreadMessageInput,
        ThreadMessageModerationRequest,
        ThreadMessageRecord,
        QuestionUpdateRequest,
        TitleTemplate,
        TitleTemplateCreate,
        User,
        UserDeleteRequest,
        UserProfileUpsertRequest,
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
        BlogArticleRecord,
        DEFAULT_QUESTION_TOPICS,
        DoctorInviteCreate,
        DoctorResponseInput,
        DoctorResponseRecord,
        EducationItem,
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
        QuestionRecord,
        ThreadMessageInput,
        ThreadMessageModerationRequest,
        ThreadMessageRecord,
        QuestionUpdateRequest,
        TitleTemplate,
        TitleTemplateCreate,
        User,
        UserDeleteRequest,
        UserProfileUpsertRequest,
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
settings = get_settings()
NOTIFICATION_REQUEST_TIMEOUT_SECONDS = 5

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


def _find_user_by_email_or_phone(email: str | None, phone_number: str | None) -> dict | None:
    normalized_email = _normalize_email(email)
    normalized_phone = _normalize_phone(phone_number)
    for user in repository.list_users():
        if normalized_email and _normalize_email(user.get("email")) == normalized_email:
            return user
        if normalized_phone and _normalize_phone(user.get("phone_number")) == normalized_phone:
            return user
    return None


def _serialize_user(user: dict) -> dict:
    clean = dict(user)
    clean.pop("password", None)
    return clean


def _mailto_link(*, to_email: str, subject: str, body: str) -> str:
    encoded_subject = quote(subject)
    encoded_body = quote(body)
    return f"mailto:{to_email}?subject={encoded_subject}&body={encoded_body}"


def _whatsapp_link(*, phone_number: str, body: str) -> str:
    digits = "".join(character for character in phone_number if character.isdigit())
    return f"https://wa.me/{digits}?text={quote(body)}"


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
        email_sent = False
        try:
            email_sent = _send_email_message(recipient_email, subject, body)
        except Exception:
            email_sent = False
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
                status="sent" if email_sent else "preview_ready",
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


def lookup_user_by_email(email: str) -> dict | None:
    user = _find_user_by_email_or_phone(email, None)
    if user is None:
        return None
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
    existing_by_identity = _find_user_by_email_or_phone(payload.email, payload.phone_number)
    existing_consent = existing.get("consent") if existing else None
    existing_created_at = existing.get("created_at") if existing else utc_now()
    existing_password = existing.get("password", "Passw0rd!") if existing else "Passw0rd!"

    role = payload.role
    verified = bool(payload.verified)
    can_manage_doctors = False
    can_moderate_content = False
    doctor_status = "not_applicable"
    invited_by = existing.get("invited_by") if existing else None
    display_name = payload.display_name.strip()
    phone_number = payload.phone_number
    specialties = payload.specialties or []

    if role == "admin":
        allowlisted = next(
            (
                admin
                for admin in ADMIN_SEED
                if _normalize_email(admin["email"]) == _normalize_email(payload.email)
                or _normalize_phone(admin["phone_number"]) == _normalize_phone(payload.phone_number)
            ),
            None,
        )
        if allowlisted is None:
            raise HTTPException(
                status_code=403,
                detail="This email or phone number is not on the MedicoHub admin allowlist.",
            )
        verified = True
        can_manage_doctors = True
        can_moderate_content = True
        doctor_status = "active"
        display_name = allowlisted["display_name"]
        phone_number = allowlisted["phone_number"]
        specialties = allowlisted["specialties"]
        languages = allowlisted["languages"]
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
        "role": role,
        "verified": verified,
        "languages": languages,
        "specialties": specialties,
        "doctor_status": doctor_status,
        "can_manage_doctors": can_manage_doctors,
        "can_moderate_content": can_moderate_content,
        "invited_by": invited_by,
        "created_at": existing_created_at,
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
    assigned_doctor = repository.get_user(question.get("target_doctor_id", ""))
    if actor.get("role") != "admin":
        direct_assignment = question.get("target_doctor_id") == actor.get("id")
        email_assignment = _normalize_email(actor.get("email")) == _normalize_email(
            assigned_doctor.get("email") if assigned_doctor else None
        )
        if not (direct_assignment or email_assignment):
            raise HTTPException(
                status_code=403,
                detail="Only the assigned doctor or an admin can moderate this thread.",
            )

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
        author = users.get(article["author_id"])
        decorated.append(
            {
                **article,
                "author_name": author.get("display_name") if author else "Unknown doctor",
            }
        )
    return sorted(decorated, key=lambda item: item.get("updated_at", ""), reverse=True)


def create_blog_article(payload: BlogArticleCreate) -> dict:
    author = repository.get_user(payload.author_id)
    if author is None:
        raise HTTPException(status_code=404, detail="Author not found.")
    if author.get("role") not in {"doctor", "admin"}:
        raise HTTPException(status_code=403, detail="Only doctors and admins can publish articles.")

    article = BlogArticleRecord(
        author_id=payload.author_id,
        title=payload.title.strip(),
        summary=payload.summary.strip(),
        body=payload.body.strip(),
        category=payload.category.strip() or "General Health",
        language=payload.language.strip() or "English",
    ).model_dump(mode="json")
    repository.create_blog_article(article)
    emit_audit("blog_article", article["id"], "created", payload.author_id, article)
    return {
        **article,
        "author_name": author.get("display_name", "Unknown doctor"),
    }


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


def resolve_report_pdf(pmc_id: str, article_url: str | None = None) -> dict:
    return {
        "pmc_id": pmc_id,
        "resolved_pdf_url": pdf_ingestion.resolve_pdf_url(pmc_id=pmc_id, article_url=article_url),
    }
