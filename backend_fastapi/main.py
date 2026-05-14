from __future__ import annotations

from fastapi import FastAPI, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware

try:
    from .models import (
        AdCampaignCreate,
        AdCampaignUpdate,
        AppSettingsUpdate,
        AttachmentCreate,
        AuthRequest,
        AuthResponse,
        BlogArticleCreate,
        DoctorInviteCreate,
        DoctorResponseInput,
        NotificationSettingsUpdate,
        OtpRequestInput,
        OtpVerifyInput,
        PaymentIntentRequest,
        QuestionCreate,
        QuestionDeleteRequest,
        ThreadMessageInput,
        ThreadMessageModerationRequest,
        QuestionUpdateRequest,
        TitleTemplateCreate,
        UserDeleteRequest,
        UserProfileUpsertRequest,
    )
    from .services import (
        add_response,
        create_ad_campaign,
        add_thread_message,
        authenticate,
        create_blog_article,
        create_attachment,
        delete_question,
        delete_user_account,
        invite_doctor,
        create_payment_intent,
        create_question,
        get_app_settings,
        get_notification_settings,
        create_title_template,
        get_user_profile,
        list_education,
        list_doctors,
        list_blog_articles,
        list_ad_campaigns,
        list_notifications,
        list_questions,
        list_title_templates,
        list_users,
        lookup_user_by_email,
        moderate_thread_message,
        request_otp,
        resolve_report_pdf,
        revoke_attachment,
        verify_otp,
        seed_if_needed,
        should_seed_demo_data,
        update_ad_campaign,
        update_app_settings,
        update_notification_settings,
        update_question,
        upsert_user_profile,
        upload_attachment_file,
    )
    from .storage import read_audit
except ImportError:
    from models import (  # type: ignore
        AdCampaignCreate,
        AdCampaignUpdate,
        AppSettingsUpdate,
        AttachmentCreate,
        AuthRequest,
        AuthResponse,
        BlogArticleCreate,
        DoctorInviteCreate,
        DoctorResponseInput,
        NotificationSettingsUpdate,
        OtpRequestInput,
        OtpVerifyInput,
        PaymentIntentRequest,
        QuestionCreate,
        QuestionDeleteRequest,
        ThreadMessageInput,
        ThreadMessageModerationRequest,
        QuestionUpdateRequest,
        TitleTemplateCreate,
        UserDeleteRequest,
        UserProfileUpsertRequest,
    )
    from services import (  # type: ignore
        add_response,
        create_ad_campaign,
        add_thread_message,
        authenticate,
        create_blog_article,
        create_attachment,
        delete_question,
        delete_user_account,
        invite_doctor,
        create_payment_intent,
        create_question,
        get_app_settings,
        get_notification_settings,
        create_title_template,
        get_user_profile,
        list_education,
        list_doctors,
        list_blog_articles,
        list_ad_campaigns,
        list_notifications,
        list_questions,
        list_title_templates,
        list_users,
        lookup_user_by_email,
        moderate_thread_message,
        request_otp,
        resolve_report_pdf,
        revoke_attachment,
        verify_otp,
        seed_if_needed,
        should_seed_demo_data,
        update_ad_campaign,
        update_app_settings,
        update_notification_settings,
        update_question,
        upsert_user_profile,
        upload_attachment_file,
    )
    from storage import read_audit  # type: ignore


app = FastAPI(title="MedicoHub Backend", version="1.3.8")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

if should_seed_demo_data():
    seed_if_needed()


@app.get("/")
def root() -> dict:
    return {
        "status": "ok",
        "service": "MedicoHub Backend",
        "disclaimer": "Educational only. No diagnosis, prescriptions, or emergency handling.",
    }


@app.post("/auth/login", response_model=AuthResponse)
def login(payload: AuthRequest) -> AuthResponse:
    user = authenticate(payload.email, payload.password)
    return AuthResponse(access_token=f"local-dev-token-{user['id']}", user=user)


@app.post("/auth/otp/request")
def otp_request(payload: OtpRequestInput) -> dict:
    return request_otp(payload)


@app.post("/auth/otp/verify")
def otp_verify(payload: OtpVerifyInput) -> dict:
    return verify_otp(payload)


@app.get("/auth/test-accounts")
def test_accounts() -> list[dict]:
    return list_users()


@app.get("/doctors")
def doctors() -> list[dict]:
    return list_doctors()


@app.post("/doctors/invite")
def add_doctor(payload: DoctorInviteCreate) -> dict:
    return invite_doctor(payload)


@app.get("/users/lookup/by-email")
def lookup_user(email: str) -> dict | None:
    return lookup_user_by_email(email)


@app.get("/users/{user_id}")
def get_user(user_id: str) -> dict:
    return get_user_profile(user_id)


@app.post("/users/profile")
def upsert_user(payload: UserProfileUpsertRequest) -> dict:
    return upsert_user_profile(payload)


@app.delete("/users/{user_id}")
def delete_user(user_id: str, payload: UserDeleteRequest) -> dict:
    return delete_user_account(user_id, payload)


@app.get("/questions")
def get_questions() -> list[dict]:
    return list_questions()


@app.post("/questions")
def post_question(payload: QuestionCreate) -> dict:
    return create_question(payload)


@app.patch("/questions/{question_id}")
def patch_question(question_id: str, payload: QuestionUpdateRequest) -> dict:
    return update_question(question_id, payload)


@app.delete("/questions/{question_id}")
def remove_question(question_id: str, payload: QuestionDeleteRequest) -> dict:
    return delete_question(question_id, payload)


@app.post("/upload")
def upload(owner_id: str, payload: AttachmentCreate) -> dict:
    return create_attachment(owner_id, payload)


@app.post("/upload/file")
async def upload_file(
    owner_id: str = Form(...),
    expiry_option: str = Form("7d"),
    file: UploadFile = File(...),
) -> dict:
    return await upload_attachment_file(
        owner_id=owner_id,
        expiry_option=expiry_option,
        file=file,
    )


@app.post("/upload/{attachment_id}/revoke")
def revoke_upload(attachment_id: str, actor_id: str) -> dict:
    return revoke_attachment(attachment_id, actor_id)


@app.get("/upload/resolve-report")
def resolve_report_source(pmc_id: str, article_url: str | None = None) -> dict:
    return resolve_report_pdf(pmc_id=pmc_id, article_url=article_url)


@app.post("/doctor/respond")
def doctor_respond(payload: DoctorResponseInput) -> dict:
    return add_response(payload)


@app.post("/questions/{question_id}/messages")
def post_thread_message(question_id: str, payload: ThreadMessageInput) -> dict:
    if payload.question_id != question_id:
        payload = payload.model_copy(update={"question_id": question_id})
    return add_thread_message(payload)


@app.patch("/questions/{question_id}/messages/{message_id}")
def patch_thread_message(
    question_id: str,
    message_id: str,
    payload: ThreadMessageModerationRequest,
) -> dict:
    return moderate_thread_message(question_id, message_id, payload)


@app.get("/blog/articles")
def blog_articles() -> list[dict]:
    return list_blog_articles()


@app.post("/blog/articles")
def publish_blog_article(payload: BlogArticleCreate) -> dict:
    return create_blog_article(payload)


@app.get("/ad-campaigns")
def ad_campaigns() -> list[dict]:
    return list_ad_campaigns()


@app.post("/ad-campaigns")
def save_ad_campaign(payload: AdCampaignCreate) -> dict:
    return create_ad_campaign(payload)


@app.patch("/ad-campaigns/{campaign_id}")
def patch_ad_campaign(campaign_id: str, payload: AdCampaignUpdate) -> dict:
    return update_ad_campaign(campaign_id, payload)


@app.get("/notifications/outbox")
def notification_outbox(user_id: str | None = None) -> list[dict]:
    return list_notifications(user_id=user_id)


@app.get("/notification-settings")
def notification_settings() -> dict:
    return get_notification_settings()


@app.post("/notification-settings")
def save_notification_settings(payload: NotificationSettingsUpdate) -> dict:
    return update_notification_settings(payload)


@app.get("/app-settings")
def app_settings() -> dict:
    return get_app_settings()


@app.post("/app-settings")
def save_app_settings(payload: AppSettingsUpdate) -> dict:
    return update_app_settings(payload)


@app.get("/education/library")
def education_library() -> list[dict]:
    return list_education()


@app.get("/title-templates")
def title_templates() -> list[dict]:
    return list_title_templates()


@app.post("/title-templates")
def create_title(payload: TitleTemplateCreate) -> dict:
    return create_title_template(payload)


@app.post("/payments/intent")
def payment_intent(payload: PaymentIntentRequest) -> dict:
    return create_payment_intent(payload)


@app.get("/summary/{question_id}")
def thread_summary(question_id: str) -> dict:
    for question in list_questions():
        if question["id"] == question_id:
            return {"question_id": question_id, "summary": question["ai_summary"]}
    return {"question_id": question_id, "summary": "No thread found."}


@app.get("/audit/logs")
def audit_logs(limit: int = 100) -> list[dict]:
    return read_audit(limit=limit)
