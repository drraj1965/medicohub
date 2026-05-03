# MedicoHub Cloud-Mac / Xcode-Cloud-Ready iOS Checklist

This checklist is for preparing MedicoHub for iPhone and iPad release from a
cloud Mac or Xcode Cloud later, while you are still working mainly on Windows
and Android now.

It is written to stop at the point where you need to pay for or activate the
Apple Developer Program.

## Current repo status

These iOS basics are already prepared in this repo:

- Flutter iOS project exists in `frontend_flutter/ios`
- iOS bundle identifier is set to `com.aster.medichub`
- iOS test bundle identifier is set to `com.aster.medichub.RunnerTests`
- iOS permissions are already added in:
  - `frontend_flutter/ios/Runner/Info.plist`
- Flutter app version is managed from:
  - `frontend_flutter/pubspec.yaml`

## 1. App identifiers

### Primary bundle identifier

Use:

- `com.aster.medichub`

This should be the iOS app bundle identifier in Apple Developer / Xcode /
App Store Connect.

### Test bundle identifier

Use:

- `com.aster.medichub.RunnerTests`

### Keep identifiers aligned

Keep these aligned across:

- Apple App ID
- Xcode project signing
- Firebase iOS app registration
- App Store Connect app record

## 2. Firebase iOS config placement

### File needed

You will need the Firebase iOS config file:

- `GoogleService-Info.plist`

### Where it goes

Place it here:

- `frontend_flutter/ios/Runner/GoogleService-Info.plist`

### How to get it

In Firebase Console for project `mediconverse`:

1. Open the iOS app for bundle ID `com.aster.medichub`
2. Download `GoogleService-Info.plist`
3. Place it into `frontend_flutter/ios/Runner/`

### Important

The repo should not commit the real `GoogleService-Info.plist` if you want to
keep public source safer. Keep it local or inject it in the cloud Mac / Xcode
Cloud environment when possible.

## 3. iOS signing requirements

You do not need to pay yet just to understand the requirements, but this is
what will be needed once you move forward.

### Required Apple-side items

- Apple ID
- Apple Developer Program membership
- App ID for `com.aster.medichub`
- Signing certificate(s)
- Provisioning profile(s)
- App Store Connect app record

### Xcode project settings to confirm later on the Mac

Open:

- `frontend_flutter/ios/Runner.xcworkspace`

Then confirm:

- Team is selected
- Signing is `Automatic`
- Bundle identifier is `com.aster.medichub`
- Deployment target remains acceptable
- Archive succeeds

### Capability review

Before enabling any extra capabilities in Apple Developer / Xcode, decide
whether MedicoHub truly needs them. Right now, the expected baseline is simple:

- no push notifications yet
- no Sign in with Apple yet
- no Apple Pay yet

So keep the first iOS release as simple as possible.

## 4. TestFlight workflow plan

This is the clean rollout path once you do have Apple membership and Mac access.

### Build path

1. Pull latest GitHub code
2. Add `GoogleService-Info.plist`
3. Run Flutter dependency restore
4. Build/archive in Xcode or via Xcode Cloud
5. Upload to App Store Connect
6. Distribute through TestFlight

### Recommended first TestFlight scope

Start with:

- you
- your son
- a very small trusted tester group

### What to test in TestFlight

- sign in / sign up
- question posting
- doctor reply flow
- WhatsApp activation flow
- theme switching
- update messaging
- sponsored card display behavior
- voice note permissions and upload flow
- report/file upload behavior

### Release discipline

For iOS, keep builds focused:

- one release candidate at a time
- avoid excessive rebuilds
- use Android and Windows to shake out most issues first

This helps you stay comfortably inside the included Xcode Cloud compute hours.

## 5. App Store metadata checklist

Prepare these before Apple-side onboarding so the launch is smoother.

### App identity

- App name: `MedicoHub`
- Subtitle
- Primary category
- Secondary category if needed

### Store listing text

- Promotional text
- Description
- Keywords
- Support URL
- Marketing URL if you want one
- Privacy Policy URL

### Visual assets

- App icon
- iPhone screenshots
- iPad screenshots
- Optional preview video later

### Review/compliance text

Prepare clear language for:

- educational-use disclaimer
- no emergency use
- no diagnosis/prescription handling
- no substitute for direct medical care

### Privacy / data disclosure planning

You will later need to disclose what MedicoHub handles, for example:

- account information
- uploaded files / reports
- question / answer content
- possible analytics or ads later
- notification-related contact details

Keep this list updated as the product evolves.

## 6. Ads and iOS planning

Because you plan to add ads before wider promotion, do this before TestFlight /
App Store release:

- decide the ad provider
- add its iOS SDK only when ready
- update privacy disclosures accordingly
- verify ad placements remain subtle and do not disrupt medical/educational use

Do not rush ads into the first iOS release if they are not stable yet.

## 7. Backend readiness for iOS

Before iOS release, confirm the public backend is stable:

- public API base URL works
- Firebase Auth works
- Firestore data flow works
- storage uploads work
- WhatsApp notification flow works as intended

Current public backend target:

- `https://medicohub-backend-u5i5.onrender.com`

When you later build iOS, it should point to the public backend, not to a local
Windows laptop address.

## 8. What can be completed before paying Apple

You can finish all of this now:

- finalize app naming and identifiers
- prepare iOS Firebase app details
- download and store `GoogleService-Info.plist`
- prepare App Store metadata draft
- prepare screenshots plan
- finalize first-wave feature set
- keep Android/public-backend testing going
- decide ad strategy and privacy wording

## 9. Stop point before Apple Developer subscription

This is the natural stopping point:

- repo is iOS-ready enough
- metadata and Firebase file plan are known
- backend/public API is known
- feature scope for first iOS beta is defined

At this point, the next step would be:

- activate the Apple Developer Program

Only after that do we move into:

- App ID creation
- signing setup
- TestFlight build upload
- App Store Connect distribution workflow

## 10. Practical next actions for you now

1. Keep testing Android and Windows `v1.3.1`
2. Decide the first iOS beta feature cutoff
3. Prepare draft App Store text and screenshots list
4. Keep this file for the future cloud-Mac / Xcode Cloud session
