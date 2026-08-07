# Data Model

## Books

Identity, bibliographic data, reading state, progress, priority, rating, genres, tags, difficulty, goals, reminders, encrypted notes, favorite quotes, timestamps, sync version, and deletion tombstone.

## Reading sessions

Book reference, start/end timestamps, pages, focused minutes, mood, location category, focus score, and notes.

## Reminders

Book reference, type, schedule, recurrence, snooze state, completion, adaptive weight, interaction timestamp, and native notification identifier.

## Recommendation feedback

Book reference, feedback action, and timestamp. The table is ready for local weight adaptation.

## Sync journal

Entity ID, last synchronized version, canonical remote hash, and sync timestamp.

## Settings

Encrypted key/value configuration such as the selected spreadsheet ID.
