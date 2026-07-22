import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/shadows.dart';

Widget _botonVelocidadAuto(int valor, String texto, int velocidadActual, VoidCallback onTap) {
  bool seleccionado = valor == velocidadActual;
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: seleccionado ? colorCeleste : colorFondoTarjeta,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: seleccionado ? colorAzulOscuro : Colors.transparent, width: 1.5),
      ),
      child: Text(texto, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: seleccionado ? Colors.white : colorAzulOscuro)),
    ),
  );
}

Widget _botonCircular({required IconData icono, required Color color, required VoidCallback onTap}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 6),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withOpacity(0.1),
      boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))],
    ),
    child: IconButton(icon: Icon(icono, color: color), onPressed: onTap),
  );
}

/// Muestra el diálogo para configurar el Modo Automático (rango de temperatura + velocidad).
/// `onGuardar` recibe los 4 valores finales para que la pantalla llamante actualice su
/// estado y envíe el comando "AUTO:..." al ESP32.
void mostrarAjustesAuto(
  BuildContext context, {
  required int tempMin,
  required int tempMax,
  required bool modoAuto,
  required int velocidadAuto,
  required void Function(int tempMin, int tempMax, bool modoAuto, int velocidadAuto) onGuardar,
}) {
  showDialog(
    context: context,
    builder: (context) {
      int tempBaja = tempMin; int tempAlta = tempMax; bool autoActivado = modoAuto; int velAuto = velocidadAuto;
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            elevation: 12,
            title: Row(children: const [
              Icon(Icons.autorenew, color: colorAzulOscuro),
              SizedBox(width: 10),
              Text('Configurar Modo Auto', style: TextStyle(color: colorAzulOscuro, fontWeight: FontWeight.bold, fontSize: 17)),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(color: colorFondo, borderRadius: BorderRadius.circular(14)),
                  child: SwitchListTile(
                    title: const Text('Activar Modo Automático', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    activeColor: colorCeleste, value: autoActivado,
                    onChanged: (val) { setStateDialog(() { autoActivado = val; }); },
                  ),
                ),
                const SizedBox(height: 18),
                const Text('El sistema se apagará al bajar de:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _botonCircular(icono: Icons.remove, color: colorAzulOscuro, onTap: () => setStateDialog(() => tempBaja--)),
                  SizedBox(width: 60, child: Text('$tempBaja°C', textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: colorAzulOscuro))),
                  _botonCircular(icono: Icons.add, color: colorAzulOscuro, onTap: () => setStateDialog(() => tempBaja++)),
                ]),
                const SizedBox(height: 14),
                const Text('El sistema se encenderá al superar:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _botonCircular(icono: Icons.remove, color: colorPeligro, onTap: () => setStateDialog(() => tempAlta--)),
                  SizedBox(width: 60, child: Text('$tempAlta°C', textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: colorPeligro))),
                  _botonCircular(icono: Icons.add, color: colorPeligro, onTap: () => setStateDialog(() => tempAlta++)),
                ]),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Velocidad del Modo Auto:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _botonVelocidadAuto(1, 'BAJO', velAuto, () => setStateDialog(() => velAuto = 1)),
                    _botonVelocidadAuto(2, 'MEDIO', velAuto, () => setStateDialog(() => velAuto = 2)),
                    _botonVelocidadAuto(3, 'ALTO', velAuto, () => setStateDialog(() => velAuto = 3)),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
              Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: sombraBoton()),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorAzulOscuro, foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onPressed: () {
                    onGuardar(tempBaja, tempAlta, autoActivado, velAuto);
                    Navigator.pop(context);
                  },
                  child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          );
        }
      );
    }
  );
}
