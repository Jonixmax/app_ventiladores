import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/shadows.dart';
import '../../../data/database_helper.dart';

/// Muestra el diálogo para editar nombre/PIN de un usuario existente.
/// `onGuardado` se llama tras persistir el cambio, para que la pantalla recargue la lista.
void mostrarDialogoEditarUsuario(BuildContext context, Map usuario, {required VoidCallback onGuardado}) {
  var ctrlNombre = TextEditingController(text: usuario['nombre']);
  var ctrlPin = TextEditingController(text: usuario['pin']);
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)), elevation: 12,
        title: Row(children: const [Icon(Icons.edit, color: colorAzulOscuro), SizedBox(width: 10), Text('Editar Usuario', style: TextStyle(color: colorAzulOscuro, fontWeight: FontWeight.bold))]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: ctrlNombre, decoration: InputDecoration(labelText: 'Nombre', filled: true, fillColor: colorFondo, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
          const SizedBox(height: 14),
          TextField(controller: ctrlPin, keyboardType: TextInputType.number, maxLength: 4, decoration: InputDecoration(labelText: 'PIN (4 números)', filled: true, fillColor: colorFondo, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
        ]),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: sombraBoton()),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorAzulOscuro, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
              onPressed: () async {
                if (ctrlNombre.text.isNotEmpty && ctrlPin.text.isNotEmpty) {
                  await DatabaseHelper.instance.update({'id': usuario['id'], 'nombre': ctrlNombre.text, 'rol': usuario['rol'], 'pin': ctrlPin.text});
                  Navigator.pop(context);
                  onGuardado();
                }
              },
              child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      );
    },
  );
}
