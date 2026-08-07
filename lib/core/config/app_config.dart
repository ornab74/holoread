class AppConfig {
  const AppConfig._();

  static const String appName = 'HoloRead';
  static const String databaseName = 'holoread_encrypted.sqlite';
  static const int databaseSchemaVersion = 1;
  static const String sheetName = 'Books';

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_OAUTH_CLIENT_ID',
  );
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_OAUTH_SERVER_CLIENT_ID',
  );
  static const String defaultSpreadsheetId = String.fromEnvironment(
    'DEFAULT_SPREADSHEET_ID',
  );
}
