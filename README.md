# MedicoHub

MedicoHub is a compliance-first Doctor-Patient forum and education platform MVP. It is designed for educational discussions, structured Q&A, and paid second-opinion conversations without diagnosis, prescriptions, or emergency handling.

Current project location: `C:\Users\drpha\Documents\Aster\doctor_forum_app`

## Project layout

```text
doctor_forum_app/
├── backend_fastapi/
├── docs/
├── frontend_flutter/
├── scripts/
├── .env.example
├── README.md
└── update.json
```

## Key safeguards

- Mandatory consent gate before app usage
- Educational-only doctor responses with structured template
- Audit logging with append-only event history
- File expiry metadata with revoke flow
- No Google Sheets for PHI and no hardcoded secrets

## Local setup

1. Copy `.env.example` to `.env` and fill the provider keys you want to enable.
2. Generate your local Firebase config files:
   - Run `flutterfire configure --project YOUR_PROJECT_ID --platforms=android,web,windows`
   - Keep the generated `frontend_flutter/lib/firebase_options.dart` local only.
   - Download or regenerate `frontend_flutter/android/app/google-services.json` locally for Android builds.
   - Use the checked-in template files only as examples:
     - `frontend_flutter/lib/firebase_options.example.dart`
     - `frontend_flutter/android/app/google-services.example.json`
3. Run `powershell -ExecutionPolicy Bypass -File .\scripts\setup_backend.ps1`
4. Run `powershell -ExecutionPolicy Bypass -File .\scripts\run_all.ps1`

`run_all.ps1` starts the FastAPI backend first and then launches the Flutter app. The frontend bootstrap script creates any missing Flutter platform folders, runs `flutter pub get`, and launches the requested device target.

## Default local endpoints

- Backend health: `http://127.0.0.1:8012/`
- API docs: `http://127.0.0.1:8012/docs`

## Firebase config safety

- Real Firebase config files are intentionally gitignored.
- Do not commit:
  - `frontend_flutter/lib/firebase_options.dart`
  - `frontend_flutter/android/app/google-services.json`
  - `frontend_flutter/ios/Runner/GoogleService-Info.plist`
- If GitHub flags an exposed Firebase or Google API key, remove the file from git history and then restrict or rotate the key in Google Cloud Console.

## Test accounts

- Patient: `patient@test.com`
- Doctor: `doctor@test.com`

Password for both dummy accounts: `Passw0rd!`

## Reuse notes

- Voice input: wire into your DictoApp keyboard/native speech flow via the Flutter ask-question form and doctor response composer.
- PDF ingestion: plug your NeuroLit parsing logic into `backend_fastapi/services.py` where the upload and summary pipeline is isolated.
- Session-style persistence: local JSON stores and backup scripts mirror the pattern you used in NeuroLit so you can migrate to Firestore later without rewriting the UI flows.

## What is included now

- Modular FastAPI backend with `/auth`, `/questions`, `/upload`, `/doctor/respond`, `/education`, `/summary`, and `/audit`
- Firestore repository and Firebase Storage adapter that activate when `ENABLE_FIRESTORE=true` and `ENABLE_FIREBASE_STORAGE=true`
  The current backend bucket is `mediconverse-medicohub-630548785812`.
- PDF ingestion service with PMC link extraction and preview text extraction for uploaded PDFs
- Compact DictoApp-based voice integration for keyboard mic guidance, native speech bridge hooks, and audio-note capture
- Flutter single-dashboard shell with tabs, consent gate, ask flow, education library, and settings
- Payment provider abstraction and expiry-aware upload metadata
- Update check scaffolding based on GitHub Releases metadata
- Backup and rollback PowerShell scripts
- Architecture, schema, wireframes, 14-day plan, and UAE monetization notes in `docs/architecture.md`

## Next integration steps

- Attach real Firebase Auth and Firestore adapters
- Use Firebase Storage bucket-backed uploads for expiring file delivery
- Connect Stripe or Razorpay checkout
- Add Whisper or native speech capture once your existing pipeline files are dropped into the workspace
