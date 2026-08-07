#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is required. Install Flutter 3.44.0 or later first." >&2
  exit 1
fi

# flutter create adds native host projects to this source-first archive.
# Existing Dart source, assets, tests, and documentation are preserved.
flutter create . \
  --project-name holoread \
  --org com.holoread \
  --platforms=android,ios,linux,windows,macos

flutter pub get
flutter analyze
flutter test

echo "HoloRead platform hosts generated. Continue with docs/GOOGLE_SHEETS_SETUP.md."
