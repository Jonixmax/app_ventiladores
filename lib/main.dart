import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async'; // NUEVO IMPORT NECESARIO
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'database_helper.dart';

void main() {
  FlutterBluePlus.setLogLevel(LogLevel.none, color: false);
  runApp(const MiAppIot());
}

// ===================== PALETA DE COLORES =====================
const colorAzulOscuro = Color(0xFF003b5c);
const colorAzulProfundo = Color(0xFF00263d);
const colorCeleste = Color(0xFF00b4eb);
const colorCelesteClaro = Color(0xFF6FE0FF);
const colorFondo = Color(0xFFEFF4F8);
const colorFondoTarjeta = Color(0xFFE1F5FE);
const colorPeligro = Color(0xFFE53950);
const colorExito = Color(0xFF17B978);

// Gradiente principal usado en fondos y botones destacados
const gradientePrincipal = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [colorAzulProfundo, colorAzulOscuro],
);

const gradienteCeleste = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [colorCelesteClaro, colorCeleste],
);

// Sombra "flotante" reutilizable en tarjetas (estilo 2D con profundidad)
List<BoxShadow> sombraTarjeta({double intensidad = 1.0}) => [
      BoxShadow(
        color: colorAzulOscuro.withOpacity(0.10 * intensidad),
        blurRadius: 20,
        spreadRadius: 0,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.04 * intensidad),
        blurRadius: 4,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ];

// Sombra tipo "botón elevado" (más marcada, para CTAs)
List<BoxShadow> sombraBoton({Color color = colorAzulOscuro}) => [
      BoxShadow(
        color: color.withOpacity(0.35),
        blurRadius: 16,
        spreadRadius: -2,
        offset: const Offset(0, 8),
      ),
    ];

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
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.light(primary: colorAzulOscuro, secondary: colorCeleste),
      ),
      home: const PantallaSplash(),
    );
  }
}

// --- 1. PANTALLA SPLASH ---
class PantallaSplash extends StatefulWidget {
  const PantallaSplash({super.key});
  @override
  State createState() { return _PantallaSplashState(); }
}

class _PantallaSplashState extends State with TickerProviderStateMixin{
  late AnimationController _controladorFade;
  late Animation _animacionFade;
  late AnimationController _controladorEscala;
  late Animation<double> _animacionEscala;

  @override
  void initState() {
    super.initState();
    _controladorFade = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animacionFade = Tween(begin: 0.0, end: 1.0).animate(_controladorFade);
    _controladorEscala = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _animacionEscala = CurvedAnimation(parent: _controladorEscala, curve: Curves.elasticOut);
    _controladorFade.forward();
    _controladorEscala.forward();
    _iniciarApp();
  }

  _iniciarApp() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) { return const PantallaLogin(); }));
  }

  @override
  void dispose() { _controladorFade.dispose(); _controladorEscala.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: gradientePrincipal),
        child: Center(
          child: FadeTransition(
            opacity: _animacionFade as Animation<double>,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _animacionEscala,
                  child: Container(
                    width: 150, 
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: colorCeleste.withOpacity(0.45), blurRadius: 40, spreadRadius: 4),
                        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: ClipOval(
                      child: Transform.scale(
                        scale: 1.6, // El zoom que ya teníamos
                        child: Transform.translate(
                          // Offset(Derecha/Izquierda, Abajo/Arriba)
                          // Positivo mueve a la derecha y abajo. Negativo a la izquierda y arriba.
                          offset: const Offset(5, 10), 
                          child: Image.asset('assets/kiro_feliz.png', fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text('KITHER', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 6)),
                const SizedBox(height: 4),
                Text('VENTILACIÓN INTELIGENTE', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 3)),
                const SizedBox(height: 36),
                SizedBox(
                  width: 32, height: 32,
                  child: CircularProgressIndicator(color: colorCeleste, strokeWidth: 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- 2. PANTALLA DE LOGIN ---
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

  _mostrarDialogoCrear() {
    var ctrlNombre = TextEditingController();
    var ctrlPin = TextEditingController();
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
              TextField(controller: ctrlNombre, decoration: _decoracionCampo(label: 'Nombre de usuario', icono: Icons.badge_outlined)),
              const SizedBox(height: 14),
              TextField(controller: ctrlPin, keyboardType: TextInputType.number, maxLength: 4, obscureText: true, decoration: _decoracionCampo(label: 'PIN (4 números)', icono: Icons.password)),
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
                    
                    // --- NUEVA LÓGICA: VERIFICAR LÍMITE DE 6 USUARIOS ---
                    var usuariosDb = await DatabaseHelper.instance.queryAllRows();
                    if (usuariosDb.length >= 6) {
                      Navigator.pop(context); // Cierra el diálogo
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text('Error: Límite máximo de 6 usuarios alcanzado'),
                        backgroundColor: colorPeligro,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ));
                      return; // Detiene el proceso de registro
                    }

                    // --- CAMBIO DE ROL: AHORA SE REGISTRAN COMO 'usuario' ---
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
                  TextButton(onPressed: _mostrarDialogoCrear, child: const Text('¿No tienes cuenta? Regístrate', style: TextStyle(color: colorAzulOscuro, fontSize: 15, fontWeight: FontWeight.bold)))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 3. PANTALLA DEL DASHBOARD INTERACTIVO ---
class DashboardScreen extends StatefulWidget {
  final String rol;
  final String nombre;
  const DashboardScreen({super.key, required this.rol, required this.nombre});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _temperaturaActual = 0.0;
  double _humedadActual = 0.0;
  bool _conectadoBluetooth = false;
  bool _modoAuto = false;
  String _tiempoSeleccionado = '';
  List<double> _velocidadVentiladores = [0.0, 0.0, 0.0, 0.0, 0.0];
  int _tempMin = 20;
  int _tempMax = 28;
  int _velocidadAuto = 3;

  // NUEVAS VARIABLES PARA EL CRONÓMETRO VISUAL
  Timer? _timerCuentaRegresiva;
  int _segundosRestantes = 0;

  BluetoothDevice? _dispositivoESP32;
  BluetoothCharacteristic? _caracteristicaTx;
  BluetoothCharacteristic? _caracteristicaRx;

  final String servicioUUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  final String rxUUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
  final String txUUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";

  @override
  void dispose() {
    _timerCuentaRegresiva?.cancel(); // APAGA EL RELOJ
    _dispositivoESP32?.disconnect();
    super.dispose();
  }

  Color _obtenerColorTemperatura(double temp) {
    if (temp == 0.0) return colorAzulOscuro;
    if (temp >= 28.0) return Colors.lightBlue.shade200;
    if (temp >= 25.0) return Colors.lightBlue;
    if (temp >= 22.0) return Colors.blue.shade700;
    return const Color(0xFF003893);
  }

  void _iniciarTemporizador(int minutos) {
    _timerCuentaRegresiva?.cancel(); // Cancela cualquier temporizador anterior

    if (minutos == 0) {
      setState(() { _tiempoSeleccionado = ''; _segundosRestantes = 0; });
      _enviarComando("TIME:0");
      return;
    }

    setState(() { _segundosRestantes = minutos * 60; });
    _enviarComando("TIME:$minutos");

    _timerCuentaRegresiva = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segundosRestantes > 0) {
        setState(() {
          _segundosRestantes--;
          int m = _segundosRestantes ~/ 60;
          int s = _segundosRestantes % 60;
          _tiempoSeleccionado = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
        });
      } else {
        timer.cancel();
        
        // Apagar modo auto si está activado
        if (_modoAuto) {
          _enviarComando("AUTO:0:$_tempMin:$_tempMax");
        }
        
        // Apagar todos los ventiladores
        for (int i = 0; i < _velocidadVentiladores.length; i++) {
          if (_velocidadVentiladores[i] > 0) {
            _enviarComando("V${i + 1}:0");
          }
        }

        setState(() {
          _tiempoSeleccionado = '';
          _modoAuto = false;
          _velocidadVentiladores = [0.0, 0.0, 0.0, 0.0, 0.0];
        });
      }
    });
  }

  void _conectarBluetooth() async {
    if (_conectadoBluetooth) {
      await _dispositivoESP32?.disconnect();
      setState(() { _conectadoBluetooth = false; _temperaturaActual = 0.0; _humedadActual = 0.0; });
      return;
    }

    Map<Permission, PermissionStatus> permisos = await [
      Permission.bluetooth, Permission.bluetoothScan, Permission.bluetoothConnect, Permission.location
    ].request();

    if (permisos.values.any((status) => status.isDenied)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Debes aceptar los permisos para usar Bluetooth'),
        backgroundColor: colorPeligro,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Buscando KITHER...'),
      backgroundColor: colorAzulOscuro,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.platformName == "KITHER") {
          FlutterBluePlus.stopScan();
          _dispositivoESP32 = r.device;

          await _dispositivoESP32!.connect();

          List<BluetoothService> servicios = await _dispositivoESP32!.discoverServices();
          for (BluetoothService servicio in servicios) {
            if (servicio.uuid.toString().toUpperCase() == servicioUUID) {
              for (BluetoothCharacteristic c in servicio.characteristics) {
                if (c.uuid.toString().toUpperCase() == txUUID) _caracteristicaTx = c;
                if (c.uuid.toString().toUpperCase() == rxUUID) {
                  _caracteristicaRx = c;
                  await _caracteristicaRx!.setNotifyValue(true);

                  _caracteristicaRx!.lastValueStream.listen((value) {
                    if(value.isNotEmpty) {
                      String datoRecibido = utf8.decode(value);
                      if(datoRecibido.startsWith("T:")) {
                        try {
                          List<String> partes = datoRecibido.split('|');
                          String tempStr = partes[0].replaceAll('T:', '');
                          String humStr = partes[1].replaceAll('H:', '');

                          setState(() {
                            _temperaturaActual = double.parse(tempStr);
                            _humedadActual = double.parse(humStr);
                          });
                        } catch (e) {
                          print("Error leyendo sensores: $e");
                        }
                      }
                    }
                  });
                }
              }
            }
          }
          setState(() { _conectadoBluetooth = true; });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('¡Conectado exitosamente!'),
            backgroundColor: colorExito,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
          break;
        }
      }
    });
  }

  void _enviarComando(String comando) async {
    if (_conectadoBluetooth && _caracteristicaTx != null) {
      await _caracteristicaTx!.write(utf8.encode(comando));
      print("Enviado a ESP32: $comando");
    }
  }

void _mostrarAjustesAuto() {
    showDialog(
      context: context,
      builder: (context) {
        int tempBaja = _tempMin; int tempAlta = _tempMax; bool autoActivado = _modoAuto; int velAuto = _velocidadAuto;
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
                  // NUEVO: Selector de velocidad para el Modo Automático
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
                      setState(() { _tempMin = tempBaja; _tempMax = tempAlta; _modoAuto = autoActivado; _velocidadAuto = velAuto; });
                      // AHORA EL COMANDO INCLUYE LA VELOCIDAD AL FINAL (ej. AUTO:1:20:28:3)
                      _enviarComando("AUTO:${autoActivado ? '1' : '0'}:$tempBaja:$tempAlta:$_velocidadAuto");
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

  // Widget auxiliar para los botones de velocidad
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

void _mostrarMenuTiempo() {
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
                  _opcionTiempo(icono: Icons.access_time, texto: '15 Minutos', onTap: () { _iniciarTemporizador(15); Navigator.pop(context); }),
                  const SizedBox(height: 10),
                  _opcionTiempo(icono: Icons.timer, texto: '1 Hora', onTap: () { _iniciarTemporizador(60); Navigator.pop(context); }),
                  const SizedBox(height: 10),
                  _opcionTiempo(icono: Icons.edit_note, texto: 'Personalizar...', onTap: () { _mostrarDialogoTiempoPersonalizado(); }),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 4),
                  _opcionTiempo(icono: Icons.cancel, texto: 'Desactivar Temporizador', colorTexto: colorPeligro, onTap: () { _iniciarTemporizador(0); Navigator.pop(context); }),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  void _mostrarDialogoTiempoPersonalizado() {
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
                    _iniciarTemporizador(minutos); // USAMOS LA NUEVA FUNCIÓN
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: sombraTarjeta()),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.nombre.toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colorAzulOscuro, letterSpacing: 0.5), overflow: TextOverflow.ellipsis, maxLines: 1),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: colorFondoTarjeta, borderRadius: BorderRadius.circular(8)),
                        child: Text('ROL: ${widget.rol.toUpperCase()}', style: const TextStyle(fontSize: 11, color: colorAzulOscuro, fontWeight: FontWeight.bold)),
                      ),
                    ])),
                    const SizedBox(width: 10),
                    Container(
                      width: 86,
                      height: 86,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradienteCeleste, boxShadow: [BoxShadow(color: colorCeleste.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
                      child: Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        child: ClipOval(
                          child: Transform.scale(
                            scale: 1.5, // Zoom para Kiro asombrado
                            child: Image.asset('assets/kiro_asombrado.png', fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colorFondoTarjeta, colorFondoTarjeta.withOpacity(0.5)]),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: sombraTarjeta(intensidad: 1.2),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('$_temperaturaActual', style: TextStyle(fontSize: 58, fontWeight: FontWeight.w800, color: _obtenerColorTemperatura(_temperaturaActual), height: 1)),
                              Padding(padding: const EdgeInsets.only(top: 10), child: Text('°C', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _obtenerColorTemperatura(_temperaturaActual)))),
                            ]),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))]),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.water_drop, color: colorCeleste, size: 18),
                                const SizedBox(width: 5),
                                Text('Humedad: $_humedadActual%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorCeleste)),
                              ]),
                            )
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: sombraBoton(color: _conectadoBluetooth ? colorExito : colorAzulOscuro)),
                          child: ElevatedButton(
                            onPressed: _conectarBluetooth,
                            style: ElevatedButton.styleFrom(shape: const CircleBorder(), backgroundColor: _conectadoBluetooth ? colorExito : colorAzulOscuro, foregroundColor: Colors.white, padding: const EdgeInsets.all(20), elevation: 0),
                            child: Icon(_conectadoBluetooth ? Icons.bluetooth_connected : Icons.bluetooth_searching, size: 32),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: _conectadoBluetooth ? colorExito : Colors.grey, boxShadow: _conectadoBluetooth ? [BoxShadow(color: colorExito.withOpacity(0.6), blurRadius: 6, spreadRadius: 1)] : [])),
                          const SizedBox(width: 8),
                          Text(_conectadoBluetooth ? 'SISTEMA CONECTADO' : 'ESPERANDO CONEXIÓN...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _conectadoBluetooth ? colorExito : colorAzulOscuro, letterSpacing: 0.5))
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 26),

              if (_modoAuto)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: colorPeligro.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                  child: const Row(children: [
                    Icon(Icons.info_outline, color: colorPeligro, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text('Desactiva el Modo Auto para control manual', style: TextStyle(color: colorPeligro, fontSize: 12, fontWeight: FontWeight.w600))),
                  ]),
                ),

              Container(
                decoration: BoxDecoration(gradient: gradientePrincipal, borderRadius: BorderRadius.circular(22), boxShadow: sombraBoton()),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) {
                      return PantallaVentiladores(
                        velocidades: _velocidadVentiladores,
                        modoAuto: _modoAuto,
                        onCambioVelocidad: (numeroVentilador, nuevaVelocidad) {
                          setState(() { _velocidadVentiladores[numeroVentilador - 1] = nuevaVelocidad; });
                          _enviarComando("V$numeroVentilador:${nuevaVelocidad.toInt()}");
                        }
                      );
                    }));
                  },
                  icon: const Icon(Icons.grid_view_rounded),
                  label: const Text('GESTIONAR VENTILADORES', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 68),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)), elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _tarjetaAccion(
                      onTap: _mostrarAjustesAuto,
                      colorFondo: _modoAuto ? colorAzulOscuro : Colors.white,
                      icono: Icons.autorenew,
                      colorIcono: _modoAuto ? Colors.white : colorAzulOscuro,
                      titulo: 'MODO AUTO',
                      colorTitulo: _modoAuto ? Colors.white : colorAzulOscuro,
                      subtitulo: _modoAuto ? '$_tempMin° - $_tempMax°' : null,
                      colorSubtitulo: colorCeleste,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _tarjetaAccion(
                      onTap: _mostrarMenuTiempo,
                      gradiente: gradienteCeleste,
                      icono: Icons.timer,
                      colorIcono: Colors.white,
                      titulo: 'TIEMPO',
                      colorTitulo: Colors.white,
                      subtitulo: _tiempoSeleccionado.isNotEmpty ? _tiempoSeleccionado : null,
                      colorSubtitulo: colorAzulOscuro,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _tarjetaAccion(
                      onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) { return PantallaAjustes(rol: widget.rol); })); },
                      gradiente: gradientePrincipal,
                      icono: Icons.settings,
                      colorIcono: Colors.white,
                      titulo: 'PERFILES',
                      colorTitulo: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaAccion({
    required VoidCallback onTap,
    required IconData icono,
    required Color colorIcono,
    required String titulo,
    required Color colorTitulo,
    Color? colorFondo,
    Gradient? gradiente,
    String? subtitulo,
    Color colorSubtitulo = Colors.grey,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 104,
        decoration: BoxDecoration(
          color: gradiente == null ? colorFondo : null,
          gradient: gradiente,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: (colorFondo ?? colorAzulOscuro).withOpacity(0.18), blurRadius: 14, offset: const Offset(0, 6))],
          border: colorFondo == Colors.white ? Border.all(color: colorAzulOscuro.withOpacity(0.15), width: 1.5) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 32, color: colorIcono),
            const SizedBox(height: 6),
            Text(titulo, style: TextStyle(color: colorTitulo, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
            if (subtitulo != null) ...[
              const SizedBox(height: 2),
              Text(subtitulo, style: TextStyle(color: colorSubtitulo, fontSize: 11, fontWeight: FontWeight.w600)),
            ]
          ],
        ),
      ),
    );
  }
}

// --- 4. NUEVA PANTALLA: CONTROL DE 5 VENTILADORES ---
class PantallaVentiladores extends StatefulWidget {
  final List<double> velocidades;
  final bool modoAuto;
  final Function(int, double) onCambioVelocidad;

  const PantallaVentiladores({super.key, required this.velocidades, required this.modoAuto, required this.onCambioVelocidad});

  @override
  State<PantallaVentiladores> createState() => _PantallaVentiladoresState();
}

class _PantallaVentiladoresState extends State<PantallaVentiladores> {

  Widget _tarjetaVentiladorIndividual(int numero) {
    double velocidadActual = widget.velocidades[numero - 1];
    String textoVelocidad = 'APAGADO'; Color colorIcono = Colors.grey;
    if (velocidadActual == 1) { textoVelocidad = 'BAJO'; colorIcono = Colors.lightBlue; }
    if (velocidadActual == 2) { textoVelocidad = 'MEDIO'; colorIcono = colorCeleste; }
    if (velocidadActual == 3) { textoVelocidad = 'ALTO'; colorIcono = const Color.fromARGB(255, 45, 86, 219); }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: sombraTarjeta(intensidad: velocidadActual > 0 ? 1.3 : 0.7),
        border: Border.all(color: velocidadActual > 0 ? colorCeleste.withOpacity(0.5) : Colors.grey.withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: colorIcono.withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(velocidadActual > 0 ? Icons.wind_power : Icons.wind_power_outlined, color: colorIcono, size: 26),
                ),
                const SizedBox(width: 15),
                Text('Ventilador $numero', style: const TextStyle(fontWeight: FontWeight.bold, color: colorAzulOscuro, fontSize: 17)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: colorIcono.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(textoVelocidad, style: TextStyle(color: colorIcono, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colorCeleste,
              inactiveTrackColor: Colors.grey.withOpacity(0.15),
              thumbColor: colorAzulOscuro,
              overlayColor: colorCeleste.withOpacity(0.15),
              trackHeight: 8.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
            ),
            child: Slider(
              value: velocidadActual, min: 0, max: 3, divisions: 3,
              onChanged: widget.modoAuto ? null : (nuevoValor) {
                setState(() {});
                widget.onCambioVelocidad(numero, nuevoValor);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        title: const Text('Control Individual', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: gradientePrincipal)),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.modoAuto)
              Container(
                margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: colorPeligro.withOpacity(0.1), borderRadius: BorderRadius.circular(18), boxShadow: sombraTarjeta(intensidad: 0.5)),
                child: const Row(children: [Icon(Icons.warning_amber_rounded, color: colorPeligro), SizedBox(width: 10), Expanded(child: Text('Modo Automático Activado. Controles manuales bloqueados.', style: TextStyle(color: colorPeligro, fontWeight: FontWeight.bold)))]),
              )
            else
              Padding(padding: const EdgeInsets.only(bottom: 20, left: 4), child: Text('Desliza la barra para ajustar la velocidad de cada motor.', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500))),

            _tarjetaVentiladorIndividual(1),
            _tarjetaVentiladorIndividual(2),
            _tarjetaVentiladorIndividual(3),
            _tarjetaVentiladorIndividual(4),
            _tarjetaVentiladorIndividual(5),
          ],
        ),
      ),
    );
  }
}

// --- 5. PANTALLA DE AJUSTES ---
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

  _mostrarDialogoEditar(Map usuario) {
    var ctrlNombre = TextEditingController(text: usuario['nombre']); var ctrlPin = TextEditingController(text: usuario['pin']);
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
                    Navigator.pop(context); _cargarUsuarios();
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
      body: Column(
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
                        IconButton(icon: const Icon(Icons.edit, color: colorCeleste), onPressed: () { _mostrarDialogoEditar(usuario); }),
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
              
              // --- CAMBIADO DE 'Modo Invitado' A 'Modo Usuario' ---
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
    );
  }
}