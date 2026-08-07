import 'dart:async';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';

class GoogleAuthService {
  final GoogleSignIn _signIn = GoogleSignIn.instance;
  GoogleSignInAccount? _currentUser;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;
  bool _initialized = false;

  GoogleSignInAccount? get currentUser => _currentUser;

  Future<void> initialize() async {
    if (_initialized) return;
    await _signIn.initialize(
      clientId: AppConfig.googleClientId.isEmpty ? null : AppConfig.googleClientId,
      serverClientId: AppConfig.googleServerClientId.isEmpty
          ? null
          : AppConfig.googleServerClientId,
    );
    _subscription = _signIn.authenticationEvents.listen((event) {
      _currentUser = switch (event) {
        GoogleSignInAuthenticationEventSignIn() => event.user,
        _ => null,
      };
    });
    final lightweightAuthentication =
        _signIn.attemptLightweightAuthentication();
    if (lightweightAuthentication != null) {
      unawaited(lightweightAuthentication);
    }
    _initialized = true;
  }

  Future<GoogleSignInAccount> authenticate() async {
    await initialize();
    if (!_signIn.supportsAuthenticate()) {
      throw UnsupportedError(
        'Interactive Google sign-in requires the platform-provided Google button.',
      );
    }
    final user = await _signIn.authenticate();
    _currentUser = user;
    return user;
  }

  Future<http.Client> authorizedSheetsClient() async {
    await initialize();
    final user = _currentUser ?? await authenticate();
    const scopes = <String>[
      sheets.SheetsApi.spreadsheetsScope,
      sheets.SheetsApi.driveFileScope,
    ];
    final existing = await user.authorizationClient.authorizationForScopes(scopes);
    final authorization = existing ??
        await user.authorizationClient.authorizeScopes(scopes);
    return authorization.authClient(scopes: scopes);
  }

  Future<void> signOut() async {
    await _signIn.signOut();
    _currentUser = null;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}
