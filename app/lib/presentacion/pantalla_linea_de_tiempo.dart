import 'package:flutter/material.dart';

import '../dependencias.dart';
import '../dominio/cambio.dart';
import '../dominio/evento_timeline.dart';
import 'formato_fecha.dart';
import 'formulario_tratamiento.dart';
import 'pantalla_detalle_cambio.dart';
import 'tema.dart';

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
  String _preset = 'todo';

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

  void _aplicarPreset(String preset) {
    final ahora = DateTime.now();
    setState(() {
      _preset = preset;
      switch (preset) {
        case 'mes':
          _desde = DateTime(ahora.year, ahora.month - 1, ahora.day);
          _hasta = ahora;
        case 'trimestre':
          _desde = DateTime(ahora.year, ahora.month - 3, ahora.day);
          _hasta = ahora;
        case 'anio':
          _desde = DateTime(ahora.year, 1, 1);
          _hasta = ahora;
        default:
          _desde = null;
          _hasta = null;
      }
    });
  }

  Future<void> _elegirRango() async {
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: (_desde != null && _hasta != null)
          ? DateTimeRange(start: _desde!, end: _hasta!)
          : null,
    );
    if (rango == null) return;
    setState(() {
      _preset = 'personalizado';
      _desde = rango.start;
      _hasta = rango.end;
    });
  }

  void _limpiarFiltro() => setState(() {
        _desde = null;
        _hasta = null;
        _preset = 'todo';
      });

  @override
  Widget build(BuildContext context) {
    final linea = Alcance.de(context).lineaDeTiempo;
    final hayFiltro = _desde != null || _hasta != null;

    return Column(
      children: [
        _Filtros(
          preset: _preset,
          onPreset: _aplicarPreset,
          onRango: _elegirRango,
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
                return hayFiltro
                    ? EstadoVacio(
                        icono: Icons.filter_alt_off,
                        mensaje: 'No hay eventos en este rango de fechas.',
                        etiquetaAccion: 'Quitar filtro',
                        iconoAccion: Icons.clear,
                        onAccion: _limpiarFiltro,
                      )
                    : const EstadoVacio(
                        icono: Icons.timeline,
                        mensaje:
                            'Todavía no hay nada en tu línea de tiempo.\nRegistrá un cambio para empezar.',
                      );
              }
              final filas = _construirFilas(eventos);
              return ListView.builder(
                padding: const EdgeInsets.only(top: 4, bottom: 96),
                itemCount: filas.length,
                itemBuilder: (context, indice) => filas[indice],
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _construirFilas(List<EventoTimeline> eventos) {
    final filas = <Widget>[];
    int? mesAnterior;
    for (var i = 0; i < eventos.length; i++) {
      final evento = eventos[i];
      final mes = evento.fecha.year * 12 + evento.fecha.month;
      if (mes != mesAnterior) {
        filas.add(_EncabezadoMes(fecha: evento.fecha));
        mesAnterior = mes;
      }
      filas.add(
        _FilaEvento(
          evento: evento,
          esUltimo: i == eventos.length - 1,
          onTap: () => _abrir(evento),
        ),
      );
    }
    return filas;
  }
}

class _Filtros extends StatelessWidget {
  final String preset;
  final ValueChanged<String> onPreset;
  final VoidCallback onRango;

  const _Filtros({
    required this.preset,
    required this.onPreset,
    required this.onRango,
  });

  @override
  Widget build(BuildContext context) {
    const opciones = [
      ('todo', 'Todo'),
      ('mes', 'Último mes'),
      ('trimestre', '3 meses'),
      ('anio', 'Este año'),
    ];
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          for (final (valor, etiqueta) in opciones)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(etiqueta),
                selected: preset == valor,
                onSelected: (_) => onPreset(valor),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: const Icon(Icons.date_range, size: 18),
              label: const Text('Personalizado'),
              selected: preset == 'personalizado',
              onSelected: (_) => onRango(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EncabezadoMes extends StatelessWidget {
  final DateTime fecha;

  const _EncabezadoMes({required this.fecha});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        _mesTexto(fecha),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: ColoresTrans.tinta.withValues(alpha: 0.7),
            ),
      ),
    );
  }
}

class _FilaEvento extends StatelessWidget {
  final EventoTimeline evento;
  final bool esUltimo;
  final VoidCallback onTap;

  const _FilaEvento({
    required this.evento,
    required this.esUltimo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final esTratamiento = evento.tipo == TipoEvento.tratamiento;
    final colorPunto = esTratamiento
        ? ColoresTrans.rosaFuerte
        : ColoresTrans.celesteFuerte;

    final fotos = evento.cambio?.adjuntos.where((a) => a.esFoto).toList() ??
        const <Adjunto>[];
    final miniatura = fotos.isEmpty ? null : fotos.first;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                const SizedBox(height: 22),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colorPunto,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                if (!esUltimo)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFFDCE6EB),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: esTratamiento
                      ? esquema.secondaryContainer
                      : ColoresTrans.celeste.withValues(alpha: 0.25),
                  child: Icon(
                    esTratamiento ? Icons.medication : Icons.timeline,
                    color: esTratamiento
                        ? esquema.onSecondaryContainer
                        : ColoresTrans.celesteFuerte,
                  ),
                ),
                title: Text(
                  evento.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${fechaTexto(evento.fecha)} · ${evento.detalle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: miniatura == null
                    ? null
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          miniatura.contenido,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                onTap: onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _meses = [
  '',
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String _mesTexto(DateTime fecha) => '${_meses[fecha.month]} ${fecha.year}';
