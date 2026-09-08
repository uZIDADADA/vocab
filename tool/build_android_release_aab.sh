#!/usr/bin/env bash

set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$project_dir"
source "$project_dir/tool/load_android_release_signing.sh"

flutter build appbundle --release "$@"

bundle="$project_dir/build/app/outputs/bundle/release/app-release.aab"
if [[ -f "$bundle" ]]; then
  printf 'Android App Bundle:\n'
  du -h "$bundle"
fi
