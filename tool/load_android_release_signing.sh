#!/usr/bin/env bash

# This file is sourced by Android release build scripts. CI and non-macOS
# machines can provide every VOCAB_RELEASE_* value directly.
if [[ -n "${VOCAB_RELEASE_KEYSTORE:-}" &&
      -n "${VOCAB_RELEASE_STORE_PASSWORD:-}" &&
      -n "${VOCAB_RELEASE_KEY_ALIAS:-}" &&
      -n "${VOCAB_RELEASE_KEY_PASSWORD:-}" ]]; then
  export VOCAB_RELEASE_STORE_TYPE="${VOCAB_RELEASE_STORE_TYPE:-PKCS12}"
  return 0
fi

if [[ "$(uname -s)" != "Darwin" ]] || ! command -v security >/dev/null 2>&1; then
  printf '%s\n' \
    'Android release signing is unavailable.' \
    'Provide VOCAB_RELEASE_KEYSTORE, VOCAB_RELEASE_STORE_PASSWORD,' \
    'VOCAB_RELEASE_KEY_ALIAS, and VOCAB_RELEASE_KEY_PASSWORD.' >&2
  return 1
fi

signing_config_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/vocab/signing"
signing_keystore="$signing_config_dir/vocab-release.p12"
signing_service="io.github.uzidadada.vocab.android-signing"
signing_account="vocab-release"

if [[ ! -f "$signing_keystore" ]]; then
  printf 'Release keystore not found at %s\n' "$signing_keystore" >&2
  printf '%s\n' 'Run ./tool/setup_android_release_signing_macos.sh first.' >&2
  return 1
fi

if ! signing_password="$(security find-generic-password \
  -a "$signing_account" \
  -s "$signing_service" \
  -w 2>/dev/null)"; then
  printf '%s\n' \
    'Release signing password was not found in macOS Keychain.' \
    'Run ./tool/setup_android_release_signing_macos.sh first.' >&2
  return 1
fi

export VOCAB_RELEASE_KEYSTORE="$signing_keystore"
export VOCAB_RELEASE_STORE_PASSWORD="$signing_password"
export VOCAB_RELEASE_KEY_ALIAS="vocab"
export VOCAB_RELEASE_KEY_PASSWORD="$signing_password"
export VOCAB_RELEASE_STORE_TYPE="PKCS12"
unset signing_password
