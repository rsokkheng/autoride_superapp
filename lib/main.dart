import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
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

// Resolved after WidgetsFlutterBinding.ensureInitialized() in main()
final ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('en'));

/// Returns the locale matching the device system language.
/// Falls back to English if the device language is not supported.
Locale _resolveDeviceLocale() {
  const supported = ['km', 'en', 'zh'];
  final device = PlatformDispatcher.instance.locale;
  final code   = supported.contains(device.languageCode)
      ? device.languageCode
      : 'en';
  return Locale(code);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set app locale to match device language (Khmer / English / Chinese)
  appLocale.value = _resolveDeviceLocale();

  // Sync language to all locale-aware services whenever the user changes it.
  void _applyLocale(String lang) {
    MapsService.language = lang;          // geocoding & directions API responses
    LocaleService.setLocale(lang);        // native Maps SDK tile language
  }
  _applyLocale(appLocale.value.languageCode);
  appLocale.addListener(
    () => _applyLocale(appLocale.value.languageCode),
  );

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

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
  final navigatorKey = GlobalKey<NavigatorState>();

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
          builder: (context, child) => IdleTimeoutWrapper(
            navigatorKey: navigatorKey,
            child: child!,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}