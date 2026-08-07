# Architecture

## 1. Source of truth

The encrypted SQLite database is the application source of truth. Screens never depend directly on a live Google Sheets response. This keeps the library usable offline and prevents transient network failures from blocking reading actions.

## 2. Data flow

1. UI reads Riverpod streams.
2. Providers resolve the repository.
3. Repository reads or writes the encrypted database.
4. Database emits a change event.
5. Listening screens re-query and update.
6. Synchronization separately compares local and remote records.

## 3. Synchronization model

Each book has:

- Stable UUID
- `updatedAt`
- `syncVersion`
- Deleted tombstone

The sync journal stores the last synchronized version and remote hash. During sync:

- Identical canonical hashes are skipped.
- New remote records are pulled.
- New local records are pushed.
- One-sided edits win safely.
- Two-sided edits become explicit conflicts and neither version is silently destroyed.

## 4. Mechanis

Mechanis is a deterministic, local ranking engine. It combines weighted signals:

- Priority
- Genre affinity
- Author affinity
- Length fit
- Difficulty fit
- Series continuity
- Goal alignment
- Novelty
- Completion likelihood
- Negative reading history

Modes modify weights rather than replacing the entire model. A diversity pass limits repeated authors and genres. Every result includes its score signals and explanation.

## 5. Adaptive reminders

The reminder engine selects an active or paused book, estimates the user's preferred hour from prior sessions, projects pages from observed reading pace, applies quiet hours, and returns a confidence score. Notification delivery is a separate platform service.

## 6. UI performance

- Low-power mode stops continuous background animation.
- Large libraries use sliver grids.
- Expensive visual effects are isolated in reusable panels.
- Search filtering is local and can be moved to indexed SQL for very large libraries.
