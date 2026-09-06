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

xcode_settings=("DISABLE_MANUAL_TARGET_ORDER_BUILD_WARNING=YES")
for argument in "$@"; do
  case "$argument" in
    --build-name=*) xcode_settings+=("FLUTTER_BUILD_NAME=${argument#*=}") ;;
    --build-number=*) xcode_settings+=("FLUTTER_BUILD_NUMBER=${argument#*=}") ;;
    *)
      printf 'Unsupported option: %s\n' "$argument" >&2
      printf 'Supported options: --build-name=... --build-number=...\n' >&2
      exit 2
      ;;
  esac
done

# Refresh Flutter plugin metadata and the one CocoaPods-only dependency without
# asking Xcode for a simulator-backed generic destination.
flutter pub get
(
  cd ios
  pod install
)

# The normal scheme pre-action does this before SwiftPM builds. Target builds
# skip scheme actions, so unpack Flutter.framework explicitly.
iphone_sdk="$(xcrun --sdk iphoneos --show-sdk-path)"
flutter_bin="$(command -v flutter)"
flutter_root="$(cd -- "$(dirname -- "$flutter_bin")/.." && pwd)"
env \
  FLUTTER_ROOT="$flutter_root" \
  FLUTTER_APPLICATION_PATH="$project_dir" \
  SOURCE_ROOT="$project_dir/ios" \
  CONFIGURATION=Release \
  ARCHS=arm64 \
  SDKROOT="$iphone_sdk" \
  BUILT_PRODUCTS_DIR="$project_dir/build/ios/Release-iphoneos" \
  ACTION=build \
  "$flutter_root/packages/flutter_tools/bin/xcode_backend.sh" prepare

# Xcode 26 can compile the device target from its bundled iPhoneOS SDK even when
# no simulator runtime is installed. Build the Pods target first because target
# builds do not use workspace dependency ordering.
xcodebuild build \
  -project ios/Pods/Pods.xcodeproj \
  -target Pods-Runner \
  -configuration Release \
  -sdk iphoneos \
  -jobs "$jobs" \
  -quiet \
  "BUILD_DIR=$project_dir/build/ios" \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO

xcodebuild build \
  -project ios/Runner.xcodeproj \
  -target Runner \
  -configuration Release \
  -sdk iphoneos \
  -jobs "$jobs" \
  -quiet \
  "BUILD_DIR=$project_dir/build/ios" \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO \
  "${xcode_settings[@]}"

printf '\nUnsigned iPhone release app (signing required before installation):\n'
du -sh "$project_dir/build/ios/Release-iphoneos/Runner.app"
