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

See [docs/architecture.md](docs/architecture.md) for the planned system design.
Logo explorations live in [docs/design/logo-candidates](docs/design/logo-candidates).

## AI text coach

The text coach currently supports Gemini and custom OpenAI-compatible chat
endpoints. Open **对练 → AI 设置**, choose a provider, then enter its Base URL,
model name, and API key. The Gemini preset uses
`gemini-3.1-flash-lite` and Google's OpenAI-compatible endpoint by default.

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
for this path. Android selects an offline English voice; install an English
voice pack in system speech settings if none is available. US English is
preferred, with another installed English voice as fallback.

Optionally open **我的 → 单词发音** and save a Merriam-Webster Collegiate key.
Configured keys take priority for default/US recorded pronunciation; lookup/download
failures fall back to system speech. MW recordings use a 50 MB local cache,
and the key remains in platform secure storage. Only the MW path sends the
word to an online dictionary. British pronunciation uses the system en-GB voice.
The review screen shows existing phonetics, part of speech, meaning and example
with separate UK/US speech buttons. Missing dictionary data is not fetched or
invented. No Free Dictionary API requests remain.

## License

Not selected yet. The repository remains private during the self-test phase.
