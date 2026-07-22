import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/gradients.dart';
import '../../core/theme/shadows.dart';
import '../../data/database_helper.dart';
import '../dashboard/dashboard_screen.dart';
import 'widgets/crear_usuario_dialog.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});
  @override
  State createState() { return _PantallaLoginState(); }
}

class _PantallaLoginState extends State<PantallaLogin> {
  var _controladorUsuario = TextEditingController();
  var _controladorPin = TextEditingController();
  bool _cargandoLogin = false;
  String _mensajeError = '';

  InputDecoration _decoracionCampo({required String label, required IconData icono, String? error}) {
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
      errorText: error,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: colorCeleste, width: 2)),
    );
  }

  _iniciarSesion() async {
    setState(() { _cargandoLogin = true; _mensajeError = ''; });
    await Future.delayed(const Duration(seconds: 1));
    var usuariosDb = await DatabaseHelper.instance.queryAllRows();
    var usuarioValido = false;
    var rolUsuario = '';
    var nombreUsuario = '';

    for (var u in usuariosDb) {
      if (u['nombre'] == _controladorUsuario.text && u['pin'] == _controladorPin.text) {
        usuarioValido = true; rolUsuario = u['rol'].toString(); nombreUsuario = u['nombre'].toString(); break;
      }
    }

    if (usuarioValido) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) { return DashboardScreen(rol: rolUsuario, nombre: nombreUsuario); }));
    } else {
      setState(() { _cargandoLogin = false; _mensajeError = 'Usuario o PIN incorrectos.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo curvo superior con gradiente
          Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: gradientePrincipal,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Image.asset('assets/logo.png', width: 130),
                  ),
                  const SizedBox(height: 45),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: sombraTarjeta(intensidad: 1.4),
                    ),
                    child: Column(
                      children: [
                        const Align(alignment: Alignment.centerLeft, child: Text('Bienvenido', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colorAzulOscuro))),
                        const SizedBox(height: 4),
                        Align(alignment: Alignment.centerLeft, child: Text('Ingresa tus datos para continuar', style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
                        const SizedBox(height: 24),
                        TextField(controller: _controladorUsuario, decoration: _decoracionCampo(label: 'Usuario', icono: Icons.person_outline)),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _controladorPin, keyboardType: TextInputType.number, obscureText: true,
                          decoration: _decoracionCampo(label: 'Contraseña (PIN)', icono: Icons.lock_outline, error: _mensajeError.isEmpty ? null : _mensajeError),
                        ),
                        const SizedBox(height: 30),
                        _cargandoLogin
                            ? const CircularProgressIndicator(color: colorCeleste)
                            : Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: gradientePrincipal,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: sombraBoton(),
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white, elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    minimumSize: const Size(double.infinity, 55),
                                  ),
                                  onPressed: _iniciarSesion,
                                  child: const Text('INGRESAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextButton(onPressed: () => mostrarDialogoCrearUsuario(context), child: const Text('¿No tienes cuenta? Regístrate', style: TextStyle(color: colorAzulOscuro, fontSize: 15, fontWeight: FontWeight.bold)))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
