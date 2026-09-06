#!/usr/bin/env bash

set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"

# Limit native compilation without changing global Xcode or shell settings.
jobs="${VOCAB_IOS_BUILD_JOBS:-1}"
if [[ ! "$jobs" =~ ^[1-9][0-9]*$ ]]; then
  printf 'VOCAB_IOS_BUILD_JOBS must be a positive integer.\n' >&2
  exit 2
fi

# Generate Flutter configuration and resolve plugins without starting a simulator.
flutter build ios --release --no-codesign --config-only "$@"
xcodebuild build \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -jobs "$jobs" \
  -quiet \
  "BUILD_DIR=$project_dir/build/ios" \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO

printf '\nUnsigned iPhone release app (signing required before installation):\n'
du -sh "$project_dir/build/ios/Release-iphoneos/Runner.app"
