import 'package:flutter/material.dart';
import 'dart:convert'; // Para convertir texto a bytes de Bluetooth
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'database_helper.dart';

void main() {
  // Inicialización de Flutter Blue Plus
  FlutterBluePlus.setLogLevel(LogLevel.none, color: false);
  runApp(const MiAppIot());
}

const colorAzulOscuro = Color(0xFF003b5c); 
const colorCeleste = Color(0xFF00b4eb);    
const colorFondo = Color(0xFFF5F7FA);      
const colorFondoTarjeta = Color(0xFFE1F5FE); 

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

class _PantallaSplashState extends State with SingleTickerProviderStateMixin {
  late AnimationController _controladorFade;
  late Animation _animacionFade;

  @override
  void initState() {
    super.initState();
    _controladorFade = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animacionFade = Tween(begin: 0.0, end: 1.0).animate(_controladorFade);
    _controladorFade.forward(); 
    _iniciarApp();
  }

  _iniciarApp() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) { return const PantallaLogin(); }));
  }

  @override
  void dispose() { _controladorFade.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _animacionFade as Animation<double>,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Crear Nuevo Usuario', style: TextStyle(color: colorAzulOscuro)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: ctrlNombre, decoration: const InputDecoration(labelText: 'Nombre de usuario')),
              TextField(controller: ctrlPin, keyboardType: TextInputType.number, maxLength: 4, obscureText: true, decoration: const InputDecoration(labelText: 'PIN (4 números)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorAzulOscuro, foregroundColor: Colors.white),
              onPressed: () async {
                if (ctrlNombre.text.isNotEmpty && ctrlPin.text.isNotEmpty) {
                  await DatabaseHelper.instance.insert({'nombre': ctrlNombre.text, 'rol': 'invitado', 'pin': ctrlPin.text});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario creado con éxito'), backgroundColor: colorCeleste));
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
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]),
                child: Column(
                  children: [
                    TextField(
                      controller: _controladorUsuario,
                      decoration: InputDecoration(labelText: 'Usuario', prefixIcon: const Icon(Icons.person_outline, color: colorAzulOscuro), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: colorCeleste, width: 2))),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _controladorPin, keyboardType: TextInputType.number, obscureText: true, 
                      decoration: InputDecoration(labelText: 'Contraseña (PIN)', prefixIcon: const Icon(Icons.lock_outline, color: colorAzulOscuro), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: colorCeleste, width: 2)), errorText: _mensajeError.isEmpty ? null : _mensajeError),
                    ),
                    const SizedBox(height: 30),
                    _cargandoLogin
                        ? const CircularProgressIndicator(color: colorCeleste) 
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: colorAzulOscuro, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), minimumSize: const Size(double.infinity, 55)),
                            onPressed: _iniciarSesion, child: const Text('INGRESAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextButton(onPressed: _mostrarDialogoCrear, child: const Text('¿No tienes cuenta? Regístrate', style: TextStyle(color: colorAzulOscuro, fontSize: 15, fontWeight: FontWeight.bold)))
            ],
          ),
        ),
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
  State createState() { return _DashboardScreenState(rol, nombre); }
}

class _DashboardScreenState extends State {
  final String rol;
  final String nombre;
  _DashboardScreenState(this.rol, this.nombre);

  int _temperaturaActual = 0; 
  bool _conectadoBluetooth = false; 
  bool _modoAuto = false;
  String _tiempoSeleccionado = ''; 
  
  double _velVent1 = 0;
  double _velVent2 = 0;
  int _tempMin = 20;
  int _tempMax = 28;

  // --- VARIABLES DE BLUETOOTH ---
  BluetoothDevice? _dispositivoESP32;
  BluetoothCharacteristic? _caracteristicaTx; // Para enviar comandos al ESP32
  BluetoothCharacteristic? _caracteristicaRx; // Para recibir temperatura del ESP32
  
  // UUIDs estándar de Comunicación Serie por Bluetooth (UART)
  final String servicioUUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  final String rxUUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; // App recibe
  final String txUUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"; // App envía

  @override
  void dispose() {
    _dispositivoESP32?.disconnect();
    super.dispose();
  }

  // --- FUNCIÓN PARA PEDIR PERMISOS Y CONECTAR ---
  void _conectarBluetooth() async {
    if (_conectadoBluetooth) {
      await _dispositivoESP32?.disconnect();
      setState(() { _conectadoBluetooth = false; _temperaturaActual = 0; });
      return;
    }

    // Pedimos permisos de Bluetooth y Ubicación a Android
    Map<Permission, PermissionStatus> permisos = await [
      Permission.bluetooth, Permission.bluetoothScan, Permission.bluetoothConnect, Permission.location
    ].request();

    if (permisos.values.any((status) => status.isDenied)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes aceptar los permisos para usar Bluetooth')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buscando KITHER...'), backgroundColor: colorAzulOscuro, duration: Duration(seconds: 2)));

    // Iniciar escaneo real
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.platformName == "KITHER") { // Buscaremos un dispositivo llamado "KITHER"
          FlutterBluePlus.stopScan();
          _dispositivoESP32 = r.device;
          
          await _dispositivoESP32!.connect();
          
          // Buscar los canales (Servicios y Características)
          List<BluetoothService> servicios = await _dispositivoESP32!.discoverServices();
          for (BluetoothService servicio in servicios) {
            if (servicio.uuid.toString().toUpperCase() == servicioUUID) {
              for (BluetoothCharacteristic c in servicio.characteristics) {
                if (c.uuid.toString().toUpperCase() == txUUID) _caracteristicaTx = c;
                if (c.uuid.toString().toUpperCase() == rxUUID) {
                  _caracteristicaRx = c;
                  // Activar notificaciones para recibir la temperatura en vivo
                  await _caracteristicaRx!.setNotifyValue(true);
                  _caracteristicaRx!.lastValueStream.listen((value) {
                    if(value.isNotEmpty) {
                      String datoRecibido = utf8.decode(value);
                      if(datoRecibido.startsWith("T:")) { // Esperamos recibir algo como "T:25"
                        setState(() { _temperaturaActual = int.tryParse(datoRecibido.substring(2)) ?? _temperaturaActual; });
                      }
                    }
                  });
                }
              }
            }
          }
          setState(() { _conectadoBluetooth = true; });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Conectado exitosamente!'), backgroundColor: Colors.green));
          break;
        }
      }
    });
  }

  // --- FUNCIÓN PARA ENVIAR COMANDOS AL ESP32 ---
  void _enviarComando(String comando) async {
    if (_conectadoBluetooth && _caracteristicaTx != null) {
      await _caracteristicaTx!.write(utf8.encode(comando));
      print("Enviado a ESP32: $comando"); // Para verlo en tu terminal
    }
  }

  void _mostrarAjustesAuto() {
    showDialog(
      context: context,
      builder: (context) {
        int tempBaja = _tempMin; int tempAlta = _tempMax; bool autoActivado = _modoAuto;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Configurar Modo Auto', style: TextStyle(color: colorAzulOscuro, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(title: const Text('Activar Modo Automático', style: TextStyle(fontWeight: FontWeight.bold)), activeColor: colorCeleste, value: autoActivado, onChanged: (val) { setStateDialog(() { autoActivado = val; }); }),
                  const Divider(), const SizedBox(height: 10),
                  const Text('El sistema se apagará al bajar de:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(icon: const Icon(Icons.remove_circle, color: colorAzulOscuro), onPressed: () => setStateDialog(() => tempBaja--)), Text('$tempBaja°C', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.add_circle, color: colorAzulOscuro), onPressed: () => setStateDialog(() => tempBaja++))]),
                  const SizedBox(height: 10), const Text('El sistema se encenderá al superar:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(icon: const Icon(Icons.remove_circle, color: Colors.redAccent), onPressed: () => setStateDialog(() => tempAlta--)), Text('$tempAlta°C', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.add_circle, color: Colors.redAccent), onPressed: () => setStateDialog(() => tempAlta++))]),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: colorAzulOscuro, foregroundColor: Colors.white),
                  onPressed: () {
                    setState(() { _tempMin = tempBaja; _tempMax = tempAlta; _modoAuto = autoActivado; });
                    // ENVIAMOS EL COMANDO AUTO POR BLUETOOTH
                    _enviarComando("AUTO:${autoActivado ? '1' : '0'}:$tempBaja:$tempAlta");
                    Navigator.pop(context);
                  },
                  child: const Text('Guardar Cambios'),
                )
              ],
            );
          }
        );
      }
    );
  }

  void _mostrarTemporizadorPersonalizado() {
    Navigator.pop(context); 
    var ctrlTiempo = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Tiempo Personalizado', style: TextStyle(color: colorAzulOscuro, fontWeight: FontWeight.bold)),
          content: TextField(controller: ctrlTiempo, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minutos', hintText: 'Ej. 45', suffixText: 'min')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorAzulOscuro, foregroundColor: Colors.white),
              onPressed: () {
                if (ctrlTiempo.text.isNotEmpty) {
                  setState(() { _tiempoSeleccionado = '${ctrlTiempo.text}m'; });
                  _enviarComando("TIME:${ctrlTiempo.text}"); // ENVIAMOS TIEMPO POR BLUETOOTH
                  Navigator.pop(context);
                }
              },
              child: const Text('Iniciar'),
            )
          ],
        );
      }
    );
  }

  void _seleccionarTiempo(String textoVisual, String valorEnMinutos) {
    setState(() { _tiempoSeleccionado = textoVisual; });
    _enviarComando("TIME:$valorEnMinutos"); // ENVIAMOS TIEMPO AL ESP32
    Navigator.pop(context);
  }

  void _mostrarMenuTiempo() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Apagar ventiladores en:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorAzulOscuro)), const SizedBox(height: 10),
                  ListTile(leading: const Icon(Icons.access_time), title: const Text('15 Minutos'), onTap: () => _seleccionarTiempo('15m', '15')),
                  ListTile(leading: const Icon(Icons.access_time_filled), title: const Text('30 Minutos'), onTap: () => _seleccionarTiempo('30m', '30')),
                  ListTile(leading: const Icon(Icons.timer), title: const Text('1 Hora'), onTap: () => _seleccionarTiempo('1h', '60')),
                  ListTile(leading: const Icon(Icons.edit_notifications, color: colorAzulOscuro), title: const Text('Personalizado...', style: TextStyle(fontWeight: FontWeight.bold, color: colorAzulOscuro)), onTap: _mostrarTemporizadorPersonalizado),
                  const Divider(),
                  ListTile(leading: const Icon(Icons.cancel, color: Colors.red), title: const Text('Desactivar Temporizador', style: TextStyle(color: Colors.red)), onTap: () { setState(() { _tiempoSeleccionado = ''; }); _enviarComando("TIME:0"); Navigator.pop(context); }),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _tarjetaVentilador(int numero, double velocidadActual) {
    String textoVelocidad = 'APAGADO'; Color colorIcono = Colors.grey;
    if (velocidadActual == 1) { textoVelocidad = 'BAJO'; colorIcono = Colors.lightBlue; }
    if (velocidadActual == 2) { textoVelocidad = 'MEDIO'; colorIcono = Colors.blue; }
    if (velocidadActual == 3) { textoVelocidad = 'ALTO'; colorIcono = colorAzulOscuro; }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: velocidadActual > 0 ? colorCeleste : Colors.grey.withOpacity(0.3), width: 2)),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(velocidadActual > 0 ? Icons.mode_fan_off : Icons.mode_fan_off_outlined, color: colorIcono), const SizedBox(width: 8), Text('VENT $numero', style: const TextStyle(fontWeight: FontWeight.bold, color: colorAzulOscuro, fontSize: 16))]),
          const SizedBox(height: 10), Text(textoVelocidad, style: TextStyle(color: colorIcono, fontWeight: FontWeight.bold, fontSize: 12)),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(activeTrackColor: colorCeleste, inactiveTrackColor: Colors.grey.withOpacity(0.2), thumbColor: colorAzulOscuro, trackHeight: 6.0),
            child: Slider(
              value: velocidadActual, min: 0, max: 3, divisions: 3, 
              onChanged: _modoAuto ? null : (nuevoValor) {
                setState(() {
                  if (numero == 1) _velVent1 = nuevoValor;
                  if (numero == 2) _velVent2 = nuevoValor;
                });
                // ENVIAMOS VELOCIDAD AL ESP32
                _enviarComando("V$numero:${nuevoValor.toInt()}"); 
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
      body: SafeArea( 
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(40), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(nombre.toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorAzulOscuro), overflow: TextOverflow.ellipsis, maxLines: 1), Text('ROL: ${rol.toUpperCase()}', style: const TextStyle(fontSize: 14, color: Colors.grey))])),
                    const SizedBox(width: 10), const CircleAvatar(radius: 30, backgroundColor: colorFondoTarjeta, child: Icon(Icons.face, size: 40, color: colorAzulOscuro))
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(color: colorFondoTarjeta, borderRadius: BorderRadius.circular(30)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$_temperaturaActual°C', style: const TextStyle(fontSize: 70, fontWeight: FontWeight.bold, color: colorAzulOscuro)),
                        ElevatedButton(
                          onPressed: _conectarBluetooth,
                          style: ElevatedButton.styleFrom(shape: const CircleBorder(), backgroundColor: _conectadoBluetooth ? Colors.green : colorAzulOscuro, foregroundColor: Colors.white, padding: const EdgeInsets.all(20), elevation: 5),
                          child: Icon(_conectadoBluetooth ? Icons.bluetooth_connected : Icons.bluetooth_searching, size: 35),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.circle, size: 10, color: _conectadoBluetooth ? Colors.green : Colors.grey), const SizedBox(width: 8), 
                        Text(_conectadoBluetooth ? 'SISTEMA CONECTADO' : 'ESPERANDO CONEXIÓN...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _conectadoBluetooth ? Colors.green : colorAzulOscuro))
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 25),
              
              const Align(alignment: Alignment.centerLeft, child: Text('Control de Velocidad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorAzulOscuro))),
              if (_modoAuto) const Padding(padding: EdgeInsets.only(top: 5, bottom: 10), child: Align(alignment: Alignment.centerLeft, child: Text('* Desactiva el Modo Auto para control manual', style: TextStyle(color: Colors.red, fontSize: 12)))) else const SizedBox(height: 10),
              
              Row(children: [Expanded(child: _tarjetaVentilador(1, _velVent1)), const SizedBox(width: 15), Expanded(child: _tarjetaVentilador(2, _velVent2))]),
              const SizedBox(height: 30),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _mostrarAjustesAuto, 
                      child: Container(
                        height: 100, decoration: BoxDecoration(color: _modoAuto ? colorAzulOscuro : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: colorAzulOscuro, width: 2)),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.autorenew, size: 35, color: _modoAuto ? Colors.white : colorAzulOscuro), Text('MODO AUTO', style: TextStyle(color: _modoAuto ? Colors.white : colorAzulOscuro, fontWeight: FontWeight.bold, fontSize: 12)), if (_modoAuto) Text('$_tempMin° - $_tempMax°', style: TextStyle(color: _modoAuto ? colorCeleste : Colors.grey, fontSize: 11))]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: _mostrarMenuTiempo,
                      child: Container(
                        height: 100, decoration: BoxDecoration(color: colorCeleste, borderRadius: BorderRadius.circular(20)),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.timer, size: 35, color: Colors.white), const Text('TIEMPO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)), if (_tiempoSeleccionado.isNotEmpty) Text(_tiempoSeleccionado, style: const TextStyle(color: colorAzulOscuro, fontWeight: FontWeight.bold))]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) { return PantallaAjustes(rol: rol); })); },
                      child: Container(
                        height: 100, decoration: BoxDecoration(color: colorAzulOscuro, borderRadius: BorderRadius.circular(20)),
                        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.settings, size: 35, color: Colors.white), Text('PERFILES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]),
                child: Image.asset('assets/logo.png', width: 60),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- 4. PANTALLA DE AJUSTES Y GESTIÓN DE USUARIOS ---
class PantallaAjustes extends StatefulWidget {
  final String rol;
  const PantallaAjustes({super.key, required this.rol});
  @override
  State createState() { return _PantallaAjustesState(rol); }
}

class _PantallaAjustesState extends State {
  final String rol;
  _PantallaAjustesState(this.rol);
  var _usuarios = [];

  @override
  void initState() { super.initState(); if (rol == 'admin') { _cargarUsuarios(); } }

  _cargarUsuarios() async { var dbUsers = await DatabaseHelper.instance.queryAllRows(); setState(() { _usuarios = dbUsers; }); }

  _cerrarSesion() { Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) { return const PantallaLogin(); }), (route) => false); }

  _borrarUsuario(int id, String rolUsuario) async {
    if (rolUsuario == 'admin') { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No puedes borrar al Administrador'), backgroundColor: Colors.red)); return; }
    await DatabaseHelper.instance.delete(id); _cargarUsuarios();
  }

  _mostrarDialogoEditar(Map usuario) {
    var ctrlNombre = TextEditingController(text: usuario['nombre']); var ctrlPin = TextEditingController(text: usuario['pin']);
    showDialog(
      context: context,
      builder: (context) { 
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Editar Usuario', style: TextStyle(color: colorAzulOscuro)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: ctrlNombre, decoration: const InputDecoration(labelText: 'Nombre')), TextField(controller: ctrlPin, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: 'PIN (4 números)'))]),
          actions: [
            TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorAzulOscuro, foregroundColor: Colors.white),
              onPressed: () async {
                if (ctrlNombre.text.isNotEmpty && ctrlPin.text.isNotEmpty) {
                  await DatabaseHelper.instance.update({'id': usuario['id'], 'nombre': ctrlNombre.text, 'rol': usuario['rol'], 'pin': ctrlPin.text});
                  Navigator.pop(context); _cargarUsuarios(); 
                }
              },
              child: const Text('Guardar'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes'), backgroundColor: colorAzulOscuro, foregroundColor: Colors.white),
      body: Column(
        children: [
          const SizedBox(height: 20),
          if (rol == 'admin') ...[
            const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Align(alignment: Alignment.centerLeft, child: Text('Gestión de Usuarios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorAzulOscuro)))),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _usuarios.length,
                itemBuilder: (context, index) {
                  var usuario = _usuarios[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: usuario['rol'] == 'admin' ? colorAzulOscuro : Colors.grey, child: Icon(usuario['rol'] == 'admin' ? Icons.admin_panel_settings : Icons.person, color: Colors.white)),
                      title: Text(usuario['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Rol: ${usuario['rol']}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.edit, color: colorCeleste), onPressed: () { _mostrarDialogoEditar(usuario); }), IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { _borrarUsuario(usuario['id'], usuario['rol']); })]),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shield_outlined, size: 80, color: Colors.grey.withOpacity(0.5)), const SizedBox(height: 15), const Text('Modo Invitado', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorAzulOscuro)), const SizedBox(height: 5), const Text('No tienes permisos para\neditar o borrar usuarios.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))])) )
          ],
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout), label: const Text('CERRAR SESIÓN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              onPressed: _cerrarSesion,
            ),
          ),
        ],
      ),
    );
  }
}