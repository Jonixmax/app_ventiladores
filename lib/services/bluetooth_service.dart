import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/constants/ble_uuids.dart';

/// Resultado de una solicitud de permisos BLE.
enum PermisosBleResultado { concedidos, denegados }

/// Encapsula toda la comunicación BLE con el ESP32 "KITHER":
/// escaneo, conexión, envío de comandos y recepción de temperatura/humedad.
///
/// Antes vivía repartido dentro de `_DashboardScreenState` en main.dart;
/// ahora la pantalla solo escucha los callbacks de esta clase.
class KitherBluetoothService {
  BluetoothDevice? _dispositivo;
  BluetoothCharacteristic? _caracteristicaTx;
  BluetoothCharacteristic? _caracteristicaRx;

  bool get estaConectado => _dispositivo != null && _caracteristicaTx != null;

  /// Se llama cuando llegan nuevas lecturas de temperatura/humedad ("T:xx|H:xx").
  void Function(double temperatura, double humedad)? onLecturaSensores;

  /// Se llama cuando la conexión se establece con éxito.
  void Function()? onConectado;

  /// Se llama cuando se pierde o se cierra la conexión.
  void Function()? onDesconectado;

  /// Se llama si algo falla durante el escaneo/conexión (mensaje ya listo para SnackBar).
  void Function(String mensaje)? onError;

  Future<PermisosBleResultado> solicitarPermisos() async {
    final permisos = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    final algunoDenegado = permisos.values.any((status) => status.isDenied);
    return algunoDenegado ? PermisosBleResultado.denegados : PermisosBleResultado.concedidos;
  }

  /// Escanea, se conecta al primer dispositivo "KITHER" que encuentre
  /// y se suscribe a las notificaciones de la característica RX.
  Future<void> conectar() async {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.platformName == nombreDispositivoBle) {
          FlutterBluePlus.stopScan();
          _dispositivo = r.device;

          try {
            await _dispositivo!.connect();
            await _descubrirCaracteristicas();
            onConectado?.call();
          } catch (e) {
            onError?.call('No se pudo conectar con $nombreDispositivoBle: $e');
          }
          break;
        }
      }
    });
  }

  Future<void> _descubrirCaracteristicas() async {
    final servicios = await _dispositivo!.discoverServices();
    for (BluetoothService servicio in servicios) {
      if (servicio.uuid.toString().toUpperCase() != servicioUUID) continue;

      for (BluetoothCharacteristic c in servicio.characteristics) {
        if (c.uuid.toString().toUpperCase() == txUUID) {
          _caracteristicaTx = c;
        }
        if (c.uuid.toString().toUpperCase() == rxUUID) {
          _caracteristicaRx = c;
          await _caracteristicaRx!.setNotifyValue(true);
          _caracteristicaRx!.lastValueStream.listen(_procesarValorRecibido);
        }
      }
    }
  }

  void _procesarValorRecibido(List<int> value) {
    if (value.isEmpty) return;
    final datoRecibido = utf8.decode(value);
    if (!datoRecibido.startsWith("T:")) return;

    try {
      final partes = datoRecibido.split('|');
      final tempStr = partes[0].replaceAll('T:', '');
      final humStr = partes[1].replaceAll('H:', '');
      onLecturaSensores?.call(double.parse(tempStr), double.parse(humStr));
    } catch (e) {
      onError?.call('Error leyendo sensores: $e');
    }
  }

  /// Envía un comando de texto plano al ESP32 (ej. "V1:2", "TIME:5", "AUTO:1:20:28:3").
  Future<void> enviarComando(String comando) async {
    if (!estaConectado) return;
    await _caracteristicaTx!.write(utf8.encode(comando));
  }

  Future<void> desconectar() async {
    await _dispositivo?.disconnect();
    _dispositivo = null;
    _caracteristicaTx = null;
    _caracteristicaRx = null;
    onDesconectado?.call();
  }
}
