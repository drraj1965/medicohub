# Microsoft Store Next Steps

## 1. Deploy to Firebase Hosting

Use `DEPLOY_TO_FIREBASE_HOSTING.md`.

Expected live URL format:

`https://mediconverse.web.app/`

or

`https://mediconverse.firebaseapp.com/`

## 2. Test Live HTTPS URL

Open the live URL and verify:

- App loads.
- Manifest loads at `/manifest.json`.
- Privacy opens at `/privacy`.
- Terms opens at `/terms`.
- Support opens at `/support`.
- Offline page opens at `/offline.html`.
- Login works with demo credentials.

## 3. Run PWABuilder

Go to:

https://www.pwabuilder.com/

Paste the Firebase Hosting URL.

Fix any warnings about:

- Manifest
- Icons
- Service worker
- HTTPS
- App name

## 4. Generate Windows Package

In PWABuilder:

1. Choose Windows.
2. Generate package.
3. Download package.

## 5. Submit in Partner Center

Go to:

https://partner.microsoft.com/dashboard

Steps:

1. Reserve app name: `MedicoHub Connect`.
2. Create app submission.
3. Upload PWABuilder Windows package.
4. Add screenshots.
5. Add privacy/support URLs.
6. Add demo reviewer credentials.
7. Submit for certification.

## Reviewer Notes

MedicoHub Connect is educational only and not for emergencies. It does not replace direct medical consultation. Ads or sponsored content, if present, are labeled and not placed inside private medical communication.
