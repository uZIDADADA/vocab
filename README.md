# Vocab

A private-first English vocabulary and speaking companion, built with Flutter.

Vocab brings together personal words and sentence patterns, spaced review,
AI-powered speaking practice, and user-owned WebDAV sync. Android is the first
target; the codebase keeps room for other Flutter platforms later.

## Status

The repository currently contains a lightweight, dependency-minimal Flutter
shell and the first dashboard design. Real persistence, sync, accounts, and AI
providers will be added incrementally.

## Principles

- Local-first: learning works offline and local data remains the source of truth.
- Private by default: WebDAV credentials never enter source control.
- Provider-neutral: AI APIs sit behind one adapter boundary.
- Lightweight: dependencies are introduced only when a feature needs them.
- Open-source ready: product-specific services stay optional and replaceable.

## Run

```bash
flutter pub get
flutter run
```

See [docs/architecture.md](docs/architecture.md) for the planned system design.
Logo explorations live in [docs/design/logo-candidates](docs/design/logo-candidates).

## License

Not selected yet. The repository remains private during the self-test phase.
