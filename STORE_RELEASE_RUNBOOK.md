# MedicoHub Store Release Runbook

## Android / Google Play

Run from PowerShell:

```powershell
cd "D:\Rajshekher-Projects\Aster\doctor_forum_app"
.\scripts\store_release_android.ps1
```

The Play Console upload file is:

```text
frontend_flutter\build\app\outputs\bundle\release\app-release.aab
```

To also install the release APK on a connected Android device:

```powershell
.\scripts\store_release_android.ps1 -InstallOnDevice
```

Before uploading, confirm:

- Backend health endpoint returns `status: ok`.
- Android signing file exists locally: `frontend_flutter\android\key.properties`.
- Firebase Android config exists locally: `frontend_flutter\android\app\google-services.json`.
- No secrets are staged in Git.
- Release version in `frontend_flutter\pubspec.yaml` is correct.

Upload the `.aab` in Google Play Console using an internal test release first.

## Backend

Run from PowerShell:

```powershell
cd "D:\Rajshekher-Projects\Aster\doctor_forum_app"
.\scripts\deploy_backend_fly_image.ps1 -Tag store-release-1
```

This builds locally, pushes to Fly Registry, deploys the image, and checks the live health endpoint.

## iOS / Apple App Store Connect

iOS submission requires macOS with Xcode and Apple Developer signing configured.

Copy or pull this repository on the Mac, then run:

```bash
cd /path/to/doctor_forum_app
bash scripts/store_release_ios_mac.sh
```

If command-line upload is not configured, open:

```bash
open frontend_flutter/ios/Runner.xcworkspace
```

Then use Xcode:

```text
Product > Archive > Distribute App > App Store Connect
```

Before uploading, confirm:

- Bundle ID matches App Store Connect.
- Apple signing team is selected.
- `ios/Runner/GoogleService-Info.plist` exists locally.
- Version/build number is newer than the last uploaded build.
- App privacy answers match actual app behavior.
- Review notes include test login details if the reviewer needs sign-in.

## Do Not Commit

Do not commit:

- `.env`
- `secrets/`
- `frontend_flutter/android/key.properties`
- `*.jks`
- `*.keystore`
- `frontend_flutter/android/app/google-services.json`
- `frontend_flutter/ios/Runner/GoogleService-Info.plist`
- generated build folders
- `backend_fastapi/data/audit.log.jsonl`
