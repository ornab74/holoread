import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_preferences_controller.dart';
import '../../core/widgets/glass_panel.dart';
import '../../models/sync_models.dart';
import '../../shared/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({required this.preferences, super.key});
  final AppPreferencesController preferences;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _spreadsheetController = TextEditingController(
    text: AppConfig.defaultSpreadsheetId,
  );
  bool _busy = false;
  String _connection = 'Not connected';

  @override
  void dispose() {
    _spreadsheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.preferences,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
        children: <Widget>[
          Text(
            'Privacy and systems',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Google Sheets link', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(_connection),
                const SizedBox(height: 12),
                TextField(
                  controller: _spreadsheetController,
                  decoration: const InputDecoration(
                    labelText: 'Spreadsheet ID',
                    hintText: 'Paste the ID from the Google Sheets URL',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _connect,
                      icon: const Icon(Icons.account_circle_rounded),
                      label: const Text('Connect Google'),
                    ),
                    FilledButton.icon(
                      onPressed: _busy ? null : _sync,
                      icon: _busy
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync_rounded),
                      label: const Text('Secure sync'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Adaptive reminders', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Schedule the next locally generated reminder. Quiet hours and reading pace are respected.',
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _scheduleReminder,
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: const Text('Schedule next reminder'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassPanel(
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  value: widget.preferences.lowPowerMode,
                  onChanged: widget.preferences.setLowPowerMode,
                  title: const Text('Low-power holographics'),
                  subtitle: const Text('Reduces blur, animation, and continuous GPU work.'),
                ),
                SwitchListTile(
                  value: widget.preferences.reducedMotion,
                  onChanged: widget.preferences.setReducedMotion,
                  title: const Text('Reduced motion'),
                ),
                SwitchListTile(
                  value: widget.preferences.oledMode,
                  onChanged: widget.preferences.setOledMode,
                  title: const Text('OLED black mode'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const GlassPanel(
            child: ListTile(
              leading: Icon(Icons.lock_rounded),
              title: Text('Encrypted local database'),
              subtitle: Text(
                'A random 256-bit database key is stored through platform secure storage. SQLite uses the SQLCipher build selected by the sqlite3 native-assets hook.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connect() async {
    setState(() => _busy = true);
    try {
      final account = await ref.read(googleAuthProvider).authenticate();
      setState(() => _connection = 'Connected as ${account.email}');
    } catch (error) {
      _show('Google connection failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sync() async {
    final spreadsheetId = _spreadsheetController.text.trim();
    if (spreadsheetId.isEmpty) {
      _show('Enter a spreadsheet ID first.');
      return;
    }
    setState(() => _busy = true);
    try {
      final database = await ref.read(databaseProvider.future);
      database.setSetting('spreadsheet_id', spreadsheetId);
      final engine = await ref.read(syncEngineProvider.future);
      final report = await engine.synchronize(spreadsheetId);
      if (!mounted) return;
      _showReport(report);
    } catch (error) {
      _show('Sync failed safely: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scheduleReminder() async {
    setState(() => _busy = true);
    try {
      final suggestion = ref.read(reminderSuggestionProvider).asData?.value;
      if (suggestion == null) {
        _show('Start or pause a book before scheduling an adaptive reminder.');
        return;
      }
      final service = await ref.read(notificationServiceProvider.future);
      final granted = await service.requestPermissions();
      if (!granted) {
        _show('Notification permission was not granted.');
        return;
      }
      await service.scheduleSuggestion(suggestion);
      _show('Reminder scheduled for ${suggestion.scheduledAt}.');
    } catch (error) {
      _show('Reminder scheduling is unavailable on this platform: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showReport(SyncReport report) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync complete'),
        content: Text(
          'Pulled ${report.pulled}, pushed ${report.pushed}, skipped '
          '${report.skipped}, conflicts ${report.conflicts.length}. '
          'Conflicts are preserved rather than overwritten.',
        ),
        actions: <Widget>[
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        ],
      ),
    );
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
