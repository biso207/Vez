// Developed and Designed by Outly • © 2026
// Entry point for the application.

import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vez/screens/auth/loading_screen.dart';
import 'package:vez/services/notification_service.dart';
import 'package:vez/services/translation_service.dart';

// ── main ─────────────────────────────────────────────────────────────────────
//
//   used for: initializing services and running the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  //debugDefaultTargetPlatformOverride = TargetPlatform.iOS; // comment before release build

  runApp(
    DevicePreview(
      enabled:
          false, // set true to enable the device preview (iPhones) - set false before release build
      builder: (context) => const MyApp(),
    ),
  );
}

// ── my app ───────────────────────────────────────────────────────────────────
//
//   used for: defining the global theme and localized materials.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // ── build ──────────────────────────────────────────────────────────────────
  //
  //   used for: rendering the root MaterialApp.
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StringRes.localeNotifier,
      builder: (context, _) {
        return MaterialApp(
          locale: Locale(StringRes.locale),
          builder: DevicePreview.appBuilder,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('it'),
            Locale('de'),
            Locale('fr'),
            Locale('es'),
            Locale('zh'),
          ],
          title: 'Vez',
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'InstagramSans',
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.white,
              brightness: Brightness.dark,
              surface: Colors.black,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.normal,
              ),
              bodyMedium: TextStyle(color: Colors.white),
              displayLarge: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          debugShowCheckedModeBanner: false,
          home: const LoadingPage(),
        );
      },
    );
  }
}
