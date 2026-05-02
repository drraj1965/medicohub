from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Literal
from uuid import uuid4

from pydantic import BaseModel, Field, computed_field


UTC = timezone.utc


def utc_now() -> datetime:
    return datetime.now(UTC)


def make_id(prefix: str) -> str:
    return f"{prefix}_{uuid4().hex[:12]}"


class ConsentRecord(BaseModel):
    accepted: bool = True
    accepted_at: datetime = Field(default_factory=utc_now)
    disclaimer: str = (
        "This platform does not provide diagnosis or prescriptions. "
        "For emergencies, contact local emergency services."
    )


class User(BaseModel):
    id: str = Field(default_factory=lambda: make_id("usr"))
    email: str
    password: str = "Passw0rd!"
    display_name: str
    phone_number: str | None = None
    role: Literal["patient", "doctor", "admin"]
    verified: bool = False
    languages: list[str] = Field(default_factory=lambda: ["English"])
    specialties: list[str] = Field(default_factory=list)
    doctor_status: Literal["not_applicable", "invited", "active"] = "not_applicable"
    can_manage_doctors: bool = False
    can_moderate_content: bool = False
    invited_by: str | None = None
    consent: ConsentRecord = Field(default_factory=ConsentRecord)
    created_at: datetime = Field(default_factory=utc_now)


class AuthRequest(BaseModel):
    email: str
    password: str


class AuthResponse(BaseModel):
    access_token: str
    user: User
    consent_required: bool = False


class OtpRequestInput(BaseModel):
    destination: str
    channel: Literal["email", "sms"]
    purpose: Literal["sign_in", "password_reset"] = "sign_in"


class OtpVerifyInput(BaseModel):
    destination: str
    channel: Literal["email", "sms"]
    code: str
    purpose: Literal["sign_in", "password_reset"] = "sign_in"


class OtpRequestRecord(BaseModel):
    id: str = Field(default_factory=lambda: make_id("otp"))
    destination: str
    channel: Literal["email", "sms"]
    purpose: Literal["sign_in", "password_reset"] = "sign_in"
    code: str
    status: Literal["pending", "verified", "expired"] = "pending"
    preview_message: str | None = None
    expires_at: datetime
    created_at: datetime = Field(default_factory=utc_now)
    verified_at: datetime | None = None


class UserProfileUpsertRequest(BaseModel):
    id: str
    email: str
    display_name: str
    phone_number: str | None = None
    role: Literal["patient", "doctor", "admin"] = "patient"
    verified: bool = False
    languages: list[str] = Field(default_factory=lambda: ["English"])
    specialties: list[str] = Field(default_factory=list)


class AttachmentCreate(BaseModel):
    file_name: str
    mime_type: str
    source_link: str | None = None
    expiry_option: Literal["24h", "7d", "30d"] = "7d"


class AttachmentRecord(BaseModel):
    id: str = Field(default_factory=lambda: make_id("att"))
    owner_id: str
    file_name: str
    mime_type: str
    storage_provider: Literal["google_drive", "firebase_storage", "local_stub"] = "local_stub"
    storage_id: str | None = None
    storage_path: str | None = None
    source_link: str | None = None
    temporary_url: str
    extracted_text_preview: str | None = None
    expires_at: datetime
    revoked_at: datetime | None = None
    created_at: datetime = Field(default_factory=utc_now)

    @classmethod
    def from_create(cls, owner_id: str, data: AttachmentCreate) -> "AttachmentRecord":
        ttl_map = {"24h": timedelta(hours=24), "7d": timedelta(days=7), "30d": timedelta(days=30)}
        expires_at = utc_now() + ttl_map[data.expiry_option]
        attachment_id = make_id("att")
        return cls(
            id=attachment_id,
            owner_id=owner_id,
            file_name=data.file_name,
            mime_type=data.mime_type,
            source_link=data.source_link,
            storage_id=attachment_id,
            storage_path=attachment_id,
            temporary_url=f"https://medicohub.local/files/{attachment_id}",
            expires_at=expires_at,
        )


class QuestionCreate(BaseModel):
    author_id: str
    target_doctor_id: str
    type: Literal["forum", "second_opinion"] = "forum"
    heading_group: Literal[
        "Related to my condition",
        "Related to my medications",
        "Related to my test results",
        "General",
    ] = "General"
    title: str
    body: str
    tags: list[str] = Field(default_factory=list)
    language: str = "English"
    symptoms_summary: str | None = None
    current_diagnosis_text: str | None = None
    premium: bool = False
    is_public: bool = False
    attachment_ids: list[str] = Field(default_factory=list)


class QuestionUpdateRequest(BaseModel):
    actor_id: str
    title: str | None = None
    body: str | None = None
    heading_group: Literal[
        "Related to my condition",
        "Related to my medications",
        "Related to my test results",
        "General",
    ] | None = None
    language: str | None = None
    symptoms_summary: str | None = None
    is_public: bool | None = None
    attachment_ids: list[str] | None = None


class QuestionDeleteRequest(BaseModel):
    actor_id: str


class ThreadMessageInput(BaseModel):
    question_id: str
    actor_id: str
    body: str
    message_mode: Literal["text", "voice"] = "text"
    attachment_ids: list[str] = Field(default_factory=list)


class ThreadMessageModerationRequest(BaseModel):
    actor_id: str
    moderation_state: Literal["visible", "hidden"]


class ThreadMessageRecord(BaseModel):
    id: str = Field(default_factory=lambda: make_id("msg"))
    question_id: str
    actor_id: str
    actor_role: Literal["patient", "doctor", "admin"]
    body: str
    message_mode: Literal["text", "voice"] = "text"
    attachment_ids: list[str] = Field(default_factory=list)
    moderation_state: Literal["visible", "hidden"] = "visible"
    created_at: datetime = Field(default_factory=utc_now)


class DoctorResponseInput(BaseModel):
    question_id: str
    doctor_id: str
    key_points: str
    what_it_means: str
    what_to_discuss_with_doctor: str
    full_text: str
    response_mode: Literal["text", "voice"] = "text"


class DoctorResponseRecord(BaseModel):
    id: str = Field(default_factory=lambda: make_id("rsp"))
    question_id: str
    doctor_id: str
    labels: list[str] = Field(
        default_factory=lambda: ["Educational", "General guidance", "Opinion only"]
    )
    key_points: str
    what_it_means: str
    what_to_discuss_with_doctor: str
    full_text: str
    response_mode: Literal["text", "voice"] = "text"
    created_at: datetime = Field(default_factory=utc_now)


class BlogArticleCreate(BaseModel):
    author_id: str
    title: str
    summary: str
    body: str
    category: str = "General Health"
    language: str = "English"


class BlogArticleRecord(BaseModel):
    id: str = Field(default_factory=lambda: make_id("art"))
    author_id: str
    title: str
    summary: str
    body: str
    category: str = "General Health"
    language: str = "English"
    status: Literal["published", "draft"] = "published"
    created_at: datetime = Field(default_factory=utc_now)
    updated_at: datetime = Field(default_factory=utc_now)


class NotificationEvent(BaseModel):
    id: str = Field(default_factory=lambda: make_id("ntf"))
    event_type: Literal["question_created", "question_answered"]
    channel: Literal["email", "whatsapp"]
    recipient_user_id: str
    recipient_name: str
    recipient_email: str | None = None
    recipient_phone_number: str | None = None
    subject: str
    body: str
    deep_link: str | None = None
    status: Literal["queued", "preview_ready", "sent"] = "preview_ready"
    created_at: datetime = Field(default_factory=utc_now)


class NotificationSettings(BaseModel):
    id: str = "notification_settings"
    whatsapp_activation_enabled: bool = True
    whatsapp_activation_target: str = "+14155238886"
    whatsapp_activation_phrase: str = "join cloud-tired"
    email_status_note: str = "Email notifications are coming later."
    updated_by: str = "system"
    updated_at: datetime = Field(default_factory=utc_now)


class NotificationSettingsUpdate(BaseModel):
    actor_id: str
    whatsapp_activation_enabled: bool = True
    whatsapp_activation_target: str
    whatsapp_activation_phrase: str
    email_status_note: str = "Email notifications are coming later."


class AdCampaignRecord(BaseModel):
    id: str = Field(default_factory=lambda: make_id("ad"))
    sponsor_name: str = "Sponsored"
    title: str
    subtitle: str
    cta_label: str = "Learn more"
    target_url: str
    keywords: list[str] = Field(default_factory=list)
    categories: list[str] = Field(default_factory=list)
    placements: list[Literal["home", "question", "education", "blog"]] = Field(
        default_factory=lambda: ["home"]
    )
    languages: list[str] = Field(default_factory=list)
    priority: int = 50
    active: bool = True
    created_by: str
    created_at: datetime = Field(default_factory=utc_now)
    updated_at: datetime = Field(default_factory=utc_now)


class AdCampaignCreate(BaseModel):
    actor_id: str
    sponsor_name: str = "Sponsored"
    title: str
    subtitle: str
    cta_label: str = "Learn more"
    target_url: str
    keywords: list[str] = Field(default_factory=list)
    categories: list[str] = Field(default_factory=list)
    placements: list[Literal["home", "question", "education", "blog"]] = Field(
        default_factory=lambda: ["home"]
    )
    languages: list[str] = Field(default_factory=list)
    priority: int = 50


class AdCampaignUpdate(BaseModel):
    actor_id: str
    sponsor_name: str | None = None
    title: str | None = None
    subtitle: str | None = None
    cta_label: str | None = None
    target_url: str | None = None
    keywords: list[str] | None = None
    categories: list[str] | None = None
    placements: list[Literal["home", "question", "education", "blog"]] | None = None
    languages: list[str] | None = None
    priority: int | None = None
    active: bool | None = None


class QuestionRecord(BaseModel):
    id: str = Field(default_factory=lambda: make_id("qst"))
    author_id: str
    target_doctor_id: str
    type: Literal["forum", "second_opinion"] = "forum"
    heading_group: Literal[
        "Related to my condition",
        "Related to my medications",
        "Related to my test results",
        "General",
    ] = "General"
    title: str
    body: str
    tags: list[str] = Field(default_factory=list)
    language: str = "English"
    symptoms_summary: str | None = None
    current_diagnosis_text: str | None = None
    premium: bool = False
    is_public: bool = False
    payment_status: Literal["not_required", "pending", "paid"] = "not_required"
    status: Literal["open", "answered", "closed", "deleted"] = "open"
    bookmark_count: int = 0
    upvote_count: int = 0
    attachment_ids: list[str] = Field(default_factory=list)
    thread_messages: list[ThreadMessageRecord] = Field(default_factory=list)
    responses: list[DoctorResponseRecord] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=utc_now)
    updated_at: datetime = Field(default_factory=utc_now)

    @computed_field
    @property
    def ai_summary(self) -> str:
        if self.responses:
            latest = self.responses[-1]
            return (
                f"Question about {self.title}. Latest reply highlights: "
                f"{latest.key_points[:140]}"
            )
        return f"Open {self.type.replace('_', ' ')} request tagged {', '.join(self.tags[:3]) or 'general health'}."

    @classmethod
    def from_create(cls, data: QuestionCreate) -> "QuestionRecord":
        payment_status = "paid" if (data.premium and data.type == "second_opinion") else "not_required"
        return cls(
            author_id=data.author_id,
            target_doctor_id=data.target_doctor_id,
            type=data.type,
            heading_group=data.heading_group,
            title=data.title,
            body=data.body,
            tags=data.tags,
            language=data.language,
            symptoms_summary=data.symptoms_summary,
            current_diagnosis_text=data.current_diagnosis_text,
            premium=data.premium,
            is_public=data.is_public,
            payment_status=payment_status,
            attachment_ids=data.attachment_ids,
            thread_messages=[
                ThreadMessageRecord(
                    question_id="pending",
                    actor_id=data.author_id,
                    actor_role="patient",
                    body=data.body,
                    attachment_ids=data.attachment_ids,
                )
            ],
        )


class EducationItem(BaseModel):
    id: str = Field(default_factory=lambda: make_id("edu"))
    title: str
    category: str
    type: Literal["article", "video"] = "article"
    summary: str
    language: str = "English"
    duration_minutes: int = 5
    url: str


class TitleTemplateCreate(BaseModel):
    actor_id: str
    title: str
    specialty: str = "General Health"
    language: str = "English"


class DoctorInviteCreate(BaseModel):
    actor_id: str
    email: str
    display_name: str
    phone_number: str | None = None
    specialties: list[str] = Field(default_factory=lambda: ["General Health"])
    languages: list[str] = Field(default_factory=lambda: ["English"])


class TitleTemplate(BaseModel):
    id: str = Field(default_factory=lambda: make_id("ttl"))
    title: str
    specialty: str = "General Health"
    language: str = "English"
    active: bool = True
    created_by: str = "system"
    created_at: datetime = Field(default_factory=utc_now)


class PaymentIntentRequest(BaseModel):
    user_id: str
    question_id: str
    provider: Literal["stripe", "razorpay"]
    amount_aed: int


class PaymentIntentResponse(BaseModel):
    payment_id: str
    provider: str
    amount_aed: int
    currency: str = "AED"
    status: str = "requires_action"
    checkout_hint: str


class AuditEvent(BaseModel):
    id: str = Field(default_factory=lambda: make_id("evt"))
    entity_type: str
    entity_id: str
    action: str
    actor_id: str
    payload: dict
    created_at: datetime = Field(default_factory=utc_now)
