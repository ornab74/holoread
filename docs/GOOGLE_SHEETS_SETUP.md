# Google Sheets Setup

## 1. Create a Google Cloud project

Create a project in Google Cloud Console and enable the Google Sheets API.

## 2. Configure OAuth consent

Configure the OAuth consent screen. Add the account used for testing while the app remains in testing status.

## 3. Create OAuth clients

Create separate OAuth client configurations for each target platform:

- Android: package name and SHA certificate fingerprints
- iOS: bundle identifier and URL scheme
- macOS: bundle identifier
- Web: authorized JavaScript origins

Do not create or embed a service-account key for this client application.

## 4. Build configuration

Pass public client identifiers with Dart defines:

```bash
flutter run \
  --dart-define=GOOGLE_OAUTH_CLIENT_ID=... \
  --dart-define=GOOGLE_OAUTH_SERVER_CLIENT_ID=...
```

Follow the platform integration instructions from `google_sign_in` after `tool/bootstrap.sh` generates the native host projects.

## 5. Prepare the spreadsheet

Create a Google Sheet and copy its ID from the URL:

```text
https://docs.google.com/spreadsheets/d/SPREADSHEET_ID/edit
```

Paste that ID into HoloRead Settings. The app will create or repair the `Books` sheet and write the expected headers.

## 6. Scope behavior

The app uses Sheets read/write and Drive file scopes. It does not ship service credentials. Authorization is performed for the signed-in user.

## 7. Desktop limitation

The official Flutter Google Sign-In plugin does not directly implement Linux or Windows interactive sign-in. For those platforms, add one of:

- A loopback OAuth desktop broker
- A backend authorization exchange
- A platform plugin that implements Google OAuth securely

Do not imitate desktop OAuth by asking users to paste access tokens.
