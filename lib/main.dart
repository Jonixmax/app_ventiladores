import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() {
  runApp(const MiAppIot());
}

// --- PALETA DE COLORES KITHER ---
const colorAzulOscuro = Color(0xFF003b5c); // Azul del texto
const colorCeleste = Color(0xFF00b4eb);    // Celeste del personaje
const colorFondo = Color(0xFFF5F7FA);      // Gris muy clarito para el fondo

class MiAppIot extends StatelessWidget {
  const MiAppIot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      title: 'KITHER Ventilación',
      theme: ThemeData(
        scaffoldBackgroundColor: colorFondo,
        primaryColor: colorAzulOscuro,
        colorScheme: const ColorScheme.light(
          primary: colorAzulOscuro,
          secondary: colorCeleste,
        ),
        // Estilo global para los botones
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorAzulOscuro,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // Botones redondeados
            ),
            elevation: 5,
          ),
        ),
      ),
      home: const PantallaSplash(), 
    );
  }
}

// --- 1. PANTALLA SPLASH (ANIMACIÓN DEL LOGO) ---
class PantallaSplash extends StatefulWidget {
  const PantallaSplash({super.key});

  @override
  State createState() { return _PantallaSplashState(); }
}

class _PantallaSplashState extends State with SingleTickerProviderStateMixin {
  late AnimationController _controladorFade;
  late Animation _animacionFade;

  @override
  void initState() {
    super.initState();
    // Animación para que el logo aparezca suavemente
    _controladorFade = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animacionFade = Tween(begin: 0.0, end: 1.0).animate(_controladorFade);

    _controladorFade.forward(); 
    _iniciarApp();
  }

  _iniciarApp() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) { return const PantallaLogin(); }),
      );
    }
  }

  @override
  void dispose() {
    _controladorFade.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _animacionFade as Animation<double>,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Aquí llamamos a tu logo
              Image.asset('assets/logo.png', width: 250),
              const SizedBox(height: 30),
              const CircularProgressIndicator(color: colorCeleste),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. PANTALLA DE LOGIN MODERNA ---
class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State createState() { return _PantallaLoginState(); }
}

class _PantallaLoginState extends State {
  var _controladorUsuario = TextEditingController();
  var _controladorPin = TextEditingController();
  bool _cargandoLogin = false;
  String _mensajeError = '';

  _iniciarSesion() async {
    setState(() {
      _cargandoLogin = true; 
      _mensajeError = '';
    });

    await Future.delayed(const Duration(seconds: 1));
    var usuariosDb = await DatabaseHelper.instance.queryAllRows();
    var usuarioValido = false;
    var rolUsuario = '';

    for (var u in usuariosDb) {
      if (u['nombre'] == _controladorUsuario.text && u['pin'] == _controladorPin.text) {
        usuarioValido = true;
        rolUsuario = u['rol'].toString(); 
        break;
      }
    }

    if (usuarioValido) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) { return DashboardScreen(rol: rolUsuario); },
        ),
      );
    } else {
      setState(() {
        _cargandoLogin = false;
        _mensajeError = 'Usuario o PIN incorrectos.';
      });
    }
  }

  _mostrarDialogoCrear() {
    var controladorNuevoNombre = TextEditingController();
    var controladorNuevoPin = TextEditingController();

    showDialog(
      context: context,
      builder: (context) { 
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Crear Nuevo Usuario', style: TextStyle(color: colorAzulOscuro)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controladorNuevoNombre,
                decoration: const InputDecoration(labelText: 'Nombre de usuario'),
              ),
              TextField(
                controller: controladorNuevoPin,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'PIN (4 números)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(context); },
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controladorNuevoNombre.text.isNotEmpty && controladorNuevoPin.text.isNotEmpty) {
                  await DatabaseHelper.instance.insert({
                    'nombre': controladorNuevoNombre.text,
                    'rol': 'invitado', 
                    'pin': controladorNuevoPin.text
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Usuario creado con éxito'),
                      backgroundColor: colorCeleste,
                    ),
                  );
                }
              },
              child: const Text('Registrar'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              Image.asset('assets/logo.png', width: 200),
              const SizedBox(height: 40),
              
              // Tarjeta blanca para el formulario (Diseño Moderno)
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ]
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _controladorUsuario,
                      decoration: InputDecoration(
                        labelText: 'Usuario',
                        prefixIcon: const Icon(Icons.person_outline, color: colorAzulOscuro),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: colorCeleste, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _controladorPin,
                      keyboardType: TextInputType.number, 
                      obscureText: true, 
                      decoration: InputDecoration(
                        labelText: 'Contraseña (PIN)',
                        prefixIcon: const Icon(Icons.lock_outline, color: colorAzulOscuro),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: colorCeleste, width: 2),
                        ),
                        errorText: _mensajeError.isEmpty ? null : _mensajeError,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _cargandoLogin
                        ? const CircularProgressIndicator(color: colorCeleste) 
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 55), 
                            ),
                            onPressed: _iniciarSesion,
                            child: const Text('INGRESAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _mostrarDialogoCrear,
                child: const Text(
                  '¿No tienes cuenta? Regístrate', 
                  style: TextStyle(color: colorAzulOscuro, fontSize: 15, fontWeight: FontWeight.bold)
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- 3. PANTALLA DEL PANEL DE CONTROL (DASHBOARD) ---
class DashboardScreen extends StatelessWidget {
  final String rol;
  const DashboardScreen({super.key, required this.rol});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KITHER Control'),
        backgroundColor: colorAzulOscuro, 
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (rol == 'admin')
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {},
            )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_customize, size: 80, color: colorCeleste.withOpacity(0.5)),
            const SizedBox(height: 20),
            Text(
              rol == 'admin' ? 'Modo Administrador' : 'Modo Invitado',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorAzulOscuro),
            ),
            const SizedBox(height: 10),
            const Text(
              'Aquí irán los controles de los ventiladores',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}