import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_preferences_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/holographic_background.dart';
import 'features/book_detail/book_detail_screen.dart';
import 'shared/app_shell.dart';
import 'shared/providers.dart';

class HoloReadApp extends StatefulWidget {
  const HoloReadApp({super.key});

  @override
  State<HoloReadApp> createState() => _HoloReadAppState();
}

class _HoloReadAppState extends State<HoloReadApp> {
  late final AppPreferencesController _preferences = AppPreferencesController();
  late final GoRouter _router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => _StartupGate(preferences: _preferences),
      ),
      GoRoute(
        path: '/book/:id',
        builder: (context, state) => BookDetailScreen(
          bookId: state.pathParameters['id']!,
        ),
      ),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    _preferences.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _preferences,
      builder: (context, _) => MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(oled: _preferences.oledMode),
        routerConfig: _router,
        builder: (context, child) => HolographicBackground(
          animate: !_preferences.lowPowerMode && !_preferences.reducedMotion,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _StartupGate extends ConsumerWidget {
  const _StartupGate({required this.preferences});
  final AppPreferencesController preferences;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider);
    return database.when(
      loading: () => const _BootScreen(),
      error: (error, _) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.lock_reset_rounded, size: 54),
                  const SizedBox(height: 16),
                  Text(
                    'Encrypted library initialization failed',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text('$error', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(databaseProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry safely'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      data: (_) => AppShell(preferences: preferences),
    );
  }
}

class _BootScreen extends StatefulWidget {
  const _BootScreen();

  @override
  State<_BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<_BootScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.scale(
            scale: 0.96 + _controller.value * 0.06,
            child: child,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.auto_awesome_rounded, size: 72),
              const SizedBox(height: 18),
              Text(
                'HOLOREAD',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 5,
                    ),
              ),
              const SizedBox(height: 10),
              const Text('Unlocking encrypted knowledge field…'),
              const SizedBox(height: 22),
              const SizedBox(
                width: 220,
                child: LinearProgressIndicator(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
