import 'dart:async';
import 'package:flutter/material.dart';
import '../../assistant/kiro_controller.dart';
import '../../assistant/widgets/kiro_fab.dart'; // exporta KiroTab
import '../../core/constants/colors.dart';
import '../../core/constants/gradients.dart';
import '../../core/theme/shadows.dart';
import '../../services/bluetooth_service.dart';
import '../ajustes/pantalla_ajustes.dart';
import '../ventiladores/pantalla_ventiladores.dart';
import 'widgets/ajustes_auto_dialog.dart';
import 'widgets/menu_tiempo_sheet.dart';
import 'widgets/tarjeta_accion.dart';

class DashboardScreen extends StatefulWidget {
  final String rol;
  final String nombre;
  const DashboardScreen({super.key, required this.rol, required this.nombre});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final KitherBluetoothService _bluetoothService = KitherBluetoothService();

  double _temperaturaActual = 0.0;
  double _humedadActual = 0.0;
  bool _conectadoBluetooth = false;
  bool _modoAuto = false;
  String _tiempoSeleccionado = '';
  List<double> _velocidadVentiladores = [0.0, 0.0, 0.0, 0.0, 0.0];
  int _tempMin = 20;
  int _tempMax = 28;
  int _velocidadAuto = 3;

  Timer? _timerCuentaRegresiva;
  int _segundosRestantes = 0;

  @override
  void initState() {
    super.initState();

    _bluetoothService.onLecturaSensores = (temperatura, humedad) {
      if (!mounted) return;
      setState(() { _temperaturaActual = temperatura; _humedadActual = humedad; });
    };

    _bluetoothService.onConectado = () {
      if (!mounted) return;
      setState(() { _conectadoBluetooth = true; });
      KiroController.instance.cambiarEstado(KiroEstado.feliz);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('¡Conectado exitosamente!'),
        backgroundColor: colorExito,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    };

    _bluetoothService.onError = (mensaje) {
      if (!mounted) return;
      KiroController.instance.cambiarEstado(KiroEstado.triste);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(mensaje),
        backgroundColor: colorPeligro,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    };
  }

  @override
  void dispose() {
    _timerCuentaRegresiva?.cancel();
    _bluetoothService.desconectar();
    super.dispose();
  }

  Color _obtenerColorTemperatura(double temp) {
    if (temp == 0.0) return colorAzulOscuro;
    if (temp >= 28.0) return Colors.lightBlue.shade200;
    if (temp >= 25.0) return Colors.lightBlue;
    if (temp >= 22.0) return Colors.blue.shade700;
    return const Color(0xFF003893);
  }

  void _enviarComando(String comando) => _bluetoothService.enviarComando(comando);

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

        if (_modoAuto) {
          _enviarComando("AUTO:0:$_tempMin:$_tempMax");
        }

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
      await _bluetoothService.desconectar();
      setState(() { _conectadoBluetooth = false; _temperaturaActual = 0.0; _humedadActual = 0.0; });
      return;
    }

    final resultadoPermisos = await _bluetoothService.solicitarPermisos();
    if (resultadoPermisos == PermisosBleResultado.denegados) {
      if (!mounted) return;
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

    await _bluetoothService.conectar();
  }

  void _mostrarAjustesAuto() {
    mostrarAjustesAuto(
      context,
      tempMin: _tempMin,
      tempMax: _tempMax,
      modoAuto: _modoAuto,
      velocidadAuto: _velocidadAuto,
      onGuardar: (tempBaja, tempAlta, autoActivado, velAuto) {
        setState(() { _tempMin = tempBaja; _tempMax = tempAlta; _modoAuto = autoActivado; _velocidadAuto = velAuto; });
        _enviarComando("AUTO:${autoActivado ? '1' : '0'}:$tempBaja:$tempAlta:$_velocidadAuto");
      },
    );
  }

  void _mostrarMenuTiempo() {
    mostrarMenuTiempo(context, onSeleccionar: _iniciarTemporizador);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
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
                    child: TarjetaAccion(
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
                    child: TarjetaAccion(
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
                    child: TarjetaAccion(
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
      const KiroTab(),
        ],
      ),
    );
  }
}
