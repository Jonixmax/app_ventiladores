// Smoke test: verifica que la app arranca y muestra la pantalla Splash
// sin lanzar excepciones.
import 'package:flutter_test/flutter_test.dart';

import 'package:app_ventiladores/app.dart';

void main() {
  testWidgets('La app arranca y muestra el splash de KITHER', (WidgetTester tester) async {
    await tester.pumpWidget(const MiAppIot());

    expect(find.text('KITHER'), findsOneWidget);
    expect(find.text('VENTILACIÓN INTELIGENTE'), findsOneWidget);

    // El splash espera 3s antes de navegar al Login. Avanzamos el reloj de
    // pruebas ese tiempo para que el Timer no quede "pendiente" al terminar
    // el test (si no, flutter_test lo marca como fuga y falla el test).
    await tester.pump(const Duration(seconds: 4));
  });
}