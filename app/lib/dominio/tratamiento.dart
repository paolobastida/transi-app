/// Tratamiento (versión de la app). `fechaFin` nulo = activo.
class Tratamiento {
  final String id;
  final String usuarioId;
  final String nombre;
  final String dosis;
  final String frecuencia;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String? profesionalId;
  final bool activo;

  const Tratamiento({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.dosis,
    required this.frecuencia,
    required this.fechaInicio,
    this.fechaFin,
    this.profesionalId,
    this.activo = true,
  });

  bool get finalizado => fechaFin != null;
}
