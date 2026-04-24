import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vez/screens/auth/loading_screen.dart';
import 'package:vez/services/translation_service.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  // we ensure widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // orientation lock (vertical)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {

    //debugDefaultTargetPlatformOverride = TargetPlatform.iOS; // comment before release build

    runApp(DevicePreview(
      enabled: false, // set true to enable the device preview (iPhones) • set false before release build
      builder: (context) => MyApp(),
    ),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StringRes.localeNotifier,
      builder: (context, _) {
        // here to set the global style of the application //
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
              // Imposta il font globale qui
              fontFamily: 'InstagramSans',

              // defining the colors scheme
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.white,  // color for the buttons
                brightness: Brightness.dark,   // dark theme
                surface: Colors.black,         // bg color for scaffolds and cards
              ),

              // style for all the texts in the app
              inputDecorationTheme: const InputDecorationTheme(
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
              ),

              // global config for the digitated texts
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
                bodyMedium: TextStyle(color: Colors.white),
                displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),

            ),

            debugShowCheckedModeBanner: false,
            home: LoadingPage(), // first page to launch
        );
      },
    );
  }
}
