import 'cambio.dart';
import 'tratamiento.dart';

/// Tipo de evento de la línea de tiempo.
enum TipoEvento { tratamiento, cambio }

/// Un ítem de la línea de tiempo: o un tratamiento o un cambio.
/// La línea de tiempo **no es una tabla**: es una lectura que junta los dos.
class EventoTimeline {
  final TipoEvento tipo;
  final DateTime fecha;
  final String titulo;
  final String detalle;

  /// La entidad original (Tratamiento o Cambio) para abrir su detalle.
  final Object referencia;

  const EventoTimeline({
    required this.tipo,
    required this.fecha,
    required this.titulo,
    required this.detalle,
    required this.referencia,
  });

  Tratamiento? get tratamiento =>
      tipo == TipoEvento.tratamiento ? referencia as Tratamiento : null;

  Cambio? get cambio =>
      tipo == TipoEvento.cambio ? referencia as Cambio : null;
}
