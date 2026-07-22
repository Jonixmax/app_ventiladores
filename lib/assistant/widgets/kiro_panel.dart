import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../kiro_controller.dart';
import '../kiro_data.dart';

void mostrarPanelKiro(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) => const _PanelKiroContenido(),
  );
}

class _PanelKiroContenido extends StatefulWidget {
  const _PanelKiroContenido();

  @override
  State<_PanelKiroContenido> createState() => _PanelKiroContenidoState();
}

class _PanelKiroContenidoState extends State<_PanelKiroContenido> {
  String _busqueda = '';
  String? _categoriaSeleccionada; // null = "todas"

  List<PreguntaKiro> get _preguntasFiltradas {
    return preguntasKiro.where((p) {
      final coincideCategoria = _categoriaSeleccionada == null || p.categoriaId == _categoriaSeleccionada;
      final coincideBusqueda = _busqueda.isEmpty ||
          p.pregunta.toLowerCase().contains(_busqueda.toLowerCase()) ||
          p.respuesta.toLowerCase().contains(_busqueda.toLowerCase());
      return coincideCategoria && coincideBusqueda;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final preguntas = _preguntasFiltradas;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controladorScroll) {
        return SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 16),

              // --- Encabezado con la cara actual de Kiro ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    ValueListenableBuilder<KiroEstado>(
                      valueListenable: KiroController.instance.estado,
                      builder: (context, estado, _) => CircleAvatar(radius: 26, backgroundImage: AssetImage(estado.asset)),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hola, soy Kiro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorAzulOscuro)),
                          Text('¿En qué te ayudo?', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- Buscador ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: (valor) => setState(() => _busqueda = valor),
                  decoration: InputDecoration(
                    hintText: 'Buscar una pregunta...',
                    prefixIcon: const Icon(Icons.search, color: colorAzulOscuro),
                    filled: true,
                    fillColor: colorFondo,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // --- Chips de categoría ---
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _chipCategoria(nombre: 'Todas', seleccionado: _categoriaSeleccionada == null, onTap: () => setState(() => _categoriaSeleccionada = null)),
                    const SizedBox(width: 8),
                    for (final categoria in categoriasKiro) ...[
                      _chipCategoria(
                        nombre: categoria.nombre,
                        seleccionado: _categoriaSeleccionada == categoria.id,
                        onTap: () => setState(() => _categoriaSeleccionada = categoria.id),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),

              // --- Lista de preguntas ---
              Expanded(
                child: preguntas.isEmpty
                    ? const Center(child: Text('No encontré nada con eso 🤔', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        controller: controladorScroll,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: preguntas.length,
                        itemBuilder: (context, index) {
                          final p = preguntas[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                            elevation: 0,
                            color: colorFondo,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: ExpansionTile(
                              shape: const RoundedRectangleBorder(side: BorderSide.none),
                              iconColor: colorAzulOscuro,
                              collapsedIconColor: colorAzulOscuro,
                              title: Text(p.pregunta, style: const TextStyle(fontWeight: FontWeight.w600, color: colorAzulOscuro, fontSize: 14)),
                              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              expandedAlignment: Alignment.centerLeft,
                              children: [Text(p.respuesta, style: TextStyle(color: Colors.grey.shade800, height: 1.4))],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chipCategoria({required String nombre, required bool seleccionado, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? colorAzulOscuro : colorFondoTarjeta,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(nombre, style: TextStyle(color: seleccionado ? Colors.white : colorAzulOscuro, fontWeight: FontWeight.w600, fontSize: 12.5)),
      ),
    );
  }
}
