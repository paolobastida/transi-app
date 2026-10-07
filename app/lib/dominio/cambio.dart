import 'dart:typed_data';

/// Un adjunto de un cambio: foto o nota de voz, con su contenido en bytes.
class Adjunto {
  final String id;
  final String cambioId;
  final String tipo; // 'foto' | 'audio'
  final String nombre;
  final Uint8List contenido;

  const Adjunto({
    required this.id,
    required this.cambioId,
    required this.tipo,
    required this.nombre,
    required this.contenido,
  });

  bool get esFoto => tipo == 'foto';
  bool get esAudio => tipo == 'audio';
}

/// Datos que llegan al registrar un cambio (antes de tener id).
class EntradaAdjunto {
  final String tipo;
  final String nombre;
  final Uint8List contenido;

  const EntradaAdjunto({
    required this.tipo,
    required this.nombre,
    required this.contenido,
  });
}

/// Cambio (hecho físico) documentado en una fecha.
class Cambio {
  final String id;
  final String usuarioId;
  final DateTime fecha;
  final String descripcion;
  final bool activo;
  final List<Adjunto> adjuntos;

  const Cambio({
    required this.id,
    required this.usuarioId,
    required this.fecha,
    required this.descripcion,
    this.activo = true,
    this.adjuntos = const [],
  });
}
