# MedicoHub Connect Store Release Candidate 1.3.26+34

Date: 2026-08-06

## Release Intent

Upgrade release for the already deployed MedicoHub Connect app.

Primary upgrade content:

- MedicoHub Growth Studio and Growth Command Center.
- Admin-only official social account integrations.
- Manual export, WhatsApp, newsletter/email, LinkedIn, Meta/Facebook + Instagram, YouTube, Google Business, and X/Twitter connection flow.
- Safer admin profile restoration for allowlisted MedicoHub administrators.
- OAuth token exchange, account discovery, encrypted server-side token references, audit logging, and approval-gated publishing workflow.

## Version

- Flutter app version: `1.3.26+34`
- Android versionCode: `34`
- iOS build number: `34`
- iOS marketing version: `1.3.26`
- Android applicationId: `com.aster.medichub`
- iOS bundle ID: `com.aster.medichub`

## Live Services

- Web/PWA: `https://mediconverse.web.app/`
- Backend: `https://medicohub-backend.fly.dev`
- Privacy: `https://mediconverse.web.app/privacy.html`
- Terms: `https://mediconverse.web.app/terms.html`
- Disclaimer: `https://mediconverse.web.app/disclaimer.html`
- Account deletion: `https://mediconverse.web.app/delete-account.html`
- Support: `https://mediconverse.web.app/support.html`

## QA Evidence

- Backend health endpoint returned `status: ok`.
- Public web, privacy, terms, disclaimer, delete-account, and support URLs returned HTTP `200`.
- Flutter `pub get` completed.
- Flutter `analyze` completed with no issues.
- Backend admin profile regression test passed.
- Growth OAuth adapter smoke test passed.
- Live Growth integration catalog for the principal admin shows:
  - LinkedIn connected.
  - Meta connected.
  - YouTube connected.
  - Google Business connected.
  - X/Twitter connected.
  - Manual export, WhatsApp, and newsletter/email ready.
  - `can_manage_social_accounts: true` for the principal admin.
- Firebase Hosting deployed the upgraded web/PWA release to `https://mediconverse.web.app`.
- Web build contains production backend URL `https://medicohub-backend.fly.dev`.
- Android release AAB was built and signature verification reported `jar verified`.

## Android / Google Play Internal Testing

Upload this AAB in Google Play Console as an internal testing upgrade:

```text
D:\Rajshekher-Projects\Aster\doctor_forum_app\frontend_flutter\build\app\outputs\bundle\release\app-release.aab
```

Recommended track:

1. Google Play Console.
2. Select the existing MedicoHub Connect app.
3. Testing > Internal testing.
4. Create new release.
5. Upload `app-release.aab`.
6. Add release notes from this file.
7. Confirm Data Safety remains accurate.
8. Confirm Health Apps declaration remains accurate.
9. Review and roll out to internal testers.

Suggested release notes:

```text
Upgrade release with MedicoHub Growth Studio, admin-only official social account integrations, safer profile restoration for principal admins, and approval-gated social publishing workflow. Also includes production backend and PWA stability updates.
```

## Microsoft Store PWA Package

Use the already upgraded live PWA URL:

```text
https://mediconverse.web.app/
```

PWABuilder flow:

1. Open `https://www.pwabuilder.com/`.
2. Enter `https://mediconverse.web.app/`.
3. Confirm manifest, service worker, HTTPS, icons, and screenshots are detected.
4. Generate the Windows package.
5. Download the package.
6. Upload it to the existing MedicoHub Connect app submission in Microsoft Partner Center.

Microsoft listing URLs:

- Privacy: `https://mediconverse.web.app/privacy.html`
- Support: `https://mediconverse.web.app/support.html`
- Website: `https://mediconverse.web.app/`

Reviewer note:

```text
MedicoHub Connect is an educational doctor-patient communication app. It is not for emergencies and does not provide diagnosis or prescriptions. This is an upgrade release. Please use the supplied demo login to review Education, Questions, Ask Question, and Settings. Admin-only Growth Studio features are restricted to authorized MedicoHub administrators.
```

## Apple / TestFlight Preparation

iOS archive must be built on macOS with Xcode and Apple Developer signing configured.

On the Mac:

```bash
cd /path/to/doctor_forum_app
BUILD_NAME=1.3.26 BUILD_NUMBER=34 bash scripts/store_release_ios_mac.sh
```

If command-line upload is unavailable:

```text
Open frontend_flutter/ios/Runner.xcworkspace in Xcode.
Product > Archive > Distribute App > App Store Connect.
```

Before TestFlight submission:

- Confirm `ios/Runner/GoogleService-Info.plist` exists locally.
- Confirm signing team and bundle ID match the existing App Store Connect app.
- Confirm App Privacy answers match the current behavior.
- Include privacy/support URLs and reviewer notes.
- Use TestFlight first before App Store review.

## Store Review Guardrails

- Do not describe the app as emergency care, triage, diagnosis, prescription, or a replacement for face-to-face care.
- Keep Growth Studio described as an admin operations feature, not as a patient-facing medical advice feature.
- Confirm ads/sponsored content, if enabled, are clearly labeled and not shown inside private medical-question content.
- Demo/test data must not contain real patient information.
