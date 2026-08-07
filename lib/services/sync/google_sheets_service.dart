import 'package:googleapis/sheets/v4.dart' as sheets;

import '../../core/config/app_config.dart';
import '../../models/book.dart';
import 'google_auth_service.dart';
import 'sheet_schema.dart';

class GoogleSheetsService {
  const GoogleSheetsService(this._authService);
  final GoogleAuthService _authService;

  Future<sheets.SheetsApi> _api() async =>
      sheets.SheetsApi(await _authService.authorizedSheetsClient());

  Future<void> ensureSchema(String spreadsheetId) async {
    final api = await _api();
    final metadata = await api.spreadsheets.get(
      spreadsheetId,
      includeGridData: false,
    );
    final exists = metadata.sheets?.any(
          (sheet) => sheet.properties?.title == AppConfig.sheetName,
        ) ??
        false;
    if (!exists) {
      await api.spreadsheets.batchUpdate(
        sheets.BatchUpdateSpreadsheetRequest(
          requests: <sheets.Request>[
            sheets.Request(
              addSheet: sheets.AddSheetRequest(
                properties: sheets.SheetProperties(title: AppConfig.sheetName),
              ),
            ),
          ],
        ),
        spreadsheetId,
      );
    }
    await api.spreadsheets.values.update(
      sheets.ValueRange(
        values: <List<Object?>>[<Object?>[...SheetSchema.headers]],
      ),
      spreadsheetId,
      '${AppConfig.sheetName}!A1:AD1',
      valueInputOption: 'RAW',
    );
  }

  Future<List<Book>> pullBooks(String spreadsheetId) async {
    final api = await _api();
    await ensureSchema(spreadsheetId);
    final response = await api.spreadsheets.values.get(
      spreadsheetId,
      '${AppConfig.sheetName}!A2:AD',
      majorDimension: 'ROWS',
    );
    final rows = response.values ?? const <List<Object?>>[];
    return rows
        .where((row) => row.isNotEmpty && '${row.first}'.trim().isNotEmpty)
        .map(SheetSchema.fromRow)
        .toList(growable: false);
  }

  Future<void> upsertBooks(String spreadsheetId, List<Book> books) async {
    if (books.isEmpty) return;
    final api = await _api();
    await ensureSchema(spreadsheetId);
    final existing = await api.spreadsheets.values.get(
      spreadsheetId,
      '${AppConfig.sheetName}!A2:A',
      majorDimension: 'ROWS',
    );
    final rowById = <String, int>{};
    final values = existing.values ?? const <List<Object?>>[];
    for (var index = 0; index < values.length; index++) {
      if (values[index].isEmpty) continue;
      final id = '${values[index].first}'.trim();
      if (id.isNotEmpty) rowById[id] = index + 2;
    }

    final newRows = <List<Object?>>[];
    for (final book in books) {
      final rowNumber = rowById[book.id];
      if (rowNumber == null) {
        newRows.add(SheetSchema.toRow(book));
      } else {
        await api.spreadsheets.values.update(
          sheets.ValueRange(values: <List<Object?>>[SheetSchema.toRow(book)]),
          spreadsheetId,
          '${AppConfig.sheetName}!A$rowNumber:AD$rowNumber',
          valueInputOption: 'RAW',
        );
      }
    }
    if (newRows.isNotEmpty) {
      await api.spreadsheets.values.append(
        sheets.ValueRange(values: newRows),
        spreadsheetId,
        '${AppConfig.sheetName}!A:AD',
        valueInputOption: 'RAW',
        insertDataOption: 'INSERT_ROWS',
      );
    }
  }
}
