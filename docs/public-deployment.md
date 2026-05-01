# Public Deployment Plan

This document is the practical bridge from local/USB testing to true standalone Android and later iOS testing.

## Recommended public backend target

Use Render for the first public backend deployment.

Why this fits MedicoHub now:

- FastAPI deploys cleanly as a single Python web service.
- MedicoHub already keeps long-term state in Firebase / Firestore and Firebase Storage, so it does not need a hosted SQL database for MVP deployment.
- The repo now includes a `render.yaml` Blueprint that points Render at the backend automatically.

Reference:

- `render.yaml`
- `backend_fastapi/requirements.txt`

## What Render needs

### Repo connection

Connect the GitHub repository:

- `drraj1965/medicohub`

### Service creation

Render can create the service from `render.yaml`.

The Blueprint currently defines:

- service name: `medicohub-backend`
- runtime: `python`
- root directory: `backend_fastapi`
- build command: `pip install -r requirements.txt`
- start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
- health check path: `/`

### Environment variables

Non-secret variables are already defined in `render.yaml`.

Secrets must still be added in the Render dashboard:

- `TWILIO_ACCOUNT_SID`
- `TWILIO_AUTH_TOKEN`
- `TWILIO_WHATSAPP_NUMBER`
- any SMTP or SendGrid variables you decide to use later

### Secret file

Add the Firebase admin JSON as a Render secret file:

- filename: `medicohub-firebase-admin.json`
- runtime path: `/etc/secrets/medicohub-firebase-admin.json`

This matches the `GOOGLE_SERVICE_ACCOUNT_JSON` path in `render.yaml`.

Official references:

- Render FastAPI deployment: https://render.com/docs/deploy-fastapi
- Render Blueprint spec: https://render.com/docs/blueprint-spec
- Render environment variables and secret files: https://render.com/docs/configure-environment-variables

## After the backend is live

Assume Render gives you a URL such as:

- `https://medicohub-backend.onrender.com`

Verify:

- `GET /`
- `GET /questions`
- `GET /education/library`

## Rebuild Android against the public API

Once the backend URL is confirmed, rebuild the Android APK:

```powershell
Set-Location "C:\Users\drpha\Documents\Aster\doctor_forum_app"
powershell -ExecutionPolicy Bypass -File .\scripts\build_android_apk.ps1 -Release -ApiBaseUrl "https://YOUR_RENDER_URL" -ArtifactLabel public-beta
```

This produces an artifact in:

- `artifacts/`

At that point, the Android app no longer depends on:

- your laptop
- `adb reverse`
- local Wi-Fi

## iOS preparation path

The clean order for iOS is:

1. Enroll in the Apple Developer Program.
2. Regenerate FlutterFire config including iOS on a Mac.
3. Add `GoogleService-Info.plist` locally.
4. Build the iOS app against the same public backend URL used by Android.
5. Test through Xcode / TestFlight before App Store submission.

Official references:

- Apple Developer Program overview: https://developer.apple.com/programs/
- Enrollment support: https://developer.apple.com/support/enrollment/

As of Apple's current official enrollment docs, the Apple Developer Program fee is `99 USD` per membership year, with regional pricing variations shown during enrollment.

## Ads / monetization path

Do not turn on ads before the public backend is stable and the mobile auth / question flow is stable.

Recommended first monetization layer:

- Google AdMob banner ads only in low-risk locations such as Education or Settings

Do not place ads:

- inside critical consent flows
- during question submission
- adjacent to doctor advice in a way that can look like sponsored medical guidance

AdMob integration references:

- Flutter quick start: https://developers.google.com/admob/flutter/quick-start
- Test ads guidance: https://developers.google.com/admob/flutter/test-ads

## Operational warning

MedicoHub still writes audit events to a local JSONL file in addition to Firebase-backed application data.

On an ephemeral public platform, local audit files should be treated as MVP-level logs, not the final compliance-grade immutable audit store. A later hardening step should mirror audit events into a durable remote store such as Firestore or another append-only logging destination.
