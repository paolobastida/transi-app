import 'dart:async';

import '../dominio/cambio.dart';
import '../dominio/evento_timeline.dart';
import '../dominio/tratamiento.dart';
import 'cambio_repositorio.dart';
import 'tratamiento_repositorio.dart';

/// Línea de tiempo (U15): junta tratamientos y cambios ordenados por fecha
/// (más reciente primero), con filtro opcional por rango.
///
/// Es una **consulta de lectura**: no tiene tabla propia.
class LineaDeTiempo {
  final CambioRepositorio cambios;
  final TratamientoRepositorio tratamientos;

  const LineaDeTiempo({required this.cambios, required this.tratamientos});

  Stream<List<EventoTimeline>> observar(
    String usuarioId, {
    DateTime? desde,
    DateTime? hasta,
  }) {
    return _combinar(
      cambios.observar(usuarioId),
      tratamientos.observar(usuarioId),
      (listaCambios, listaTratamientos) =>
          _unir(listaCambios, listaTratamientos, desde, hasta),
    );
  }

  List<EventoTimeline> _unir(
    List<Cambio> listaCambios,
    List<Tratamiento> listaTratamientos,
    DateTime? desde,
    DateTime? hasta,
  ) {
    final eventos = <EventoTimeline>[
      for (final cambio in listaCambios)
        EventoTimeline(
          tipo: TipoEvento.cambio,
          fecha: cambio.fecha,
          titulo: cambio.descripcion.isEmpty ? 'Cambio' : cambio.descripcion,
          detalle: _resumenAdjuntos(cambio),
          referencia: cambio,
        ),
      for (final tratamiento in listaTratamientos)
        EventoTimeline(
          tipo: TipoEvento.tratamiento,
          fecha: tratamiento.fechaInicio,
          titulo: tratamiento.nombre,
          detalle: '${tratamiento.dosis} · ${tratamiento.frecuencia}',
          referencia: tratamiento,
        ),
    ];

    eventos.sort((a, b) => b.fecha.compareTo(a.fecha));
    return eventos.where((evento) {
      if (desde != null && evento.fecha.isBefore(desde)) return false;
      if (hasta != null && evento.fecha.isAfter(hasta)) return false;
      return true;
    }).toList();
  }

  String _resumenAdjuntos(Cambio cambio) {
    if (cambio.adjuntos.isEmpty) return 'Sin adjuntos';
    final fotos = cambio.adjuntos.where((a) => a.esFoto).length;
    final audios = cambio.adjuntos.where((a) => a.esAudio).length;
    final partes = <String>[
      if (fotos > 0) '$fotos foto(s)',
      if (audios > 0) '$audios audio(s)',
    ];
    return partes.join(' · ');
  }
}

/// Combina dos streams: emite cada vez que cualquiera de los dos cambia.
/// (Equivalente mínimo de `combineLatest`, sin dependencias extra.)
Stream<R> _combinar<A, B, R>(
  Stream<A> primero,
  Stream<B> segundo,
  R Function(A, B) combinar,
) {
  late StreamController<R> controlador;
  A? ultimoA;
  B? ultimoB;
  var hayA = false;
  var hayB = false;
  StreamSubscription<A>? subA;
  StreamSubscription<B>? subB;

  void emitir() {
    if (hayA && hayB) controlador.add(combinar(ultimoA as A, ultimoB as B));
  }

  controlador = StreamController<R>(
    onListen: () {
      subA = primero.listen(
        (valor) {
          ultimoA = valor;
          hayA = true;
          emitir();
        },
        onError: controlador.addError,
      );
      subB = segundo.listen(
        (valor) {
          ultimoB = valor;
          hayB = true;
          emitir();
        },
        onError: controlador.addError,
      );
    },
    onCancel: () async {
      await subA?.cancel();
      await subB?.cancel();
    },
  );

  return controlador.stream;
}
