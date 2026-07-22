import 'package:flutter/material.dart';
import '../constants/colors.dart';

// Sombra "flotante" reutilizable en tarjetas (estilo 2D con profundidad)
List<BoxShadow> sombraTarjeta({double intensidad = 1.0}) => [
      BoxShadow(
        color: colorAzulOscuro.withOpacity(0.10 * intensidad),
        blurRadius: 20,
        spreadRadius: 0,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.04 * intensidad),
        blurRadius: 4,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ];

// Sombra tipo "botón elevado" (más marcada, para CTAs)
List<BoxShadow> sombraBoton({Color color = colorAzulOscuro}) => [
      BoxShadow(
        color: color.withOpacity(0.35),
        blurRadius: 16,
        spreadRadius: -2,
        offset: const Offset(0, 8),
      ),
    ];
