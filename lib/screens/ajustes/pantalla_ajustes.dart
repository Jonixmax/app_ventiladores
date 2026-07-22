import 'package:flutter/material.dart';
import '../../assistant/widgets/kiro_fab.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/gradients.dart';
import '../../core/theme/shadows.dart';
import '../../data/database_helper.dart';
import '../login/login_screen.dart';
import 'widgets/editar_usuario_dialog.dart';

class PantallaAjustes extends StatefulWidget {
  final String rol;
  const PantallaAjustes({super.key, required this.rol});
  @override
  State<PantallaAjustes> createState() => _PantallaAjustesState();
}

class _PantallaAjustesState extends State<PantallaAjustes> {
  var _usuarios = [];

  @override
  void initState() { super.initState(); if (widget.rol == 'admin') { _cargarUsuarios(); } }

  _cargarUsuarios() async { var dbUsers = await DatabaseHelper.instance.queryAllRows(); setState(() { _usuarios = dbUsers; }); }

  _cerrarSesion() { Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) { return const PantallaLogin(); }), (route) => false); }

  _borrarUsuario(int id, String rolUsuario) async {
    if (rolUsuario == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('No puedes borrar al Administrador'), backgroundColor: colorPeligro, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      return;
    }
    await DatabaseHelper.instance.delete(id); _cargarUsuarios();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        title: const Text('Ajustes', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: gradientePrincipal)),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Stack(
        children: [
          Column(
        children: [
          const SizedBox(height: 20),

          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: sombraTarjeta()),
            child: ClipOval(
              child: Transform.scale(
                scale: 1.6, // Zoom para Kiro triste
                child: Image.asset('assets/kiro_triste.png', fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (widget.rol == 'admin') ...[
            const Padding(padding: EdgeInsets.symmetric(horizontal: 22), child: Align(alignment: Alignment.centerLeft, child: Text('Gestión de Usuarios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorAzulOscuro)))),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _usuarios.length,
                itemBuilder: (context, index) {
                  var usuario = _usuarios[index];
                  bool esAdmin = usuario['rol'] == 'admin';
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: sombraTarjeta(intensidad: 0.8)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        decoration: BoxDecoration(shape: BoxShape.circle, gradient: esAdmin ? gradientePrincipal : LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500])),
                        child: CircleAvatar(backgroundColor: Colors.transparent, child: Icon(esAdmin ? Icons.admin_panel_settings : Icons.person, color: Colors.white)),
                      ),
                      title: Text(usuario['nombre'], style: const TextStyle(fontWeight: FontWeight.bold, color: colorAzulOscuro)),
                      subtitle: Text('Rol: ${usuario['rol']}', style: TextStyle(color: Colors.grey.shade600)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.edit, color: colorCeleste), onPressed: () { mostrarDialogoEditarUsuario(context, usuario, onGuardado: _cargarUsuarios); }),
                        IconButton(icon: const Icon(Icons.delete, color: colorPeligro), onPressed: () { _borrarUsuario(usuario['id'], usuario['rol']); }),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: sombraTarjeta()), child: Icon(Icons.shield_outlined, size: 60, color: Colors.grey.withOpacity(0.5))),
              const SizedBox(height: 18),
              const Text('Modo Usuario', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorAzulOscuro)),
              const SizedBox(height: 6),
              const Text('No tienes permisos para\neditar o borrar usuarios.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))
            ])) )
          ],
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), boxShadow: sombraBoton(color: colorPeligro)),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout), label: const Text('CERRAR SESIÓN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                style: ElevatedButton.styleFrom(backgroundColor: colorPeligro, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 0),
                onPressed: _cerrarSesion,
              ),
            ),
          ),
        ],
          ),
          const KiroTab(),
        ],
      ),
    );
  }
}
