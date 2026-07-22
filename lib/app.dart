import 'package:flutter/material.dart';
import 'core/constants/colors.dart';
import 'screens/splash/splash_screen.dart';

class MiAppIot extends StatelessWidget {
  const MiAppIot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KITHER Ventilación',
      theme: ThemeData(
        scaffoldBackgroundColor: colorFondo,
        primaryColor: colorAzulOscuro,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.light(primary: colorAzulOscuro, secondary: colorCeleste),
      ),
      home: const PantallaSplash(),
    );
  }
}
