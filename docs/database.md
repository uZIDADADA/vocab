# Local database

Vocab uses Drift on top of SQLite. On Android, the database is opened on a
background isolate and stored at `Application Support/database/vocab.sqlite`.
The UI only talks to `LearningRepository`; generated Drift rows do not escape
the data layer.

## Tables

- `vocabulary_entries`: words, definitions, source context, mastery and due date.
- `sentence_patterns`: reusable spoken patterns, meanings, examples and due date.
- `review_events`: immutable review history used for future scheduling changes.
- `inbox_entries`: unprocessed items imported from KISS or collected from AI.
- `app_settings`: non-secret local metadata. Credentials must use secure storage.

Mutable syncable rows include `sync_revision`, `is_dirty`, `updated_at`, and a
soft-delete timestamp. These fields are intentionally present before WebDAV is
implemented so the sync layer can export changes without changing the schema.

## Schema changes

1. Increment `schemaVersion` in `app_database.dart`.
2. Add an explicit `onUpgrade` migration for every supported previous version.
3. Regenerate Drift code:

```bash
dart run build_runner build
```

4. Add a migration test before shipping the change.

`app_database.g.dart` is generated source and should not be edited manually.
