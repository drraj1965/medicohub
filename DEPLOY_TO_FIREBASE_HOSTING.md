# Deploy MedicoHub Connect PWA to Firebase Hosting

These commands are for Windows PowerShell.

## 1. Open PowerShell

```powershell
cd "C:\Users\drpha\Documents\Aster\neurolitApp\neurolitApp-April23\doctor_forum_app"
```

## 2. Confirm Firebase Login

```powershell
firebase login
firebase projects:list
firebase use mediconverse
```

If `firebase login` opens a browser, sign in with the Google account that owns the Firebase project.

## 3. Build Flutter Web

```powershell
cd frontend_flutter
flutter clean
flutter pub get
flutter build web --release
cd ..
```

## 4. Confirm Required Files Exist

```powershell
Test-Path frontend_flutter\build\web\index.html
Test-Path frontend_flutter\build\web\manifest.json
Test-Path frontend_flutter\build\web\offline.html
Test-Path frontend_flutter\build\web\privacy.html
Test-Path frontend_flutter\build\web\terms.html
Test-Path frontend_flutter\build\web\support.html
Test-Path frontend_flutter\build\web\icons\Icon-512.png
```

Each line should return `True`.

## 5. Secret Scan Before Deploy

```powershell
rg -n "BEGIN PRIVATE|PRIVATE KEY|AuthKey|SMTP_PASSWORD|SERVICE_ACCOUNT|client_secret|APPLE_API|ISSUER_ID|\.env" frontend_flutter\build\web
```

Expected result: no output.

## 6. Dry-Run Deploy

```powershell
firebase deploy --only hosting --project mediconverse --dry-run
```

## 7. Real Deploy

Run this only after the dry-run looks safe.

```powershell
firebase deploy --only hosting --project mediconverse
```

## 8. Test Live HTTPS URL

After deploy, Firebase will print a Hosting URL. Open it and test:

- `/`
- `/manifest.json`
- `/offline.html`
- `/privacy`
- `/terms`
- `/support`
- `/delete-account`

## Rollback

Firebase Hosting keeps release history. To roll back:

1. Open Firebase Console.
2. Go to Hosting.
3. Open Release history.
4. Choose the previous working release.
5. Click Roll back.
