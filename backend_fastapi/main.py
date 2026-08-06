from __future__ import annotations

from collections import defaultdict, deque
from time import monotonic

from fastapi import FastAPI, File, Form, HTTPException, Request, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse

try:
    from .models import (
        AdCampaignCreate,
        AdCampaignUpdate,
        AppSettingsUpdate,
        AttachmentCreate,
        AuthRequest,
        AuthResponse,
        BlogArticleCreate,
        BlogArticleCommentCreate,
        BlogArticleLikeRequest,
        BlogArticleUpdate,
        CommunicationPreferencesUpdate,
        ContentShareReport,
        ContentShareRequest,
        DoctorInviteCreate,
        DoctorResponseInput,
        GrowthCampaignCreate,
        GrowthCampaignUpdate,
        GrowthContentDerivativeCreate,
        GrowthEventInput,
        GrowthIntegrationApprovalUpdate,
        GrowthIntegrationCreate,
        GrowthIntegrationOAuthStart,
        GrowthIntegrationSelectionUpdate,
        GrowthOpportunityCreate,
        GrowthPublishingApprovalUpdate,
        GrowthPublishingRequestCreate,
        NotificationSettingsUpdate,
        OtpRequestInput,
        OtpVerifyInput,
        PaymentIntentRequest,
        QuestionCreate,
        QuestionDeleteRequest,
        ResponseDeleteRequest,
        ThreadMessageInput,
        ThreadMessageModerationRequest,
        QuestionUpdateRequest,
        SectionTranslationRequest,
        SectionTranslationResponse,
        TitleTemplateCreate,
        TranslationRequest,
        TranslationResponse,
        UserDeleteRequest,
        UserProfileUpsertRequest,
        UnsubscribeRequest,
    )
    from .services import (
        add_response,
        create_ad_campaign,
        add_thread_message,
        authenticate,
        create_blog_article,
        add_blog_article_comment,
        create_attachment,
        delete_question,
        delete_responses,
        delete_user_account,
        invite_doctor,
        create_payment_intent,
        create_growth_campaign,
        create_growth_derivative,
        create_growth_integration,
        create_growth_opportunity,
        create_growth_publishing_request,
        create_question,
        complete_growth_integration_oauth,
        get_app_settings,
        get_notification_settings,
        growth_overview,
        ingest_growth_event,
        list_email_campaigns,
        list_growth_campaigns,
        list_growth_derivatives,
        list_growth_integration_catalog,
        list_growth_integrations,
        list_growth_opportunities,
        list_growth_publishing_requests,
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
        lookup_user_by_phone,
        moderate_thread_message,
        moderate_blog_article_comment,
        request_otp,
        resolve_report_pdf,
        revoke_attachment,
        translate_article_section,
        translate_text,
        share_content,
        unsubscribe_email,
        verify_otp,
        seed_if_needed,
        should_seed_demo_data,
        start_growth_integration_oauth,
        test_growth_integration_connection,
        update_ad_campaign,
        update_blog_article,
        update_growth_campaign,
        update_growth_integration_approval,
        update_growth_integration_selection,
        update_growth_publishing_request,
        like_blog_article,
        update_app_settings,
        update_communication_preferences,
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
        BlogArticleCommentCreate,
        BlogArticleLikeRequest,
        BlogArticleUpdate,
        CommunicationPreferencesUpdate,
        ContentShareReport,
        ContentShareRequest,
        DoctorInviteCreate,
        DoctorResponseInput,
        GrowthCampaignCreate,
        GrowthCampaignUpdate,
        GrowthContentDerivativeCreate,
        GrowthEventInput,
        GrowthIntegrationApprovalUpdate,
        GrowthIntegrationCreate,
        GrowthIntegrationOAuthStart,
        GrowthIntegrationSelectionUpdate,
        GrowthOpportunityCreate,
        GrowthPublishingApprovalUpdate,
        GrowthPublishingRequestCreate,
        NotificationSettingsUpdate,
        OtpRequestInput,
        OtpVerifyInput,
        PaymentIntentRequest,
        QuestionCreate,
        QuestionDeleteRequest,
        ResponseDeleteRequest,
        ThreadMessageInput,
        ThreadMessageModerationRequest,
        QuestionUpdateRequest,
        SectionTranslationRequest,
        SectionTranslationResponse,
        TitleTemplateCreate,
        TranslationRequest,
        TranslationResponse,
        UserDeleteRequest,
        UserProfileUpsertRequest,
        UnsubscribeRequest,
    )
    from services import (  # type: ignore
        add_response,
        create_ad_campaign,
        add_thread_message,
        authenticate,
        create_blog_article,
        add_blog_article_comment,
        create_attachment,
        delete_question,
        delete_responses,
        delete_user_account,
        invite_doctor,
        create_payment_intent,
        create_growth_campaign,
        create_growth_derivative,
        create_growth_integration,
        create_growth_opportunity,
        create_growth_publishing_request,
        create_question,
        complete_growth_integration_oauth,
        get_app_settings,
        get_notification_settings,
        growth_overview,
        ingest_growth_event,
        list_email_campaigns,
        list_growth_campaigns,
        list_growth_derivatives,
        list_growth_integration_catalog,
        list_growth_integrations,
        list_growth_opportunities,
        list_growth_publishing_requests,
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
        lookup_user_by_phone,
        moderate_thread_message,
        moderate_blog_article_comment,
        request_otp,
        resolve_report_pdf,
        revoke_attachment,
        translate_article_section,
        translate_text,
        share_content,
        unsubscribe_email,
        verify_otp,
        seed_if_needed,
        should_seed_demo_data,
        start_growth_integration_oauth,
        test_growth_integration_connection,
        update_ad_campaign,
        update_blog_article,
        update_growth_campaign,
        update_growth_integration_approval,
        update_growth_integration_selection,
        update_growth_publishing_request,
        like_blog_article,
        update_app_settings,
        update_communication_preferences,
        update_notification_settings,
        update_question,
        upsert_user_profile,
        upload_attachment_file,
    )
    from storage import read_audit  # type: ignore


app = FastAPI(title="MedicoHub Backend", version="1.3.10")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

if should_seed_demo_data():
    seed_if_needed()


_translation_hits: defaultdict[str, deque[float]] = defaultdict(deque)


def _check_translation_rate_limit(request: Request) -> None:
    client = request.client.host if request.client else "unknown"
    now = monotonic()
    hits = _translation_hits[client]
    while hits and now - hits[0] > 60:
        hits.popleft()
    if len(hits) >= 45:
        raise HTTPException(
            status_code=429,
            detail="Too many translation requests. Please try again shortly.",
        )
    hits.append(now)


@app.get("/")
def root() -> dict:
    return {
        "status": "ok",
        "service": "MedicoHub Backend",
        "disclaimer": "Educational only. No diagnosis, prescriptions, or emergency handling.",
    }


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "service": "MedicoHub Backend"}


@app.post("/api/translate", response_model=TranslationResponse)
def translate(payload: TranslationRequest, request: Request) -> TranslationResponse:
    _check_translation_rate_limit(request)
    return translate_text(payload)


@app.post("/api/translate-section", response_model=SectionTranslationResponse)
def translate_section(payload: SectionTranslationRequest, request: Request) -> SectionTranslationResponse:
    _check_translation_rate_limit(request)
    return translate_article_section(payload)


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


@app.get("/api/admin/users")
def admin_users() -> list[dict]:
    return list_users()


@app.post("/api/admin/share-content", response_model=ContentShareReport)
def admin_share_content(payload: ContentShareRequest) -> ContentShareReport:
    return share_content(payload)


@app.get("/api/admin/email-campaigns")
def admin_email_campaigns() -> list[dict]:
    return list_email_campaigns()


@app.get("/api/admin/growth/overview")
def admin_growth_overview(actor_id: str) -> dict:
    return growth_overview(actor_id)


@app.get("/api/admin/growth/campaigns")
def admin_growth_campaigns(actor_id: str) -> list[dict]:
    return list_growth_campaigns(actor_id)


@app.post("/api/admin/growth/campaigns")
def admin_create_growth_campaign(payload: GrowthCampaignCreate) -> dict:
    return create_growth_campaign(payload)


@app.patch("/api/admin/growth/campaigns/{campaign_id}")
def admin_update_growth_campaign(campaign_id: str, payload: GrowthCampaignUpdate) -> dict:
    return update_growth_campaign(campaign_id, payload)


@app.get("/api/admin/growth/opportunities")
def admin_growth_opportunities(actor_id: str) -> list[dict]:
    return list_growth_opportunities(actor_id)


@app.post("/api/admin/growth/opportunities")
def admin_create_growth_opportunity(payload: GrowthOpportunityCreate) -> dict:
    return create_growth_opportunity(payload)


@app.get("/api/admin/growth/content-derivatives")
def admin_growth_content_derivatives(actor_id: str, source_article_id: str | None = None) -> list[dict]:
    return list_growth_derivatives(actor_id, source_article_id)


@app.post("/api/admin/growth/content-derivatives")
def admin_create_growth_derivative(payload: GrowthContentDerivativeCreate) -> dict:
    return create_growth_derivative(payload)


@app.get("/api/admin/growth/integrations/catalog")
def admin_growth_integration_catalog(actor_id: str) -> list[dict]:
    return list_growth_integration_catalog(actor_id)


@app.get("/api/admin/growth/integrations")
def admin_growth_integrations(actor_id: str) -> list[dict]:
    return list_growth_integrations(actor_id)


@app.post("/api/admin/growth/integrations")
def admin_create_growth_integration(payload: GrowthIntegrationCreate) -> dict:
    return create_growth_integration(payload)


@app.post("/api/admin/growth/integrations/{integration_id}/oauth/start")
def admin_start_growth_integration_oauth(integration_id: str, payload: GrowthIntegrationOAuthStart) -> dict:
    return start_growth_integration_oauth(integration_id, payload)


@app.patch("/api/admin/growth/integrations/{integration_id}/approval")
def admin_update_growth_integration_approval(integration_id: str, payload: GrowthIntegrationApprovalUpdate) -> dict:
    return update_growth_integration_approval(integration_id, payload)


@app.patch("/api/admin/growth/integrations/{integration_id}/selection")
def admin_update_growth_integration_selection(integration_id: str, payload: GrowthIntegrationSelectionUpdate) -> dict:
    return update_growth_integration_selection(integration_id, payload)


@app.post("/api/admin/growth/integrations/{integration_id}/test")
def admin_test_growth_integration_connection(integration_id: str, payload: GrowthIntegrationOAuthStart) -> dict:
    return test_growth_integration_connection(integration_id, payload.actor_id)


@app.get("/api/integrations/{provider}/callback")
@app.get("/api/growth/oauth/{provider}/callback")
def growth_integration_oauth_callback(
    provider: str,
    state: str | None = None,
    code: str | None = None,
    error: str | None = None,
    error_description: str | None = None,
) -> HTMLResponse:
    try:
        result = complete_growth_integration_oauth(provider, state, code, error or error_description)
        if result.get("status") == "failed":
            title = "Social account connection failed"
            detail = f"{provider} was not connected: {result.get('detail', 'OAuth failed')}."
            status_code = 400
        else:
            title = "Social account connected"
            detail = (
                f"{provider} is connected. Returning to MedicoHub Growth Studio; "
                "refresh Integrations, then select or approve the official destination."
            )
            status_code = 200
    except HTTPException as exc:
        title = "Social account connection failed"
        detail = str(exc.detail)
        status_code = exc.status_code
        result = {"status": "failed", "provider": provider}
    html = f"""
    <!doctype html>
    <html lang=\"en\">
      <head>
        <meta charset=\"utf-8\">
        <title>{title}</title>
        {"<meta http-equiv=\"refresh\" content=\"3; url=https://mediconverse.web.app\">" if status_code < 400 else ""}
      </head>
      <body style=\"font-family: system-ui, sans-serif; margin: 40px; max-width: 760px;\">
        <h1>{title}</h1>
        <p>{detail}</p>
        {"<p>You will be redirected automatically in a few seconds.</p>" if status_code < 400 else ""}
        <p><a href=\"https://mediconverse.web.app\">Open MedicoHub Connect</a></p>
        <pre style=\"white-space: pre-wrap; background: #f7f7f7; padding: 12px;\">{result}</pre>
      </body>
    </html>
    """
    return HTMLResponse(content=html, status_code=status_code)


@app.get("/api/admin/growth/publishing-requests")
def admin_growth_publishing_requests(actor_id: str) -> list[dict]:
    return list_growth_publishing_requests(actor_id)


@app.post("/api/admin/growth/publishing-requests")
def admin_create_growth_publishing_request(payload: GrowthPublishingRequestCreate) -> dict:
    return create_growth_publishing_request(payload)


@app.patch("/api/admin/growth/publishing-requests/{publish_id}/approval")
def admin_update_growth_publishing_request(publish_id: str, payload: GrowthPublishingApprovalUpdate) -> dict:
    return update_growth_publishing_request(publish_id, payload)


@app.post("/api/growth/events")
def growth_event(payload: GrowthEventInput) -> dict:
    return ingest_growth_event(payload)


@app.get("/doctors")
def doctors() -> list[dict]:
    return list_doctors()


@app.post("/doctors/invite")
def add_doctor(payload: DoctorInviteCreate) -> dict:
    return invite_doctor(payload)


@app.get("/users/lookup/by-email")
def lookup_user(email: str) -> dict | None:
    return lookup_user_by_email(email)


@app.get("/users/lookup/by-phone")
def lookup_user_phone(
    phone_number: str | None = None,
    phone_country_code: str | None = None,
    phone_national_number: str | None = None,
) -> dict | None:
    return lookup_user_by_phone(phone_number, phone_country_code, phone_national_number)


@app.get("/users/{user_id}")
def get_user(user_id: str) -> dict:
    return get_user_profile(user_id)


@app.post("/users/profile")
def upsert_user(payload: UserProfileUpsertRequest) -> dict:
    return upsert_user_profile(payload)


@app.post("/users/{user_id}/communication-preferences")
def save_communication_preferences(user_id: str, payload: CommunicationPreferencesUpdate) -> dict:
    return update_communication_preferences(user_id, payload)


@app.post("/api/unsubscribe")
def unsubscribe(payload: UnsubscribeRequest) -> dict:
    return unsubscribe_email(payload)


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


@app.delete("/questions/{question_id}/responses")
def remove_responses(question_id: str, payload: ResponseDeleteRequest) -> dict:
    return delete_responses(question_id, payload)


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


@app.patch("/blog/articles/{article_id}")
def patch_blog_article(article_id: str, payload: BlogArticleUpdate) -> dict:
    return update_blog_article(article_id, payload)


@app.post("/blog/articles/{article_id}/comments")
def post_blog_article_comment(article_id: str, payload: BlogArticleCommentCreate) -> dict:
    return add_blog_article_comment(article_id, payload)


@app.patch("/blog/articles/{article_id}/comments/{comment_id}")
def patch_blog_article_comment(
    article_id: str,
    comment_id: str,
    payload: ThreadMessageModerationRequest,
) -> dict:
    return moderate_blog_article_comment(article_id, comment_id, payload)


@app.post("/blog/articles/{article_id}/likes")
def post_blog_article_like(article_id: str, payload: BlogArticleLikeRequest) -> dict:
    return like_blog_article(article_id, payload)


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


@app.get("/api/admin/translation-usage")
def translation_usage(limit: int = 1000) -> dict:
    events = [
        event
        for event in read_audit(limit=limit)
        if event.get("entity_type") == "article_translation"
    ]
    total_characters = 0
    languages: dict[str, int] = {}
    providers: dict[str, int] = {}
    section_calls: dict[str, int] = {}
    for event in events:
        payload = event.get("payload") or {}
        total_characters += int(payload.get("characterCount") or 0)
        pair = f"{payload.get('sourceLang', '')}->{payload.get('targetLang', '')}"
        languages[pair] = languages.get(pair, 0) + 1
        provider = payload.get("provider") or "unknown"
        providers[provider] = providers.get(provider, 0) + 1
        section_id = payload.get("sectionId") or "unknown"
        section_calls[section_id] = section_calls.get(section_id, 0) + 1
    return {
        "providerCalls": len(events),
        "charactersTranslated": total_characters,
        "languagePairs": languages,
        "providers": providers,
        "sections": section_calls,
        "note": "Provider calls are counted from audit events emitted only after Azure generates a new translation. Server and local cache avoidance is reported in the reader UI.",
    }
