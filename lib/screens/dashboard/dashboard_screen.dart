import 'dart:async';
import 'package:flutter/material.dart';
import '../../assistant/kiro_controller.dart'; // Controlador para gestionar el estado del asistente Kiro.
import '../../assistant/widgets/kiro_fab.dart'; // Botón de acción flotante para Kiro.
import '../../core/constants/colors.dart'; // Colores personalizados de la aplicación.
import '../../core/constants/gradients.dart'; // Gradientes personalizados.
import '../../core/theme/shadows.dart'; // Estilos de sombra para UI.
import '../../services/bluetooth_service.dart'; // Servicio para la comunicación Bluetooth Low Energy (BLE).
import '../ajustes/pantalla_ajustes.dart'; // Pantalla de ajustes.
import '../ventiladores/pantalla_ventiladores.dart'; // Pantalla para gestionar ventiladores.
import 'widgets/ajustes_auto_dialog.dart'; // Diálogo para configurar el modo automático.
import 'widgets/menu_tiempo_sheet.dart'; // Hoja inferior para seleccionar tiempo.
import 'widgets/tarjeta_accion.dart'; // Widget de tarjeta reutilizable para acciones.

/// `DashboardScreen` es la pantalla principal de la aplicación.
/// Muestra información de sensores, estado de conexión Bluetooth y opciones de control.
class DashboardScreen extends StatefulWidget {
  final String rol; // Rol del usuario (ej. 'admin', 'invitado').
  final String nombre; // Nombre del usuario.

  /// Constructor del DashboardScreen.
  const DashboardScreen({super.key, required this.rol, required this.nombre});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

/// Estado asociado a `DashboardScreen`.
/// Gestiona la lógica de negocio, la interacción con servicios y la actualización de la UI.
class _DashboardScreenState extends State<DashboardScreen> {
  final KitherBluetoothService _bluetoothService = KitherBluetoothService(); // Instancia del servicio Bluetooth.

  // Variables de estado para la información mostrada en el dashboard.
  double _temperaturaActual = 0.0; // Temperatura actual leída del sensor.
  double _humedadActual = 0.0; // Humedad actual leída del sensor.
  bool _conectadoBluetooth = false; // Estado de conexión Bluetooth.
  bool _modoAuto = false; // Indica si el modo automático de ventiladores está activo.
  String _tiempoSeleccionado = ''; // Cadena que representa el tiempo restante del temporizador.
  List<double> _velocidadVentiladores = [0.0, 0.0, 0.0, 0.0, 0.0]; // Velocidades de los 5 ventiladores.
  
  // Parámetros para el modo automático.
  int _tempMin = 20; // Temperatura mínima para el modo automático.
  int _tempMax = 28; // Temperatura máxima para el modo automático.
  int _velocidadAuto = 3; // Velocidad predeterminada en modo automático.

  Timer? _timerCuentaRegresiva; // Temporizador para la cuenta regresiva en pantalla.
  int _segundosRestantes = 0; // Segundos restantes para el temporizador.

  @override
  void initState() {
    super.initState();
    // Configura los listeners del servicio Bluetooth para actualizar el estado de la UI.

    /// Listener para las lecturas de sensores.
    /// Actualiza la temperatura y humedad en el estado del widget.
    _bluetoothService.onLecturaSensores = (temperatura, humedad) {
      if (!mounted) return; // Asegura que el widget aún está montado antes de actualizar el estado.
      setState(() { _temperaturaActual = temperatura; _humedadActual = humedad; });
    };

    /// Listener para el evento de conexión Bluetooth exitosa.
    /// Actualiza el estado de conexión, el estado de Kiro y muestra un mensaje al usuario.
    _bluetoothService.onConectado = () {
      if (!mounted) return;
      setState(() { _conectadoBluetooth = true; });
      KiroController.instance.cambiarEstado(KiroEstado.feliz); // Kiro se pone feliz al conectar.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('¡Conectado exitosamente!'),
        backgroundColor: colorExito,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    };

    /// Listener para errores del servicio Bluetooth.
    /// Kiro se pone triste y muestra un mensaje de error al usuario.
    _bluetoothService.onError = (mensaje) {
      if (!mounted) return;
      KiroController.instance.cambiarEstado(KiroEstado.triste); // Kiro se pone triste por el error.
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
    _timerCuentaRegresiva?.cancel(); // Cancela el temporizador para evitar fugas de memoria.
    _bluetoothService.desconectar(); // Desconecta el servicio Bluetooth al salir de la pantalla.
    super.dispose();
  }

  /// Determina el color del texto de la temperatura basándose en su valor.
  /// Proporciona una indicación visual rápida del rango de temperatura.
  Color _obtenerColorTemperatura(double temp) {
    if (temp == 0.0) return colorAzulOscuro; // Color por defecto si no hay lectura.
    if (temp >= 28.0) return Colors.lightBlue.shade200; // Muy cálido.
    if (temp >= 25.0) return Colors.lightBlue; // Cálido.
    if (temp >= 22.0) return Colors.blue.shade700; // Templado.
    return const Color(0xFF003893); // Frío.
  }

  /// Envía un comando al dispositivo Bluetooth a través del servicio.
  void _enviarComando(String comando) => _bluetoothService.enviarComando(comando);

  /// Inicia o cancela un temporizador para los ventiladores.
  /// Envía el comando `TIME` al hardware y gestiona la cuenta regresiva en la UI.
  void _iniciarTemporizador(int minutos) {
    _timerCuentaRegresiva?.cancel(); // Cancela cualquier temporizador existente.

    // Envía el comando de tiempo al hardware. Si 'minutos' es 0, el firmware lo interpreta como una cancelación.
    _enviarComando("TIME:$minutos");

    if (minutos == 0) {
      // Si el temporizador se cancela, se limpia el estado local de la UI.
      setState(() {
        _tiempoSeleccionado = '';
        _segundosRestantes = 0;
      });
      return;
    }

    // Si se inicia un temporizador, el modo automático se desactiva para evitar conflictos.
    if (_modoAuto) {
      setState(() {
        _modoAuto = false;
      });
    }

    // Inicializa la cuenta regresiva en la UI.
    setState(() {
      _segundosRestantes = minutos * 60;
    });

    // Inicia un temporizador periódico para actualizar la cuenta regresiva cada segundo.
    _timerCuentaRegresiva = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segundosRestantes > 0) {
        setState(() {
          _segundosRestantes--;
          int m = _segundosRestantes ~/ 60; // Calcula los minutos restantes.
          int s = _segundosRestantes % 60; // Calcula los segundos restantes.
          _tiempoSeleccionado = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'; // Formatea el tiempo.
        });
      } else {
        timer.cancel(); // Detiene el temporizador cuando llega a cero.
        // Cuando el temporizador finaliza, el firmware ya debería haber apagado los ventiladores.
        // Aquí solo limpiamos el estado de la UI para reflejarlo.
        setState(() {
          _tiempoSeleccionado = '';
          _velocidadVentiladores = List.filled(5, 0.0); // Reinicia las velocidades de los ventiladores.
        });
      }
    });
  }

  /// Gestiona la conexión y desconexión con el dispositivo Bluetooth.
  /// Incluye la solicitud de permisos y feedback al usuario.
  void _conectarBluetooth() async {
    if (_conectadoBluetooth) {
      // Si ya está conectado, desconecta el servicio y reinicia el estado de la UI.
      await _bluetoothService.desconectar();
      setState(() { _conectadoBluetooth = false; _temperaturaActual = 0.0; _humedadActual = 0.0; });
      return;
    }

    // Solicita los permisos necesarios para Bluetooth.
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

    // Muestra un mensaje mientras busca el dispositivo.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Buscando KITHER...'),
      backgroundColor: colorAzulOscuro,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));

    await _bluetoothService.conectar(); // Inicia el proceso de conexión.
  }

  /// Muestra el diálogo para configurar los ajustes del modo automático.
  /// Gestiona el guardado de la configuración y la comunicación con el hardware.
  void _mostrarAjustesAuto() {
    mostrarAjustesAuto(
      context,
      tempMin: _tempMin,
      tempMax: _tempMax,
      modoAuto: _modoAuto,
      velocidadAuto: _velocidadAuto,
      onGuardar: (tempBaja, tempAlta, autoActivado, velAuto) {
        final bool modoAutoEstabaActivo = _modoAuto; // Guarda el estado anterior del modo auto.

        // Si se activa el modo automático, cualquier temporizador activo debe cancelarse.
        if (autoActivado) {
          _iniciarTemporizador(0); // Cancela el temporizador.
        }

        // Actualiza el estado local del widget con los nuevos valores.
        setState(() {
          _tempMin = tempBaja;
          _tempMax = tempAlta;
          _modoAuto = autoActivado;
          _velocidadAuto = velAuto;
                        
          // Si el modo automático se desactiva, reinicia visualmente los sliders de velocidad.
          if (!autoActivado) {
            _velocidadVentiladores = [0.0, 0.0, 0.0, 0.0, 0.0];
          }
        });
                      
        // WORKAROUND: Si el modo automático ya estaba activo y solo se modificaron sus valores (temperaturas, velocidad),
        // se desactiva y reactiva en el ESP32 para forzar una re-evaluación de los umbrales y aplicar los cambios.
        if (autoActivado && modoAutoEstabaActivo) {
          _enviarComando("AUTO:0:$tempBaja:$tempAlta:$velAuto"); // Desactiva temporalmente.
        }

        // Envía el comando final al ESP32 para activar/desactivar el modo automático
        // con los nuevos umbrales de temperatura y velocidad.
        _enviarComando("AUTO:${autoActivado ? '1' : '0'}:$tempBaja:$tempAlta:$_velocidadAuto");

        // Si el modo automático se desactiva, envía comandos explícitos para apagar todos los ventiladores.
        if (!autoActivado) {
          for (int i = 1; i <= 5; i++) {
            _enviarComando("V$i:0"); // Apaga cada ventilador individualmente.
          }
        }
                      
        // Cierra el diálogo de ajustes automáticos. `rootNavigator: true` asegura que solo se cierra el diálogo.
        Navigator.of(context, rootNavigator: true).pop();
      },
    );
  }

  /// Muestra el menú de tiempo para configurar el temporizador de apagado.
  void _mostrarMenuTiempo() {
    mostrarMenuTiempo(context, onSeleccionar: _iniciarTemporizador);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack( // Permite superponer widgets, como el botón flotante de Kiro.
        children: [
          SafeArea( // Asegura que el contenido no se superponga con las barras del sistema (notch, barra de estado).
            child: SingleChildScrollView( // Permite hacer scroll si el contenido excede el tamaño de la pantalla.
              padding: const EdgeInsets.all(20), // Espaciado alrededor del contenido principal.
              child: Column( // Columna principal que organiza todos los widgets verticalmente.
                children: [
                  // Tarjeta de información del usuario (Nombre y Rol).
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: sombraTarjeta()),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded( // Permite que la columna de texto ocupe el espacio disponible.
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.nombre.toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colorAzulOscuro, letterSpacing: 0.5), overflow: TextOverflow.ellipsis, maxLines: 1),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(color: colorFondoTarjeta, borderRadius: BorderRadius.circular(8)),
                                child: Text('ROL: ${widget.rol.toUpperCase()}', style: const TextStyle(fontSize: 11, color: colorAzulOscuro, fontWeight: FontWeight.bold)),
                              ),
                            ]
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Avatar de Kiro (imagen asombrada).
                        Container(
                          width: 86,
                          height: 86,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradienteCeleste, boxShadow: [BoxShadow(color: colorCeleste.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
                          child: Container(
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                            child: ClipOval( // Recorta la imagen en forma circular.
                              child: Transform.scale(
                                scale: 1.5, // Aplica un zoom a la imagen de Kiro.
                                child: Image.asset('assets/kiro_asombrado.png', fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Tarjeta de temperatura, humedad y estado de conexión Bluetooth.
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
                            Column( // Columna para mostrar la temperatura y humedad.
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('$_temperaturaActual', style: TextStyle(fontSize: 58, fontWeight: FontWeight.w800, color: _obtenerColorTemperatura(_temperaturaActual), height: 1)),
                                    Padding(padding: const EdgeInsets.only(top: 10), child: Text('°C', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _obtenerColorTemperatura(_temperaturaActual)))),
                                  ]
                                ),
                                const SizedBox(height: 8),
                                // Contenedor para mostrar la humedad.
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))]),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.water_drop, color: colorCeleste, size: 18),
                                      const SizedBox(width: 5),
                                      Text('Humedad: $_humedadActual%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorCeleste)),
                                    ]
                                  ),
                                )
                              ],
                            ),
                            // Botón para conectar/desconectar Bluetooth.
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
                        // Indicador de estado de conexión Bluetooth.
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

                  // Mensaje de advertencia si el modo automático está activo.
                  if (_modoAuto)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: colorPeligro.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: colorPeligro, size: 18),
                          SizedBox(width: 8),
                          Expanded(child: Text('Desactiva el Modo Auto para control manual', style: TextStyle(color: colorPeligro, fontSize: 12, fontWeight: FontWeight.w600))),
                        ]
                      ),
                    ),

                  // Botón para navegar a la pantalla de gestión de ventiladores.
                  Container(
                    decoration: BoxDecoration(gradient: gradientePrincipal, borderRadius: BorderRadius.circular(22), boxShadow: sombraBoton()),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) {
                          return PantallaVentiladores(
                            velocidades: _velocidadVentiladores,
                            modoAuto: _modoAuto,
                            // Callback para actualizar la velocidad de un ventilador y enviar el comando.
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

                  // Fila de tarjetas de acción (Modo Auto, Tiempo, Perfiles).
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TarjetaAccion(
                          onTap: _mostrarAjustesAuto, // Abre el diálogo de ajustes automáticos.
                          colorFondo: _modoAuto ? colorAzulOscuro : Colors.white,
                          icono: Icons.autorenew,
                          colorIcono: _modoAuto ? Colors.white : colorAzulOscuro,
                          titulo: 'MODO AUTO',
                          colorTitulo: _modoAuto ? Colors.white : colorAzulOscuro,
                          subtitulo: _modoAuto ? '$_tempMin° - $_tempMax°' : null, // Muestra el rango de temperatura si está activo.
                          colorSubtitulo: colorCeleste,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TarjetaAccion(
                          onTap: _mostrarMenuTiempo, // Abre la hoja inferior para seleccionar el tiempo.
                          gradiente: gradienteCeleste,
                          icono: Icons.timer,
                          colorIcono: Colors.white,
                          titulo: 'TIEMPO',
                          colorTitulo: Colors.white,
                          subtitulo: _tiempoSeleccionado.isNotEmpty ? _tiempoSeleccionado : null, // Muestra el tiempo restante si hay un temporizador activo.
                          colorSubtitulo: colorAzulOscuro,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TarjetaAccion(
                          onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) { return PantallaAjustes(rol: widget.rol); })); }, // Navega a la pantalla de ajustes de perfiles.
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
          const KiroTab(), // Botón de acción flotante del asistente Kiro, superpuesto sobre el contenido.
        ],
      ),
    );
  }
}
