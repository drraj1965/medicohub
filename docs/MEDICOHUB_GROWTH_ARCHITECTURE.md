# MedicoHub Growth Architecture

## Implemented Foundation

Growth Studio is owned by MedicoHub Connect.

- Canonical backend records: campaigns, opportunities, events, content derivatives, referrals, experiments, integrations, consent preferences.
- Admin UI: `MedicoHub Growth Studio` drawer entry for admins and growth roles.
- First-party event taxonomy endpoint: `/api/growth/events`.
- Admin endpoints: `/api/admin/growth/overview`, `/campaigns`, `/opportunities`, `/content-derivatives`.
- Content lineage: promotional derivatives reference source article ID, article version, review status, and review date.
- Source update control: when a source article changes, unsent derivatives are marked `review_required`.

## Service Boundaries

External tools should connect through adapters:

- `SEOProvider`
- `SocialPublishingProvider`
- `ProductAnalyticsProvider`
- `NewsletterProvider`
- `WorkflowProvider`
- `FeedbackProvider`
- `LinkTrackingProvider`
- `NotificationProvider`
- `AIContentProvider`

MedicoHub remains authoritative for campaign records, content approval, medical review, consent, attribution, referrals, and audit logs.

## Data Collections

Implemented storage buckets:

- `growth_campaigns`
- `growth_opportunities`
- `growth_events`
- `growth_event_daily_aggregates`
- `growth_content_derivatives`
- `growth_integrations`
- `growth_consent_preferences`
- `growth_referrals`
- `growth_experiments`

Future Firestore production indexes should cover `created_at`, `campaign_id + timestamp`, `event_name + timestamp`, `source_article_id + approval_status`, and `status + updated_at`.
