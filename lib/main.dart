import 'dart:developer';
import 'dart:async';
import 'package:educational_app/core/notification_service/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:screen_protector/screen_protector.dart';
import 'core/design/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/route_names.dart';
import 'core/auth/session_invalidation_service.dart';
import 'core/api/api_client.dart';
import 'core/api/api_endpoints.dart';
import 'core/config/app_config_provider.dart';
import 'core/config/theme_provider.dart';
import 'services/token_storage_service.dart';
import 'l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Set to `true` when you want to block screenshots and screen recording again.
const bool kEnableScreenProtection = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await FirebaseNotification.initializeNotifications();
  log('FCM Token: ${FirebaseNotification.fcmToken}');

  if (kEnableScreenProtection) {
    try {
      await ScreenProtector.protectDataLeakageOn();
      await ScreenProtector.preventScreenshotOn();
    } catch (e) {
      debugPrint('Screen protection initialization error: $e');
    }
  }

  // Initialize app config provider
  final configProvider = AppConfigProvider();
  await configProvider.initialize();

  // Initialize theme provider (singleton) and load preferences
  final themeProvider = ThemeProvider.instance;
  await themeProvider.ensureInitialized();

  runApp(EducationalApp(
    configProvider: configProvider,
    themeProvider: themeProvider,
  ));
}

class EducationalApp extends StatelessWidget {
  final AppConfigProvider configProvider;
  final ThemeProvider themeProvider;

  const EducationalApp({
    super.key,
    required this.configProvider,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: configProvider,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: themeProvider,
          builder: (context, _) {
            return SessionInvalidationListener(
              child: FcmLaunchCoordinator(
                child: MaterialApp.router(
                  title: configProvider.config?.appName ?? 'Bouslty',
                  debugShowCheckedModeBanner: false,

                  locale: themeProvider.locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localeResolutionCallback:
                      (Locale? deviceLocale, Iterable<Locale> supported) {
                    final current = themeProvider.locale;
                    for (final locale in supported) {
                      if (locale.languageCode == current.languageCode) {
                        return locale;
                      }
                    }
                    return const Locale('en');
                  },
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],

                  // Theme - use API config if available
                  theme: AppTheme.lightTheme(configProvider.config?.theme),
                  darkTheme: AppTheme.darkTheme(configProvider.config?.theme),
                  themeMode: themeProvider.themeMode,

                  // Router
                  routerConfig: AppRouter.router,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class SessionInvalidationListener extends StatefulWidget {
  const SessionInvalidationListener({super.key, required this.child});

  final Widget child;

  @override
  State<SessionInvalidationListener> createState() =>
      _SessionInvalidationListenerState();
}

class _SessionInvalidationListenerState
    extends State<SessionInvalidationListener> with WidgetsBindingObserver {
  static const Duration _sessionCheckInterval = Duration(seconds: 2);
  static const Duration _sessionCheckTimeout = Duration(seconds: 4);

  StreamSubscription<SessionInvalidationEvent>? _subscription;
  Timer? _sessionTimer;
  bool _sessionCheckInProgress = false;
  bool _dialogVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = SessionInvalidationService.instance.stream.listen((event) {
      if (!mounted || _dialogVisible) return;
      if (event.reason != SessionInvalidationReason.loggedInFromAnotherDevice) {
        return;
      }

      _dialogVisible = true;
      AppRouter.router.go(RouteNames.login);

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final dialogContext = AppRouter.rootNavigatorKey.currentContext;
        if (dialogContext == null) {
          _dialogVisible = false;
          return;
        }

        await showDialog<void>(
          context: dialogContext,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 3.82),
          builder: (context) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;
            final message = event.message.isNotEmpty
                ? event.message
                : 'Your account was logged in on another device. Please log in again.';

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              backgroundColor: theme.brightness == Brightness.dark
                  ? const Color(0xFF1C1C1E)
                  : Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 12,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF1C1C1E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: colorScheme.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: colorScheme.error,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Session ended',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(92, 42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Log in again'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        _dialogVisible = false;
      });
    });

    _startSessionWatcher();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSessionOnce();
    }
  }

  void _startSessionWatcher() {
    _checkSessionOnce();
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(
      _sessionCheckInterval,
      (_) => _checkSessionOnce(),
    );
  }

  Future<void> _checkSessionOnce() async {
    if (!mounted || _sessionCheckInProgress || _dialogVisible) return;

    _sessionCheckInProgress = true;
    try {
      final isLoggedIn = await TokenStorageService.instance.isLoggedIn();
      if (!isLoggedIn) return;

      // Heartbeat request to detect remote session revocation immediately.
      await ApiClient.instance
          .get(
            ApiEndpoints.me,
            requireAuth: true,
          )
          .timeout(_sessionCheckTimeout);
    } catch (_) {
      // ApiClient emits a SessionInvalidationEvent on 401/session-revoked responses.
    } finally {
      _sessionCheckInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
