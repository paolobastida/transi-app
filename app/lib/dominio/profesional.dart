/// Ficha del equipo médico (versión de la app).
class Profesional {
  final String id;
  final String usuarioId;
  final String nombre;
  final String especialidad;
  final bool activo;

  const Profesional({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.especialidad,
    this.activo = true,
  });
}
