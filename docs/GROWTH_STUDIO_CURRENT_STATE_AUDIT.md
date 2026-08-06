# MedicoHub Growth Studio Current State Audit

Date: 2026-08-05

## Live Repository Confirmation

- Active worktree: `D:\Rajshekher-Projects\Aster\doctor_forum_app`.
- `C:\Users\drpha\Documents\Aster\doctor_forum_app` resolves to the same Git toplevel.
- Git remote: `https://github.com/drraj1965/medicohub.git`.
- Firebase Hosting project: `mediconverse`, public URL references: `https://mediconverse.web.app/`.
- Fly backend app: `medicohub-backend`, public API default: `https://medicohub-backend.fly.dev`.
- Prior `M:\doctor_forum_app` VHDX mount is not currently present.

## Frameworks

- Frontend: Flutter app with Android, iOS, Windows, and Flutter Web/PWA targets.
- Backend: FastAPI with Pydantic models, Firebase Admin/Firestore support, Firebase Storage/Google Drive/local storage provider abstractions, and local JSON storage for development.
- Public web: Flutter web shell under `frontend_flutter/web`, deployed by root `firebase.json`.

## Existing Capabilities Found

- Authentication: local demo login, OTP request/verify paths, Firebase Auth service on frontend.
- Roles: patient, doctor, admin; this change extends support for growth roles without exposing signup controls for those roles.
- Content: doctor/admin article publishing, rich article sections, YouTube fields, translations, comments, likes, email sharing.
- Questions: private/public Q&A, doctor responses, thread messages, moderation, attachments with expiry.
- Notifications: outbox, WhatsApp activation configuration, email preference controls.
- Saved/local health tools: vestibular exercise module with local progress sharing.
- Admin: data console, user listing, doctor invites, app settings, ad campaigns, audit log.
- Privacy guardrails: educational disclaimer, no diagnosis/prescription/emergency handling, storage rules blocking direct client file access.

## Baseline Verification

- Backup checkpoint created: `backups/growth-studio-checkpoint-20260805-073958`.
- Global Python `pytest` failed because FastAPI was not installed in the global interpreter.
- Backend virtualenv exists but does not currently include `pytest`.
- Flutter is available: Flutter 3.41.7, Dart 3.11.5.
- Initial `flutter pub get; flutter analyze` exceeded the first 180 second command window and was rerun after implementation.

## Risk Notes

- There is no checked-in Firestore rules file; only `storage.rules` exists.
- Root `firebase.json` previously set long immutable caching for JS/CSS/assets. Confirm cache behavior before production redeploy.
- Public article content is currently inside a Flutter client app, so search crawlers may not see article bodies without prerender/SSR/exported static pages.
- Backend admin endpoints currently use `actor_id` payload checks, not signed Firebase ID token verification on every request. Production hardening should bind these checks to authenticated tokens.
