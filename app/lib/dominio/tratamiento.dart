/// Tratamiento (versión de la app). `fechaFin` nulo = activo.
///
/// `nombre`, `dosis` y `frecuencia` son **texto** y siguen siendo obligatorios
/// (R6): los registros antiguos los traen poblados y no se tocan.
///
/// Todo lo demás es **opcional**: vía, presentación, dosis estructurada,
/// indicación, y el profesional que lo indicó (nombre + especialidad como
/// texto, sin entidad aparte).
class Tratamiento {
  final String id;
  final String usuarioId;
  final String nombre;
  final String dosis;
  final String frecuencia;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final bool activo;

  // --- Campos opcionales ---
  final String? via;
  final String? presentacion;
  final double? dosisCantidad;
  final String? dosisUnidad;
  final String? indicacion;
  final String? profesionalNombre;
  final String? profesionalEspecialidad;

  /// Horas del recordatorio diario, en minutos desde medianoche (0–1439),
  /// ordenadas y sin repetir. Vacío = sin recordatorio.
  final List<int> recordatorioMinutos;

  const Tratamiento({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.dosis,
    required this.frecuencia,
    required this.fechaInicio,
    this.fechaFin,
    this.activo = true,
    this.via,
    this.presentacion,
    this.dosisCantidad,
    this.dosisUnidad,
    this.indicacion,
    this.profesionalNombre,
    this.profesionalEspecialidad,
    this.recordatorioMinutos = const [],
  });

  bool get finalizado => fechaFin != null;
}

/// Formatea minutos desde medianoche como "HH:mm" (ej. 480 → "08:00").
String horaTexto(int minutos) =>
    '${(minutos ~/ 60).toString().padLeft(2, '0')}:'
    '${(minutos % 60).toString().padLeft(2, '0')}';

/// Serializa los minutos del recordatorio para guardarlos ("08:00,20:00").
String horasTexto(List<int> minutos) =>
    minutos.map(horaTexto).join(',');

/// Parsea "08:00,20:00" a minutos del día, descartando lo inválido,
/// ordenado y sin repetidos. Vacío o null → lista vacía.
List<int> horasDesdeTexto(String? texto) {
  if (texto == null || texto.trim().isEmpty) return const [];
  final resultado = <int>{};
  for (final parte in texto.split(',')) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(parte.trim());
    if (m == null) continue;
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    if (h > 23 || min > 59) continue;
    resultado.add(h * 60 + min);
  }
  final lista = resultado.toList()..sort();
  return lista;
}
