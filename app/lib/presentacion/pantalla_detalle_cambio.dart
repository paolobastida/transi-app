import 'package:flutter/material.dart';

import '../dependencias.dart';
import '../dominio/cambio.dart';

/// P9 · Detalle de un cambio. Muestra la descripción y los adjuntos.
class PantallaDetalleCambio extends StatelessWidget {
  final Cambio cambio;

  const PantallaDetalleCambio({super.key, required this.cambio});

  Future<void> _desactivar(BuildContext context) async {
    await Alcance.de(context).cambios.desactivar(cambio.id, cambio.usuarioId);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambio'),
        actions: [
          IconButton(
            tooltip: 'Desactivar',
            onPressed: () => _desactivar(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_fechaTexto(cambio.fecha),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (cambio.descripcion.isNotEmpty) Text(cambio.descripcion),
          const SizedBox(height: 16),
          for (final adjunto in cambio.adjuntos)
            if (adjunto.esFoto)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(adjunto.contenido, fit: BoxFit.cover),
                ),
              )
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.audiotrack),
                title: Text(adjunto.nombre),
                subtitle: const Text('Nota de voz'),
              ),
        ],
      ),
    );
  }
}

String _fechaTexto(DateTime fecha) =>
    '${fecha.year.toString().padLeft(4, '0')}-'
    '${fecha.month.toString().padLeft(2, '0')}-'
    '${fecha.day.toString().padLeft(2, '0')}';
