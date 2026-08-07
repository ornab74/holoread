# Google Sheets Sync Protocol

## Identity

Every book uses a stable UUID stored in column A. Spreadsheet row numbers are never treated as identity.

## Local authority

The encrypted local database drives the UI. Sheets is a synchronization surface, bulk editor, and portable copy.

## Change detection

Each record contains `syncVersion` and `updatedAt`. A canonical 30-column row is SHA-256 hashed after successful synchronization. The local journal stores the synchronized version and remote hash.

## Reconciliation

- Local-only records are pushed.
- Remote-only records are pulled.
- Equal hashes are skipped.
- A one-sided newer edit wins.
- Two-sided edits after the last baseline become explicit conflicts.
- Deleted records are represented as tombstones instead of disappearing silently.

## Failure behavior

Network and authorization failures leave local data intact. Rows are upserted by UUID, preventing repeated syncs from creating duplicates. Conflicts are preserved and reported rather than overwritten.

## Spreadsheet contract

The `Books` worksheet contains 30 columns. `SheetSchema` owns conversion, defaults, status normalization, list separators, date parsing, and boolean tombstones.
