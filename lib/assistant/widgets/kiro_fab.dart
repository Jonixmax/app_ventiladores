import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../kiro_controller.dart';
import 'kiro_panel.dart';

/// Pestaña de ayuda pegada al borde derecho de la pantalla.
///
/// A diferencia de un FloatingActionButton clásico (que queda fijo en una
/// esquina y puede tapar contenido), esta pestaña vive sobre el borde y solo
/// asoma la mitad, por lo que casi no compite visualmente con las tarjetas
/// de cada pantalla.
///
/// Uso: como esta pestaña necesita `Positioned`, el `body` del Scaffold debe
/// ser un `Stack` que la contenga, por ejemplo:
///
/// ```dart
/// body: Stack(
///   children: [
///     SafeArea(child: ...tu contenido de siempre...),
///     const KiroTab(),
///   ],
/// ),
/// ```
class KiroTab extends StatelessWidget {
  /// Fracción de la altura de pantalla donde se centra la pestaña (0 = arriba, 1 = abajo).
  final double posicionVertical;

  const KiroTab({super.key, this.posicionVertical = 0.42});

  @override
  Widget build(BuildContext context) {
    final alturaPantalla = MediaQuery.of(context).size.height;

    return Positioned(
      right: 0,
      top: alturaPantalla * posicionVertical,
      child: ValueListenableBuilder<KiroEstado>(
        valueListenable: KiroController.instance.estado,
        builder: (context, estado, _) {
          return GestureDetector(
            onTap: () => mostrarPanelKiro(context),
            child: Container(
              width: 20,
              height: 46,
              padding: const EdgeInsets.only(left: 6),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                border: Border.all(color: colorCeleste, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 10, offset: const Offset(-2, 3))],
              ),
              child: ClipOval(child: Image.asset(estado.asset, width: 36, height: 36, fit: BoxFit.cover)),
            ),
          );
        },
      ),
    );
  }
}
