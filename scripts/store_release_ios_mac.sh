#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FLUTTER_DIR="$REPO_ROOT/frontend_flutter"
ARCHIVE_PATH="$FLUTTER_DIR/build/ios/archive/Runner.xcarchive"
EXPORT_PATH="$FLUTTER_DIR/build/ios/ipa"
BUILD_NAME="${BUILD_NAME:-1.3.25}"
BUILD_NUMBER="${BUILD_NUMBER:-33}"

echo "== MedicoHub iOS App Store Connect Release =="
echo "This script must be run on macOS with Xcode installed."

command -v flutter >/dev/null
command -v xcodebuild >/dev/null

if [ ! -f "$FLUTTER_DIR/ios/Runner/GoogleService-Info.plist" ]; then
  echo "Missing Firebase iOS config: ios/Runner/GoogleService-Info.plist" >&2
  exit 1
fi

cd "$FLUTTER_DIR"
GIT_COMMIT="$(git -C "$REPO_ROOT" rev-parse --short HEAD)"
flutter --version
flutter doctor -v
flutter clean
rm -rf build/ios/archive build/ios/ipa
flutter pub get
flutter analyze
python3 - <<PY
from pathlib import Path
import re

project = Path("ios/Runner.xcodeproj/project.pbxproj")
text = project.read_text()
text = re.sub(r"CURRENT_PROJECT_VERSION = [^;]+;", "CURRENT_PROJECT_VERSION = ${BUILD_NUMBER};", text)
text = re.sub(r"MARKETING_VERSION = [^;]+;", "MARKETING_VERSION = ${BUILD_NAME};", text)
project.write_text(text)
PY
flutter build ipa --release \
  --build-name "$BUILD_NAME" \
  --build-number "$BUILD_NUMBER" \
  --dart-define "MEDICOHUB_GIT_COMMIT=$GIT_COMMIT" \
  --dart-define "MEDICOHUB_BUILD_NUMBER=$BUILD_NUMBER" \
  --dart-define "MEDICOHUB_API_BASE_URL=https://medicohub-backend.fly.dev"

echo ""
echo "IPA output directory:"
echo "$EXPORT_PATH"
echo ""
echo "If automatic upload is not configured, open Xcode:"
echo "open ios/Runner.xcworkspace"
echo "Then Product > Archive > Distribute App > App Store Connect."
echo ""
echo "Archive path, if created:"
echo "$ARCHIVE_PATH"
