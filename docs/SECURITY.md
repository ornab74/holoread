# Security Model

## Assets protected

- Reading history
- Private notes and quotations
- Recommendation profile
- Google authorization state
- Synchronization metadata
- Reminder behavior

## Database encryption

The application selects a SQLCipher SQLite build through the Dart native-assets hook. A random 256-bit key is generated with `Random.secure()` and stored in platform secure storage. The key is represented as a raw hexadecimal SQLCipher key, not a user password.

The app checks `PRAGMA cipher_version` and fails closed when an encrypted SQLite build is not available. This prevents a silent fallback to plaintext SQLite.

## Credential rules

- No service-account JSON is shipped.
- No OAuth client secret is shipped.
- Public OAuth client IDs are build-time values.
- Google access tokens remain managed by Google Sign-In and platform storage.
- Logs must not include tokens, private notes, or complete spreadsheet rows.

## Google scopes

The implementation requests:

- Google Sheets read/write access
- Drive file access limited to files used by the app

A future read-only mode should request the narrower Sheets read-only scope.

## Sync safety

The system uses stable IDs, versions, canonical hashing, and tombstones. Concurrent edits are surfaced as conflicts. The current UI reports the number of conflicts; a production release should add field-level merging before enabling unattended background synchronization.

## Threats not fully solved

- A compromised unlocked device can access data through the running app.
- Desktop secure-storage quality depends on operating-system keyring configuration.
- Screenshots and application previews require platform-specific protection.
- Rooted or jailbroken devices weaken key isolation.
- Google Sheets data is readable by the Google account and collaborators after sync.

## Recommended hardening

- Biometric application lock
- Android `FLAG_SECURE`
- iOS application-switcher privacy cover
- Key rotation and encrypted backup wrapping
- Dependency audit and reproducible release builds
- Certificate transparency monitoring for remote endpoints
- Privacy-safe crash reporting with explicit opt-in
