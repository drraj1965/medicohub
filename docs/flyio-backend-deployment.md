# Fly.io Backend Deployment

Deploy the always-on FastAPI backend from `backend_fastapi/`.

## One-time setup

```powershell
cd backend_fastapi
fly auth login
fly apps create medicohub-backend
fly secrets set GOOGLE_SERVICE_ACCOUNT_JSON="$(Get-Content ..\secrets\medicohub-firebase-admin.json -Raw)"
```

Set only the email or Twilio secrets that are actually in use:

```powershell
fly secrets set SENDGRID_API_KEY="..." SENDGRID_SENDER_EMAIL="..."
fly secrets set SMTP_HOST="..." SMTP_PORT="..." SMTP_USERNAME="..." SMTP_PASSWORD="..." SMTP_SENDER_EMAIL="..." ENABLE_SMTP_TLS="true"
fly secrets set TWILIO_ACCOUNT_SID="..." TWILIO_AUTH_TOKEN="..." TWILIO_FROM_PHONE="..." TWILIO_WHATSAPP_NUMBER="..."
```

## Deploy

```powershell
cd backend_fastapi
fly deploy
fly status
fly logs
```

## Verify

```powershell
Invoke-RestMethod https://medicohub-backend.fly.dev/
```

The checked-in `fly.toml` keeps one small machine running so login does not wait for a sleeping backend to wake.
