import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/shadows.dart';
import '../../../data/database_helper.dart';

/// Muestra el diálogo de "Crear nuevo usuario" (máx. 6 usuarios, rol fijo 'usuario').
void mostrarDialogoCrearUsuario(BuildContext context) {
  var ctrlNombre = TextEditingController();
  var ctrlPin = TextEditingController();

  InputDecoration decoracionCampo({required String label, required IconData icono}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
      prefixIcon: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: colorFondoTarjeta, borderRadius: BorderRadius.circular(10)),
        child: Icon(icono, color: colorAzulOscuro, size: 20),
      ),
      filled: true,
      fillColor: colorFondo,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: colorCeleste, width: 2)),
    );
  }

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 12,
        title: Row(children: const [
          Icon(Icons.person_add_alt_1, color: colorAzulOscuro),
          SizedBox(width: 10),
          Text('Crear Nuevo Usuario', style: TextStyle(color: colorAzulOscuro, fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: ctrlNombre, decoration: decoracionCampo(label: 'Nombre de usuario', icono: Icons.badge_outlined)),
            const SizedBox(height: 14),
            TextField(controller: ctrlPin, keyboardType: TextInputType.number, maxLength: 4, obscureText: true, decoration: decoracionCampo(label: 'PIN (4 números)', icono: Icons.password)),
          ],
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: sombraBoton()),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorAzulOscuro, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onPressed: () async {
                if (ctrlNombre.text.isNotEmpty && ctrlPin.text.isNotEmpty) {
                  // --- LÍMITE DE 6 USUARIOS ---
                  var usuariosDb = await DatabaseHelper.instance.queryAllRows();
                  if (usuariosDb.length >= 6) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Error: Límite máximo de 6 usuarios alcanzado'),
                      backgroundColor: colorPeligro,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                    return;
                  }

                  // Los usuarios que se autoregistran siempre entran como 'usuario' (no admin).
                  await DatabaseHelper.instance.insert({'nombre': ctrlNombre.text, 'rol': 'usuario', 'pin': ctrlPin.text});
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Usuario creado con éxito'),
                    backgroundColor: colorExito,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                }
              },
              child: const Text('Registrar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      );
    },
  );
}
