# Growth Studio Deployment and Rollback

## Backup

Checkpoint created before implementation:

`backups/growth-studio-checkpoint-20260805-073958`

It contains Git status, HEAD, working-tree diff, and a local database copy where available.

## Deploy

Backend:

1. Run backend verification.
2. Build/push Fly image using existing script: `scripts/deploy_backend_fly_image.ps1`.
3. Verify `https://medicohub-backend.fly.dev/health`.

Frontend:

1. Run `flutter pub get`.
2. Run `flutter analyze`.
3. Run `flutter build web --release --dart-define=MEDICOHUB_API_BASE_URL=https://medicohub-backend.fly.dev`.
4. Deploy with `firebase deploy --only hosting --project mediconverse`.
5. Verify `https://mediconverse.web.app/`.

## Rollback

- Revert the Growth Studio commit or apply the checkpoint diff in reverse.
- Restore `backend_fastapi/data/db.json` from the checkpoint only for local development rollback.
- For production Firestore, disable new Growth Studio navigation first, then archive or ignore newly created `growth_*` collections after export.
