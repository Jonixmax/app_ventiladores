import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class TarjetaAccion extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icono;
  final Color colorIcono;
  final String titulo;
  final Color colorTitulo;
  final Color? colorFondo;
  final Gradient? gradiente;
  final String? subtitulo;
  final Color colorSubtitulo;

  const TarjetaAccion({
    super.key,
    required this.onTap,
    required this.icono,
    required this.colorIcono,
    required this.titulo,
    required this.colorTitulo,
    this.colorFondo,
    this.gradiente,
    this.subtitulo,
    this.colorSubtitulo = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 104,
        decoration: BoxDecoration(
          color: gradiente == null ? colorFondo : null,
          gradient: gradiente,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: (colorFondo ?? colorAzulOscuro).withOpacity(0.18), blurRadius: 14, offset: const Offset(0, 6))],
          border: colorFondo == Colors.white ? Border.all(color: colorAzulOscuro.withOpacity(0.15), width: 1.5) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 32, color: colorIcono),
            const SizedBox(height: 6),
            Text(titulo, style: TextStyle(color: colorTitulo, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
            if (subtitulo != null) ...[
              const SizedBox(height: 2),
              Text(subtitulo!, style: TextStyle(color: colorSubtitulo, fontSize: 11, fontWeight: FontWeight.w600)),
            ]
          ],
        ),
      ),
    );
  }
}
