#!/usr/bin/env bash

set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="$project_dir/build/app/outputs/flutter-apk"

cd "$project_dir"

# A previous universal build can otherwise remain beside the split APKs and be
# mistaken for the current release artifact.
rm -f "$output_dir/app-release.apk" "$output_dir/app-release.apk.sha1"

flutter build apk --release --split-per-abi "$@"

printf 'ABI-specific release APKs:\n'
for apk in "$output_dir"/app-*-release.apk; do
  if [[ -f "$apk" ]]; then
    du -h "$apk"
  fi
done
