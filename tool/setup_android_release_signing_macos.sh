#!/usr/bin/env bash

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf '%s\n' 'This setup helper requires macOS Keychain.' >&2
  exit 1
fi

for required_command in keytool openssl security; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$required_command" >&2
    exit 1
  fi
done

signing_config_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/vocab/signing"
signing_keystore="$signing_config_dir/vocab-release.p12"
signing_service="io.github.uzidadada.vocab.android-signing"
signing_account="vocab-release"

mkdir -p "$signing_config_dir"
chmod 700 "$signing_config_dir"

if signing_password="$(security find-generic-password \
  -a "$signing_account" \
  -s "$signing_service" \
  -w 2>/dev/null)"; then
  if [[ -f "$signing_keystore" ]]; then
    printf 'Android release signing is already configured at %s\n' "$signing_keystore"
    exit 0
  fi
else
  if [[ -e "$signing_keystore" ]]; then
    printf 'Refusing to replace an existing keystore without its Keychain credential: %s\n' \
      "$signing_keystore" >&2
    exit 1
  fi
  signing_password="$(openssl rand -hex 32)"
  security add-generic-password \
    -a "$signing_account" \
    -s "$signing_service" \
    -w "$signing_password" >/dev/null
fi

keytool -genkeypair \
  -keystore "$signing_keystore" \
  -storetype PKCS12 \
  -storepass "$signing_password" \
  -keypass "$signing_password" \
  -alias vocab \
  -keyalg RSA \
  -keysize 4096 \
  -validity 10000 \
  -dname 'CN=Vocab, OU=Mobile, O=Vocab, C=CN'

chmod 600 "$signing_keystore"
unset signing_password
printf 'Created Android release keystore: %s\n' "$signing_keystore"
printf '%s\n' 'Its password is stored in macOS Keychain under io.github.uzidadada.vocab.android-signing.'
