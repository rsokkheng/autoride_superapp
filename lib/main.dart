import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'utils/app_log.dart';

import 'l10n/app_localizations.dart';
import 'providers/theme_provider.dart';
import 'providers/biometric_provider.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

final ValueNotifier<Locale> appLocale =
    ValueNotifier(const Locale('km'));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    AppLog.e('Flutter', details.exceptionAsString(), details.exception, details.stack);
    FlutterError.presentError(details);
  };

  final mapsImpl = GoogleMapsFlutterPlatform.instance;
  if (mapsImpl is GoogleMapsFlutterAndroid) {
    await mapsImpl.initializeWithRenderer(AndroidMapRenderer.legacy);
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

class AutoRideApp extends StatelessWidget {
  const AutoRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'ROTEH App',
          debugShowCheckedModeBanner: false,
          theme:     AppTheme.lightTheme,
          darkTheme: AppTheme.darkModeTheme,
          themeMode: themeProvider.mode,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const SplashScreen(),
        );
      },
    );
  }
}