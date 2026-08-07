import 'package:flutter/material.dart';

import '../core/theme/app_preferences_controller.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/library/library_screen.dart';
import '../features/recommendations/recommendations_screen.dart';
import '../features/settings/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.preferences, super.key});
  final AppPreferencesController preferences;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[const DashboardScreen(), const LibraryScreen(), const RecommendationsScreen(), const AnalyticsScreen(), SettingsScreen(preferences: widget.preferences)];
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final content = IndexedStack(index: _index, children: screens);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: wide
          ? Row(children: <Widget>[
              NavigationRail(
                backgroundColor: Colors.black.withValues(alpha: 0.18),
                selectedIndex: _index,
                onDestinationSelected: (value) => setState(() => _index = value),
                extended: MediaQuery.sizeOf(context).width >= 1200,
                leading: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Icon(Icons.auto_awesome_rounded, size: 34)),
                destinations: const <NavigationRailDestination>[
                  NavigationRailDestination(icon: Icon(Icons.dashboard_rounded), label: Text('Command')),
                  NavigationRailDestination(icon: Icon(Icons.local_library_rounded), label: Text('Library')),
                  NavigationRailDestination(icon: Icon(Icons.psychology_alt_rounded), label: Text('Mechanis')),
                  NavigationRailDestination(icon: Icon(Icons.analytics_rounded), label: Text('Telemetry')),
                  NavigationRailDestination(icon: Icon(Icons.settings_rounded), label: Text('Systems')),
                ],
              ),
              Expanded(child: content),
            ])
          : content,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: const <NavigationDestination>[
                NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Command'),
                NavigationDestination(icon: Icon(Icons.local_library_rounded), label: 'Library'),
                NavigationDestination(icon: Icon(Icons.psychology_alt_rounded), label: 'Mechanis'),
                NavigationDestination(icon: Icon(Icons.analytics_rounded), label: 'Telemetry'),
                NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Systems'),
              ],
            ),
    );
  }
}
