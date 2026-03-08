import 'package:flutter/material.dart';
import 'package:vez/screens/loading_page.dart';

void main() {
  runApp(const MyApp());
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
            seedColor: Colors.deepPurple,  // color for the buttons
            brightness: Brightness.dark,   // dark theme
            surface: Colors.black,         // bg color for scaffolds and cards
          ),

          // global config for the texts
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white),
            displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),

        ),

        debugShowCheckedModeBanner: false,
        home: LoadingPage(), // first page to launch
    );
  }
}