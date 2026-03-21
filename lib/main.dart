import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vez/screens/loading_screen.dart';

void main() {
  // we ensure widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // orientation lock (vertical)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // here to set the global style of the application //
    return MaterialApp(
        title: 'Vez',
        theme: ThemeData(
          useMaterial3: true,
          // Imposta il font globale qui
          fontFamily: 'InstagramSans',

          // defining the colors scheme
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.redAccent,  // color for the buttons
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
  }
}