# MedicoHub iOS Release Path

This project is now structurally ready for iPhone and iPad packaging, but the
actual iOS build and upload must happen on a Mac with Xcode.

## What is already prepared

- iOS folder exists in `frontend_flutter/ios`
- bundle identifier is set to `com.aster.medichub`
- iPhone and iPad orientations are enabled
- microphone, camera, and photo-library permission text is set in
  `frontend_flutter/ios/Runner/Info.plist`

## What requires your action

1. Install Xcode on a Mac.
2. Open `frontend_flutter/ios/Runner.xcworkspace` in Xcode.
3. Add the Firebase iOS config file:
   - `frontend_flutter/ios/Runner/GoogleService-Info.plist`
4. In Xcode, set the correct Apple Team under Signing & Capabilities.
5. Test on an iPhone and iPad.
6. Archive and upload the build to App Store Connect.
7. Use TestFlight for private beta testing before App Store release.

## When the Apple subscription is required

You can work with a free Apple developer account for limited local device
testing in Xcode, but you need the paid Apple Developer Program membership
before:

- TestFlight distribution
- App Store distribution
- App Store Connect upload and release workflows

## Recommended launch sequence

1. Finish Android/public-backend validation.
2. Buy the Apple Developer Program membership when you're ready to start
   TestFlight.
3. On a Mac:
   - run `flutter pub get`
   - run `flutter build ios --release --dart-define=MEDICOHUB_API_BASE_URL=https://YOUR_PUBLIC_BACKEND`
   - open Xcode and archive the app
4. Upload to App Store Connect.
5. Share through TestFlight with your close testers first.

## Important caveats

- iOS builds cannot be produced from this Windows laptop alone.
- Ad network setup for iOS should be finalized before broader promotion so the
  app review metadata, privacy disclosures, and ad placements match the final
  product behavior.
