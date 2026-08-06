# MedicoHub App Store Connect / TestFlight Submission Pack

This file is the practical Apple release pack for MedicoHub up to the point
where a real Mac session becomes necessary.

It is designed to minimize wasted time and cloud-Mac cost later.

## 1. Confirmed Apple-side identifiers

- App name: `MedicoHub`
- Bundle ID: `com.aster.medichub`
- Apple Team ID: `853V9K56Z8`
- Firebase project: `mediconverse`
- Public backend: `https://medicohub-backend-u5i5.onrender.com`

Important distinction:

- App Store Connect API Key ID: `MXP35DX64Y`
- Issuer ID: `0cb0ad38-689d-4ada-a9f4-c4c6203e3cea`

Those API credentials are useful for future automation, but they are not the
same thing as the Apple Team ID used for signing.

## 2. App Store Connect app record plan

When App Store Connect setup begins, create one app record with:

- Name: `MedicoHub`
- Primary language: `English (U.S.)`
- Bundle ID: `com.aster.medichub`
- SKU suggestion: `medicohub-ios-001`

Recommended first platform scope:

- iPhone
- iPad

Keep macOS as a later phase. The current Flutter workspace does not yet include
the `macos/` target, so adding macOS now would increase complexity before the
first mobile beta is stable.

## 3. Metadata draft

### App name

- `MedicoHub`

### Subtitle suggestions

Pick one later:

- `Ask doctors. Learn clearly.`
- `Doctor guidance, simply explained`
- `Educational health Q&A`

Recommended first subtitle:

- `Doctor guidance, simply explained`

### Primary category suggestion

- `Medical`

### Secondary category suggestion

- `Education`

### Promotional text draft

MedicoHub helps patients ask structured health questions, follow educational
doctor replies, and review public learning threads in a calm, privacy-aware
format.

### Description draft

MedicoHub is an educational doctor-patient discussion app designed to make
health questions easier to organize and easier to understand.

With MedicoHub, users can:

- ask a question addressed to a specific doctor
- attach reports, files, and voice notes
- follow thread-based doctor replies and follow-up questions
- browse educational content and public learning threads
- manage preferences such as language, notifications, and app themes

Doctors and admins can:

- review current and historical question threads
- publish educational articles
- manage question topics and sponsored educational cards
- moderate thread content

Important:

- MedicoHub is for educational use
- it does not provide emergency handling
- it is not a substitute for direct medical care, diagnosis, or prescriptions

### Keywords suggestion set

Use a trimmed version later based on Apple limits:

- doctor
- medical
- patient
- health
- neurology
- education
- questions
- symptoms
- reports
- second opinion

Recommended compressed keyword draft:

`doctor,medical,patient,health,education,questions,symptoms,reports,neurology,opinion`

### Support URL

Needed before submission. If you do not yet have a dedicated site, prepare a
simple support page or hosted document later.

### Marketing URL

Optional for first beta.

### Privacy Policy URL

Required before broad release. Since you may later use a dedicated legal
provider such as iubenda, keep this as a planned placeholder for now rather
than overengineering it prematurely.

## 4. Screenshot checklist

Prepare these later on iPhone and iPad once the UI is frozen enough for beta.

### iPhone screenshots to capture

1. Sign In / Create Account
2. Home dashboard
3. Ask Question form
4. My Questions / Public Questions tabs with filters
5. Thread reply view
6. Education / blog view
7. Settings with theme and notifications

### iPad screenshots to capture

1. Sign In / Create Account
2. Home dashboard with wider layout
3. Ask Question form on tablet layout
4. Question browser with filters visible
5. Doctor/admin dashboard layout
6. Education / article layout
7. Settings / admin controls layout

### Screenshot notes

- Use realistic but non-sensitive demo content
- Avoid showing passwords, personal phone numbers, or private reports
- Keep screenshots consistent in theme and branding
- Prefer the cleaner, non-admin experience for public store screenshots unless
  doctor/admin roles are a key part of the marketing story

## 5. Firebase iOS registration checklist

This can be prepared before Mac access, but the final file placement happens
when a Mac session is available.

### Register the iOS app in Firebase

In Firebase project `mediconverse`:

1. Add an iOS app
2. Bundle ID: `com.aster.medichub`
3. App nickname: `MedicoHub iOS`
4. Download `GoogleService-Info.plist`

### File location later

Place the file at:

- `frontend_flutter/ios/Runner/GoogleService-Info.plist`

### Important repository note

Do not commit the real `GoogleService-Info.plist` to the public repo.

## 6. First Mac session checklist

This is the exact sequence to use once you finally have access to a real Mac
or a cloud Mac session.

### Before opening the Mac session

Have these ready:

- GitHub repo access
- Apple Developer account access
- App Store Connect access
- Firebase iOS config file: `GoogleService-Info.plist`
- public backend URL:
  `https://medicohub-backend-u5i5.onrender.com`

### Mac session actions

1. Install or open:
   - Xcode
   - Flutter SDK
   - CocoaPods
2. Clone the repo
3. Place `GoogleService-Info.plist` in:
   - `frontend_flutter/ios/Runner/`
4. From `frontend_flutter`, run:
   - `flutter pub get`
5. Build the iOS project files:
   - `flutter build ios --release --dart-define=MEDICOHUB_API_BASE_URL=https://medicohub-backend-u5i5.onrender.com`
6. Open:
   - `frontend_flutter/ios/Runner.xcworkspace`
7. In Xcode, set:
   - Team = your Apple team
   - Bundle ID = `com.aster.medichub`
   - Signing = automatic
8. Connect and test:
   - one iPhone
   - one iPad if possible
9. Fix any signing or permission issues
10. Archive the app
11. Upload to App Store Connect
12. Wait for build processing
13. Create the first TestFlight build group
14. Add only a very small trusted tester set first

### What not to do in the first Mac session

- do not add macOS target yet
- do not add many new features
- do not start with ads on iOS unless Android ad behavior is already considered
  stable and privacy wording is ready
- do not burn time styling screenshots before the archive works

## 7. TestFlight-first scope

The first Apple beta should focus on:

- sign in / sign up
- question posting
- doctor reply flow
- WhatsApp activation path
- file upload
- voice note permission and capture
- theme switching

Keep this first TestFlight milestone operational and calm.

## 8. macOS later plan

Do not include macOS in the first Apple phase.

Reason:

- the current Flutter project does not yet include the `macos/` platform folder
- adding macOS now would expand the build matrix and review complexity
- it is better to stabilize iPhone + iPad first

Later, if still wanted, the next macOS phase would be:

1. enable Flutter macOS support
2. add the `macos/` folder
3. review desktop permissions and Firebase behavior there
4. decide whether distribution is through GitHub, TestFlight-equivalent beta,
   or Mac App Store

## 9. Security cleanup note

The file:

- `docs/AuthKey_MXP35DX64Y_app-connect-API.p8`

should be moved out of `docs/` and kept in a local secrets location outside the
normal documentation tree. It should not be committed or shared casually.
