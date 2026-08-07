import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyManager {
  KeyManager({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _databaseKeyName = 'holoread.database.key.v1';
  final FlutterSecureStorage _storage;

  Future<Uint8List> loadOrCreateDatabaseKey() async {
    final existing = await _storage.read(key: _databaseKeyName);
    if (existing != null && existing.isNotEmpty) {
      final decoded = base64Url.decode(existing);
      if (decoded.length != 32) {
        throw StateError('Stored database key has an invalid length.');
      }
      return Uint8List.fromList(decoded);
    }

    final random = Random.secure();
    final key = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    await _storage.write(
      key: _databaseKeyName,
      value: base64UrlEncode(key),
    );
    return key;
  }

  Future<void> deleteDatabaseKey() =>
      _storage.delete(key: _databaseKeyName);
}
