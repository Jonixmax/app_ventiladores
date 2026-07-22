import 'package:flutter/foundation.dart';

enum KiroEstado { feliz, triste, asombrado }

extension KiroEstadoAsset on KiroEstado {
  /// Ruta del asset correspondiente a cada emoción (ya declarados en pubspec.yaml).
  String get asset {
    switch (this) {
      case KiroEstado.feliz:
        return 'assets/kiro_feliz.png';
      case KiroEstado.triste:
        return 'assets/kiro_triste.png';
      case KiroEstado.asombrado:
        return 'assets/kiro_asombrado.png';
    }
  }
}

/// Singleton simple: cualquier pantalla puede hacer
/// `KiroController.instance.cambiarEstado(KiroEstado.triste)` y el FAB
/// (en cualquier pantalla que lo tenga montado) se actualiza solo.
class KiroController {
  KiroController._interno();
  static final KiroController instance = KiroController._interno();

  final ValueNotifier<KiroEstado> estado = ValueNotifier(KiroEstado.feliz);

  void cambiarEstado(KiroEstado nuevoEstado) {
    estado.value = nuevoEstado;
  }

  /// Vuelve a la cara feliz por defecto (útil tras mostrar un error momentáneo).
  void resetear() {
    estado.value = KiroEstado.feliz;
  }
}
