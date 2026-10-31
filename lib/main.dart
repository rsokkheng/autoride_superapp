import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'utils/app_log.dart';

import 'l10n/app_localizations.dart';
import 'services/locale_service.dart';
import 'services/maps_service.dart';
import 'providers/theme_provider.dart';
import 'providers/biometric_provider.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'widgets/idle_timeout_wrapper.dart';

// Khmer by default; replaced in main() by the language the user last picked.
final ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('km'));

// Top-level so ApiService can also trigger a redirect to LoginScreen (e.g.
// when a refresh token turns out to be invalid), not just IdleTimeoutWrapper.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const _kLanguagePref = 'app_language';

/// The language the user last picked, or Khmer — the app's default language
/// regardless of the device's system language.
Future<Locale> _resolveStartupLocale() async {
  const supported = ['km', 'en', 'zh'];
  final saved = (await SharedPreferences.getInstance()).getString(_kLanguagePref);
  return Locale(supported.contains(saved) ? saved! : 'km');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khmer unless the user picked another language before (Khmer / English / Chinese)
  appLocale.value = await _resolveStartupLocale();

  // Sync language to all locale-aware services whenever the user changes it.
  void _applyLocale(String lang) {
    MapsService.language = lang;          // geocoding & directions API responses
    LocaleService.setLocale(lang);        // native Maps SDK tile language
  }
  _applyLocale(appLocale.value.languageCode);
  appLocale.addListener(() {
    _applyLocale(appLocale.value.languageCode);
    // Remember the choice so the next launch opens in the same language.
    SharedPreferences.getInstance().then(
        (p) => p.setString(_kLanguagePref, appLocale.value.languageCode));
  });

  FlutterError.onError = (details) {
    AppLog.e('Flutter', details.exceptionAsString(), details.exception, details.stack);
    FlutterError.presentError(details);
  };

  final mapsImpl = GoogleMapsFlutterPlatform.instance;
  if (mapsImpl is GoogleMapsFlutterAndroid) {
    try {
      await mapsImpl.initializeWithRenderer(AndroidMapRenderer.legacy);
    } on PlatformException catch (e) {
      // Benign on Android hot restart: the native process (and its Maps
      // renderer) survives a Dart-only restart, so re-initializing throws.
      if (!e.code.contains('already initialized')) rethrow;
    }
  }

  await dotenv.load(fileName: '.env');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    // Benign on hot restart: the native process (and its Firebase app
    // instance) survives a Dart-only restart — `Firebase.apps` is a
    // Dart-side cache that resets even though the native app is still
    // registered, so checking it first doesn't help; the native call
    // itself throws "[core/duplicate-app] ... already exists" instead.
    if (e.code != 'duplicate-app') rethrow;
  }
  // Must be registered before runApp, right after Firebase is ready.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await NotificationService.instance.initialize();

  final themeProvider    = ThemeProvider();
  final biometricProvider = BiometricProvider();
  await Future.wait([themeProvider.load(), biometricProvider.load()]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: biometricProvider),
      ],
      child: const AutoRideApp(),
    ),
  );
}

class AutoRideApp extends StatefulWidget {
  const AutoRideApp({super.key});

  @override
  State<AutoRideApp> createState() => _AutoRideAppState();
}

class _AutoRideAppState extends State<AutoRideApp> {
  @override
  void initState() {
    super.initState();
    // Seed native SharedPreferences and MapsService with the current locale so
    // Google Maps tiles and geocoding responses use the right language.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lang = appLocale.value.languageCode;
      MapsService.language = lang;
      LocaleService.setLocale(lang);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'ROTEH APP',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme:     AppTheme.lightTheme,
          darkTheme: AppTheme.darkModeTheme,
          themeMode: themeProvider.mode,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          // Respect the user's font size, but cap it — very large system
          // scaling (common on Samsung) breaks fixed-height layouts.
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                  textScaler: mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.25)),
              child: IdleTimeoutWrapper(
                navigatorKey: navigatorKey,
                child: child!,
              ),
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}