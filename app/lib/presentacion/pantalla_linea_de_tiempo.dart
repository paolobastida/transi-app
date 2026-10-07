import 'package:flutter/material.dart';

import '../dependencias.dart';
import '../dominio/evento_timeline.dart';
import 'formulario_tratamiento.dart';
import 'pantalla_detalle_cambio.dart';

/// P3 · Línea de tiempo: tratamientos y cambios unidos, por fecha, con filtro.
class PantallaLineaDeTiempo extends StatefulWidget {
  final String usuarioId;

  const PantallaLineaDeTiempo({super.key, required this.usuarioId});

  @override
  State<PantallaLineaDeTiempo> createState() => _PantallaLineaDeTiempoState();
}

class _PantallaLineaDeTiempoState extends State<PantallaLineaDeTiempo> {
  DateTime? _desde;
  DateTime? _hasta;

  Future<void> _elegirFecha(bool esDesde) async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: (esDesde ? _desde : _hasta) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (elegida == null) return;
    setState(() {
      if (esDesde) {
        _desde = elegida;
      } else {
        _hasta = elegida;
      }
    });
  }

  void _limpiarFiltro() => setState(() {
        _desde = null;
        _hasta = null;
      });

  Future<void> _abrir(EventoTimeline evento) async {
    if (evento.tratamiento != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FormularioTratamiento(
            usuarioId: widget.usuarioId,
            tratamiento: evento.tratamiento,
          ),
        ),
      );
    } else if (evento.cambio != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PantallaDetalleCambio(cambio: evento.cambio!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final linea = Alcance.de(context).lineaDeTiempo;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => _elegirFecha(true),
                icon: const Icon(Icons.event),
                label: Text(_desde == null ? 'Desde' : _fechaTexto(_desde!)),
              ),
              TextButton.icon(
                onPressed: () => _elegirFecha(false),
                icon: const Icon(Icons.event_available),
                label: Text(_hasta == null ? 'Hasta' : _fechaTexto(_hasta!)),
              ),
              const Spacer(),
              if (_desde != null || _hasta != null)
                IconButton(
                  tooltip: 'Quitar filtro',
                  onPressed: _limpiarFiltro,
                  icon: const Icon(Icons.clear),
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<EventoTimeline>>(
            stream: linea.observar(widget.usuarioId, desde: _desde, hasta: _hasta),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final eventos = snapshot.data!;
              if (eventos.isEmpty) {
                return const Center(
                  child: Text('Todavía no hay nada en tu línea de tiempo.'),
                );
              }
              return ListView.builder(
                itemCount: eventos.length,
                itemBuilder: (context, indice) {
                  final evento = eventos[indice];
                  return ListTile(
                    leading: Icon(
                      evento.tipo == TipoEvento.tratamiento
                          ? Icons.medication
                          : Icons.timeline,
                    ),
                    title: Text(evento.titulo),
                    subtitle: Text('${_fechaTexto(evento.fecha)} · ${evento.detalle}'),
                    onTap: () => _abrir(evento),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

String _fechaTexto(DateTime fecha) =>
    '${fecha.year.toString().padLeft(4, '0')}-'
    '${fecha.month.toString().padLeft(2, '0')}-'
    '${fecha.day.toString().padLeft(2, '0')}';
