import 'package:flutter/material.dart';
import 'screens/display_screen.dart';

class TvApp extends StatelessWidget {
  const TvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'thecup Ekran',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const DisplayScreen(),
    );
  }
}
