import 'package:flutter/material.dart';

import '../dependencias.dart';
import '../dominio/cambio.dart';
import 'confirmaciones.dart';
import 'formato_fecha.dart';
import 'reproductor_audio.dart';
import 'vista_foto.dart';

/// P9 · Detalle de un cambio. Muestra la descripción y los adjuntos.
class PantallaDetalleCambio extends StatelessWidget {
  final Cambio cambio;

  const PantallaDetalleCambio({super.key, required this.cambio});

  Future<void> _desactivar(BuildContext context) async {
    final repositorio = Alcance.de(context).cambios;
    final confirmar = await confirmarOcultar(context, que: 'este cambio');
    if (!confirmar) return;
    await repositorio.desactivar(cambio.id, cambio.usuarioId);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambio'),
        actions: [
          IconButton(
            tooltip: 'Ocultar',
            onPressed: () => _desactivar(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(fechaTexto(cambio.fecha),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (cambio.descripcion.isNotEmpty) Text(cambio.descripcion),
          const SizedBox(height: 16),
          for (final adjunto in cambio.adjuntos)
            if (adjunto.esFoto)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: VistaFoto(contenido: adjunto.contenido),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nota de voz',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 6),
                    ReproductorAudio(contenido: adjunto.contenido),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
