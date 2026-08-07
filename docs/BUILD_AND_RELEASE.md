# Build and Release

## Generate host projects

```bash
chmod +x tool/bootstrap.sh
./tool/bootstrap.sh
```

## Run locally

```bash
flutter run -d linux
flutter run -d android
```

## Validate

```bash
./tool/run_checks.sh
```

## Release examples

```bash
flutter build apk --release
flutter build appbundle --release
flutter build linux --release
flutter build windows --release
flutter build macos --release
```

Pass Google client identifiers with `--dart-define` or a private `--dart-define-from-file` excluded from source control.

Before distribution, configure platform signing, OAuth identifiers, notification manifests, privacy descriptions, secure-storage entitlements, and application identifiers.
