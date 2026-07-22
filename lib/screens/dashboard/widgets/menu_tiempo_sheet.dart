import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/shadows.dart';

Widget _opcionTiempo({required IconData icono, required String texto, required VoidCallback onTap, Color colorTexto = colorAzulOscuro}) {
  return Material(
    color: colorFondo,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icono, color: colorTexto),
          const SizedBox(width: 14),
          Text(texto, style: TextStyle(color: colorTexto, fontWeight: FontWeight.w600, fontSize: 15)),
        ]),
      ),
    ),
  );
}

void _mostrarDialogoTiempoPersonalizado(BuildContext context, void Function(int minutos) onSeleccionar) {
  TextEditingController controladorMinutos = TextEditingController();

  showDialog(
    context: context,
    builder: (contextDialog) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 12,
        title: Row(children: const [
          Icon(Icons.timer_outlined, color: colorAzulOscuro),
          SizedBox(width: 10),
          Text('Tiempo Personalizado', style: TextStyle(color: colorAzulOscuro, fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        content: TextField(
          controller: controladorMinutos,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Minutos',
            filled: true,
            fillColor: colorFondo,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextDialog),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))
          ),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: sombraBoton()),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorAzulOscuro,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)
              ),
              onPressed: () {
                int? minutos = int.tryParse(controladorMinutos.text);
                if (minutos != null && minutos > 0) {
                  onSeleccionar(minutos);
                  Navigator.pop(contextDialog);
                  Navigator.pop(context);
                }
              },
              child: const Text('Iniciar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      );
    }
  );
}

/// Muestra la hoja inferior para elegir en cuánto tiempo se apagan los ventiladores.
/// `onSeleccionar` recibe los minutos elegidos (0 = desactivar temporizador).
void mostrarMenuTiempo(BuildContext context, {required void Function(int minutos) onSeleccionar}) {
  showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 45, height: 5, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                const Align(alignment: Alignment.centerLeft, child: Text('Apagar ventiladores en:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorAzulOscuro))),
                const SizedBox(height: 14),
                _opcionTiempo(icono: Icons.access_time, texto: '15 Minutos', onTap: () { onSeleccionar(15); Navigator.pop(context); }),
                const SizedBox(height: 10),
                _opcionTiempo(icono: Icons.timer, texto: '1 Hora', onTap: () { onSeleccionar(60); Navigator.pop(context); }),
                const SizedBox(height: 10),
                _opcionTiempo(icono: Icons.edit_note, texto: 'Personalizar...', onTap: () { _mostrarDialogoTiempoPersonalizado(context, onSeleccionar); }),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 4),
                _opcionTiempo(icono: Icons.cancel, texto: 'Desactivar Temporizador', colorTexto: colorPeligro, onTap: () { onSeleccionar(0); Navigator.pop(context); }),
              ],
            ),
          ),
        ),
      );
    }
  );
}
