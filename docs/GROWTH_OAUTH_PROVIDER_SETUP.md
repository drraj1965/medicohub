# MedicoHub Growth OAuth Provider Setup

This is the safe setup path for Growth Studio social integrations.

Do not paste provider secrets into chat, tickets, screenshots, docs, or Git. Use the local PowerShell importer:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\configure_growth_oauth_secrets.ps1 -Provider recommended
```

The script prompts securely, pipes values to `fly secrets import`, and does not write secret values to disk.

## Callback URLs

Use these redirect/callback URLs in the provider developer consoles:

```text
https://medicohub-backend.fly.dev/api/growth/oauth/linkedin/callback
https://medicohub-backend.fly.dev/api/growth/oauth/meta/callback
https://medicohub-backend.fly.dev/api/growth/oauth/youtube/callback
https://medicohub-backend.fly.dev/api/growth/oauth/tiktok/callback
https://medicohub-backend.fly.dev/api/growth/oauth/google_business/callback
https://medicohub-backend.fly.dev/api/growth/oauth/reddit/callback
https://medicohub-backend.fly.dev/api/growth/oauth/x/callback
https://medicohub-backend.fly.dev/api/growth/oauth/threads/callback
```

## Recommended First Providers

Start with these because they match MedicoHub's likely growth motion:

- LinkedIn: professional credibility, doctor education, referrals.
- Meta: Facebook Page and Instagram Business publishing after app review.
- Google: YouTube upload and Google Business Profile later.

## Phase 1 Ownership Model

MedicoHub Connect connects only official organisation-owned social accounts in Phase 1:

- one official Facebook Page plus the linked Instagram professional account through one Meta OAuth connection;
- one LinkedIn account or organisation Page;
- one YouTube channel.

Do not connect every doctor's personal social accounts during Phase 1. The data model keeps `owner_type=organisation` and `owner_id=medicohub` so later organisations, clinics, or doctors can be added without changing the public workflow.

Only `superAdmin`, `socialAccounts.manage`, or the configured principal administrator may connect, reconnect, disconnect, test, or change official social destinations. Other Growth Studio admins may draft content and request publishing approval.

If the principal administrator is not yet stored as `superAdmin`, configure one of these Fly secrets:

```powershell
fly secrets set MEDICOHUB_PRINCIPAL_ADMIN_USER_ID=<firebase-user-id> --app medicohub-backend
fly secrets set MEDICOHUB_PRINCIPAL_ADMIN_EMAIL=<admin-email> --app medicohub-backend
```

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\configure_growth_oauth_secrets.ps1 -Provider recommended
```

## Secret Names

The backend looks for these Fly environment secrets:

```text
LINKEDIN_CLIENT_ID
LINKEDIN_CLIENT_SECRET
META_CLIENT_ID
META_CLIENT_SECRET
GOOGLE_OAUTH_CLIENT_ID
GOOGLE_OAUTH_CLIENT_SECRET
TIKTOK_CLIENT_KEY
TIKTOK_CLIENT_SECRET
REDDIT_CLIENT_ID
REDDIT_CLIENT_SECRET
X_CLIENT_ID
X_CLIENT_SECRET
THREADS_CLIENT_ID
THREADS_CLIENT_SECRET
```

## Provider Console Checklist

LinkedIn:

- Create or open an app in the LinkedIn Developer Portal.
- Open the app Auth tab.
- Add `https://medicohub-backend.fly.dev/api/growth/oauth/linkedin/callback` as an authorized redirect URL.
- Copy the Client ID and Client Secret.
- Request the products/scopes needed for posting, especially member social posting.

Meta for Facebook and Instagram:

- Create or open a Meta app.
- Add Facebook Login / Instagram Graph API capabilities as needed.
- Add this valid OAuth redirect URI:
  - `https://medicohub-backend.fly.dev/api/growth/oauth/meta/callback`
- Copy the App ID and App Secret.
- For Instagram publishing, use an Instagram Business or Creator account connected to the selected Facebook Page.
- Expect app review for publish permissions.

Google for YouTube and Google Business:

- Create or open a Google Cloud project.
- Configure the OAuth consent screen.
- Enable YouTube Data API v3 for YouTube upload work.
- Create an OAuth Client ID for a web application.
- Add these authorized redirect URIs:
  - `https://medicohub-backend.fly.dev/api/growth/oauth/youtube/callback`
  - `https://medicohub-backend.fly.dev/api/growth/oauth/google_business/callback`
- Copy the Client ID and Client Secret.

TikTok:

- Create or open an app in TikTok for Developers.
- Configure Login Kit / content posting access.
- Add `https://medicohub-backend.fly.dev/api/growth/oauth/tiktok/callback` as the redirect URI.
- Copy the Client Key and Client Secret.
- Treat TikTok as later-phase because medical content and publishing review may be stricter.

Reddit:

- Create an OAuth app in Reddit preferences/developer settings.
- Use a web app style configuration.
- Add `https://medicohub-backend.fly.dev/api/growth/oauth/reddit/callback` as the redirect URI.
- Copy the Client ID and Client Secret.
- Use cautiously for subreddit-specific education and AMA-style activity.

X / Twitter:

- Create or open an X Developer app.
- Configure OAuth 2.0 user authentication.
- Add `https://medicohub-backend.fly.dev/api/growth/oauth/x/callback` as the callback URI.
- Copy the Client ID and Client Secret.
- Confirm your access tier permits posting.

Threads:

- Create or open the Meta app with Threads API access.
- Add `https://medicohub-backend.fly.dev/api/growth/oauth/threads/callback` as the redirect URI.
- Copy the Client ID and Client Secret.
- Expect Meta review before production publishing.

## After Import

Verify names only:

```powershell
fly secrets list --app medicohub-backend
```

Then open Growth Studio -> Integrations and refresh. OAuth-capable channels should move from `OAuth app needed` to `OAuth configured`.
