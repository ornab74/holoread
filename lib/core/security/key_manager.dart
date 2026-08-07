import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the active HoloRead database key was loaded from.
enum KeyStorageBackend {
  osKeyring,
  linuxProtectedFile,
}

/// Loads the SQLCipher database key.
///
/// HoloRead always tries the operating-system credential store first. On Linux
/// only, machines without a working Secret Service implementation (for example
/// minimal/Crostini sessions where org.freedesktop.secrets is unavailable) can
/// fall back to a per-user file protected with Unix 0700/0600 permissions.
///
/// The file fallback is intentionally Linux-only and is less resistant to a
/// fully compromised local user account than a functioning OS keyring. It is
/// still a randomly generated 256-bit SQLCipher key and is never committed to
/// the project or stored beside source code.
class KeyManager {
  KeyManager({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _databaseKeyName = 'holoread.database.key.v1';
  static const String _fallbackDirectoryName = 'holoread';
  static const String _fallbackKeyFileName = 'database-key-v1';

  final FlutterSecureStorage _storage;

  KeyStorageBackend? _activeBackend;
  KeyStorageBackend? get activeBackend => _activeBackend;
  bool get isUsingFallback =>
      _activeBackend == KeyStorageBackend.linuxProtectedFile;

  Future<Uint8List> loadOrCreateDatabaseKey() async {
    try {
      final key = await _loadOrCreateFromOsKeyring();
      _activeBackend = KeyStorageBackend.osKeyring;
      return key;
    } on PlatformException catch (error) {
      if (!Platform.isLinux || !_isLinuxKeyringUnavailable(error)) {
        rethrow;
      }
      final key = await _loadOrCreateLinuxFallback();
      _activeBackend = KeyStorageBackend.linuxProtectedFile;
      return key;
    } catch (error) {
      // Some Linux secret-service implementations surface D-Bus/libsecret
      // failures as non-PlatformException errors. Only fall back when the
      // message clearly identifies the Secret Service/keyring layer.
      if (!Platform.isLinux || !_looksLikeLinuxKeyringFailure(error)) {
        rethrow;
      }
      final key = await _loadOrCreateLinuxFallback();
      _activeBackend = KeyStorageBackend.linuxProtectedFile;
      return key;
    }
  }

  Future<Uint8List> _loadOrCreateFromOsKeyring() async {
    final existing = await _storage.read(key: _databaseKeyName);
    if (existing != null && existing.isNotEmpty) {
      return _decodeAndValidate(existing, source: 'OS keyring');
    }

    final key = _generateKey();
    await _storage.write(
      key: _databaseKeyName,
      value: base64UrlEncode(key),
    );
    return key;
  }

  Future<Uint8List> _loadOrCreateLinuxFallback() async {
    final file = _linuxFallbackFile();
    final parent = file.parent;

    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    await _chmod(parent.path, '700');

    if (await file.exists()) {
      await _chmod(file.path, '600');
      final existing = (await file.readAsString()).trim();
      if (existing.isEmpty) {
        throw StateError('Linux fallback database key file is empty.');
      }
      return _decodeAndValidate(existing, source: 'Linux fallback key file');
    }

    final key = _generateKey();
    final encoded = base64UrlEncode(key);
    final temp = File('${file.path}.tmp-${DateTime.now().microsecondsSinceEpoch}');

    try {
      await temp.writeAsString(encoded, flush: true);
      await _chmod(temp.path, '600');
      await temp.rename(file.path);
      await _chmod(file.path, '600');
    } finally {
      if (await temp.exists()) {
        await temp.delete();
      }
    }

    return key;
  }

  Uint8List _generateKey() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
  }

  Uint8List _decodeAndValidate(String encoded, {required String source}) {
    try {
      final decoded = base64Url.decode(encoded);
      if (decoded.length != 32) {
        throw StateError('$source database key has an invalid length.');
      }
      return Uint8List.fromList(decoded);
    } on FormatException catch (error) {
      throw StateError('$source database key is not valid base64: $error');
    }
  }

  File _linuxFallbackFile() {
    final home = Platform.environment['HOME'];
    if (home == null || home.trim().isEmpty) {
      throw StateError(
        'Linux keyring is unavailable and HOME is not set, so the protected '
        'local key fallback cannot be initialized.',
      );
    }

    final configHome = Platform.environment['XDG_CONFIG_HOME'];
    final root = (configHome != null && configHome.trim().isNotEmpty)
        ? configHome
        : '$home/.config';
    return File('$root/$_fallbackDirectoryName/keys/$_fallbackKeyFileName');
  }

  Future<void> _chmod(String path, String mode) async {
    final result = await Process.run('chmod', <String>[mode, path]);
    if (result.exitCode != 0) {
      throw FileSystemException(
        'Unable to secure HoloRead fallback key permissions (${result.stderr})',
        path,
      );
    }
  }

  bool _isLinuxKeyringUnavailable(PlatformException error) {
    final details = '${error.code} ${error.message ?? ''} ${error.details ?? ''}';
    return _looksLikeLinuxKeyringFailure(details);
  }

  bool _looksLikeLinuxKeyringFailure(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('org.freedesktop.secrets') ||
        text.contains('libsecret') ||
        text.contains('secret_service') ||
        text.contains('secret service') ||
        text.contains('keyring') ||
        text.contains('not provided by any .service files') ||
        text.contains('cannot autolaunch d-bus') ||
        text.contains('dbus');
  }

  Future<void> deleteDatabaseKey() async {
    Object? keyringError;
    try {
      await _storage.delete(key: _databaseKeyName);
    } catch (error) {
      keyringError = error;
      if (!Platform.isLinux || !_looksLikeLinuxKeyringFailure(error)) {
        rethrow;
      }
    }

    if (Platform.isLinux) {
      final file = _linuxFallbackFile();
      if (await file.exists()) {
        await file.delete();
      }
    }

    // A Linux keyring error is deliberately suppressed after the local
    // fallback has been removed. On every other platform it is rethrown above.
    if (keyringError != null && !Platform.isLinux) {
      throw keyringError;
    }
    _activeBackend = null;
  }
}
