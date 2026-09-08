# Vocab

A private-first English vocabulary and speaking companion, built with Flutter.

Vocab brings together personal words and sentence patterns, spaced review,
AI-powered speaking practice, and user-owned WebDAV sync. Android is the first
target; the codebase keeps room for other Flutter platforms later.

## Status

The repository contains a functional four-screen Flutter app backed by a local
Drift/SQLite data layer. Vocabulary, sentence patterns, review events, inbox
items, AI conversations, search, favorites, and dashboard counts are persisted
locally. The app can also import encrypted favorite words from KISS Translator's
KISS-Worker sync and place them into the review queue. Full Vocab WebDAV sync
and browser share-target capture are later implementation slices.

## Principles

- Local-first: learning works offline and local data remains the source of truth.
- Private by default: WebDAV credentials never enter source control.
- Provider-neutral: AI APIs sit behind one adapter boundary.
- Lightweight: dependencies are introduced only when a feature needs them.
- Open-source ready: product-specific services stay optional and replaceable.

## Run

```bash
flutter pub get
dart run build_runner build
flutter run
```

## Android release builds

Android Release artifacts use a private, long-lived signing key instead of the
Flutter debug key. On macOS, create it once; the encrypted keystore is stored
outside the repository and its random password is stored in macOS Keychain:

```bash
./tool/setup_android_release_signing_macos.sh
```

Back up both the keystore and its Keychain password securely. Losing them makes
it impossible to issue compatible APK updates. Never commit or share either.

Build ABI-specific Release APKs for direct device testing:

```bash
./tool/build_android_release_apks.sh
```

It produces separate `armeabi-v7a`, `arm64-v8a`, and `x86_64` APKs under
`build/app/outputs/flutter-apk/` and removes any stale universal release APK
from that directory. Use an Android App Bundle instead when publishing through
Google Play so Play can deliver the device-specific APK automatically.

For Google Play internal testing or production, build the signed Android App
Bundle instead:

```bash
./tool/build_android_release_aab.sh
```

Release builds on CI or non-macOS hosts can provide
`VOCAB_RELEASE_KEYSTORE`, `VOCAB_RELEASE_STORE_PASSWORD`,
`VOCAB_RELEASE_KEY_ALIAS`, and `VOCAB_RELEASE_KEY_PASSWORD` directly.

### GitHub Actions builds

The `Android release` workflow builds signed ABI-specific APKs and an AAB on
every push to `main`, on version tags matching `v*`, and when started manually
from the GitHub Actions page. Every successful run keeps the packages as a
30-day workflow artifact. A version tag also publishes the same files and their
SHA-256 checksums to GitHub Releases.

Configure these repository secrets under **Settings → Secrets and variables →
Actions** before the first run:

- `VOCAB_RELEASE_KEYSTORE_BASE64`: Base64 text of the PKCS12 keystore.
- `VOCAB_RELEASE_STORE_PASSWORD`: Keystore password.
- `VOCAB_RELEASE_KEY_ALIAS`: Key alias (`vocab` for the setup script above).
- `VOCAB_RELEASE_KEY_PASSWORD`: Private-key password.

On the Mac that owns the signing key, the GitHub CLI can transfer the values
without printing the password:

```bash
base64 -i ~/.config/vocab/signing/vocab-release.p12 | \
  gh secret set VOCAB_RELEASE_KEYSTORE_BASE64
security find-generic-password \
  -a vocab-release \
  -s io.github.uzidadada.vocab.android-signing \
  -w | gh secret set VOCAB_RELEASE_STORE_PASSWORD
gh secret set VOCAB_RELEASE_KEY_ALIAS --body vocab
security find-generic-password \
  -a vocab-release \
  -s io.github.uzidadada.vocab.android-signing \
  -w | gh secret set VOCAB_RELEASE_KEY_PASSWORD
```

For an ordinary build, push to `main` and download the artifact from its Actions
run. For a downloadable release, first update `version:` in `pubspec.yaml`,
commit and push it, then push a matching tag. A prerelease version such as
`0.1.0-beta.1+2` uses tag `v0.1.0-beta.1` and is marked as a GitHub
Pre-release; a stable version such as `1.0.0+10` uses tag `v1.0.0`. The workflow
rejects a tag whose version does not match `pubspec.yaml`.

See [docs/architecture.md](docs/architecture.md) for the planned system design.
Logo explorations live in [docs/design/logo-candidates](docs/design/logo-candidates).

## iOS release builds

The iOS runner targets iOS 15.0 or later with bundle ID
`io.github.uzidadada.vocab`. On a Mac, install full Xcode with iOS platform
support and CocoaPods (`brew install cocoapods`). Select Xcode's command-line
tools and complete its first-launch setup. Flutter and `pod` must be on PATH;
no additional global environment variables are required.

Build an unsigned device Release app with one native compile job:

```bash
./tool/build_ios_release.sh
```

This runs from the terminal without launching Xcode or a simulator. The output
is `build/ios/Release-iphoneos/Runner.app`; it requires signing before it can
be installed on an iPhone. `VOCAB_IOS_BUILD_JOBS=2` optionally increases native
build concurrency. The script accepts Flutter build options such as
`--build-number=2` or `--build-name=0.1.1`. Builds still require memory for the compiler; one job limits
concurrency, not total memory use.

To export a signed IPA, first open `ios/Runner.xcworkspace` in Xcode and choose
your Team under **Runner → Signing & Capabilities**, with automatic signing.
Use an available bundle ID for that Team. Then run `flutter build ipa --release`
for App Store/TestFlight, or `flutter build ipa --release --export-method development`
for an appropriate development provisioning profile. IPA export depends on
your Apple account and signing assets; the unsigned build does not configure
these or upload anything. Standard Flutter IPA builds use Xcode's default
concurrency, so avoid other heavy tasks during export on a small-memory Mac.

iOS Keychain configuration is included for secure storage. Database, dictionary,
speech and network features still require iPhone validation. Daily reminders
currently have an Android-only implementation and show as unsupported on iOS.

## AI text coach

The text coach includes presets for Gemini, DeepSeek, Zhipu BigModel, and Kimi,
and also supports custom OpenAI-compatible chat endpoints. Open **对练 → AI
设置**, choose a provider, then enter its Base URL, model name, and API key.
Provider presets fill the official endpoint and a current default model while
keeping both fields editable.

The API key is stored with the platform secure-storage service; non-secret
provider metadata is stored in SQLite. Conversations and messages are stored in
SQLite. The app keeps the 20 most recent conversations by default; open the
history sheet to change the limit from 1 to 100, continue a conversation, or
delete history. A message can also be analyzed by the configured model and its
confirmed word or sentence-pattern suggestions saved to the learning library.
Create a Gemini key in [Google AI Studio](https://aistudio.google.com/apikey).

## KISS-Worker vocabulary import

Open **我的 → KISS-Worker 词汇同步 → 同步设置** and enter the same HTTPS
Worker endpoint, sync key, and encryption passphrase used by KISS Translator.
All three values are stored in platform secure storage. The app requests
`kiss-words.json`, performs PBKDF2-SHA-256/AES-GCM decryption on the device,
shows a confirmation before importing, skips existing terms, and never sends
decrypted vocabulary to the Worker. Imported words are immediately available
in the four-rating review flow under **今日**.

### Upload words added on the phone

Use **我的 → 上传本机新增** and confirm the upload. Manually added words
and words saved from AI practice are merged into the remote word book after
client-side encryption. Imported words, demo entries, deleted words, sentence
patterns, and review history are excluded. Matching terms ignore case and
surrounding whitespace; existing remote entries and their unknown fields win.
Uploading again skips words already present. This is manual, additive upload,
not background sync or deletion/edit propagation.

The adapter uses the official KISS-Worker `POST /sync` protocol. It increments
the observed remote version and retries merging a newer returned record up to
three times. The protocol has no compare-and-swap guarantee; older Worker/KV
deployments or other clients can still overwrite a whole book later. Real
Worker and browser-extension interoperability still requires device validation.

## Word pronunciation

Word cards use the device's built-in English text-to-speech engine by default,
via the open-source `flutter_tts` bridge. No dictionary HTTP API or key is used
for this path. Android prefers an installed offline English voice; when the
requested accent is available only as a system-provided network voice, the
device speech engine may use its own network service. If an available accent is
not listed as a voice, the app still asks the engine to resolve that locale so
it can fetch speech online instead of failing early. Install an English voice
pack in system speech settings for reliable offline playback. US English is
preferred for automatic playback, with another English voice as fallback.

Optionally open **我的 → 单词发音** and save a Merriam-Webster Collegiate key.
Configured keys take priority for default/US recorded pronunciation; lookup/download
failures fall back to system speech. MW recordings use a 50 MB local cache,
and the key remains in platform secure storage. Only the MW path sends the
word to an online dictionary directly from the app. British pronunciation uses
the system en-GB voice and never silently substitutes an American voice.
The review screen shows existing phonetics, part of speech, meaning and example
with separate UK/US speech buttons. Missing dictionary data is not fetched or
invented. No Free Dictionary API requests remain.

## License

Licensed under the [Apache License 2.0](LICENSE).
