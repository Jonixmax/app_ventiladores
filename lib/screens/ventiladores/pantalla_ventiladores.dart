import 'package:flutter/material.dart';
import '../../assistant/widgets/kiro_fab.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/gradients.dart';
import '../../core/theme/shadows.dart';

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
      body: Stack(
        children: [
          SafeArea(
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
          const KiroTab(),
        ],
      ),
    );
  }
}
