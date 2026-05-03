# MedicoHub Mobile Store Rollout Notes

This note keeps Android and iOS rollout steps aligned while the product is
still being validated on Windows and Android first.

## Android now

Current public-backend test target:

- `https://medicohub-backend-u5i5.onrender.com`

Current Android test artifact path after build:

- `artifacts/medicohub-android-v1.3.1-public-beta.apk`

### What to test on Android now

- sign in and sign up
- custom theme selection and HEX validation
- `My Questions` and `Public Questions` tabs
- date/topic filtering
- WhatsApp activation flow
- sponsored cards
- AdMob banner display
- app-open ad behavior when returning to the app
- voice note upload
- file/report upload

### Before Google Play later

Before publishing to Google Play, prepare:

- privacy policy URL
- app screenshots
- icon and feature graphic
- ads disclosure text
- data safety answers
- release keystore management

## iOS / TestFlight next

Use together with:

- `docs/ios-release.md`
- `docs/cloud-mac-xcode-cloud-checklist.md`

### First iOS beta scope

Keep the first TestFlight build focused on:

- login / signup
- question posting
- doctor reply flow
- WhatsApp activation
- custom themes
- uploads

Avoid expanding scope too much before the first TestFlight loop is stable.

### Ads for the first iOS beta

Because Android ad integration is now being introduced first, the clean iOS
plan is:

1. verify Android ad placements feel subtle
2. finalize privacy wording
3. add the iOS ad unit IDs later
4. test ad behavior in TestFlight before broader promotion

## Recommended release order

1. Validate the current Android public-backend build on phone.
2. Refine any ad-placement or UX issues found there.
3. Activate the Apple Developer Program when ready for TestFlight.
4. Use a cloud Mac or Xcode Cloud to produce the first iOS beta.
5. After both mobile paths are stable, create updated Windows and Android
   GitHub releases together.
