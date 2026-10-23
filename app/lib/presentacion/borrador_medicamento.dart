import 'package:flutter/widgets.dart';

import '../dominio/tratamiento.dart';

/// Dosis guardada como texto libre; si empieza con un número, también se
/// guarda la parte estructurada (cantidad + unidad) para sincronizar.
final _dosisInicial = RegExp(r'^(\d+(?:[.,]\d+)?)\s*(.*)$');

/// Borrador editable de **un** medicamento dentro del formulario de tratamiento.
///
/// Es el estado del formulario, separado de la interfaz: los `TextField` leen y
/// escriben estos controladores, y [validar] concentra las reglas de R6. Tenerlo
/// aparte permite razonar (y probar) el borrador sin montar la pantalla.
class BorradorMedicamento {
  final nombre = TextEditingController();
  final dosis = TextEditingController();
  final via = TextEditingController();
  final frecuencia = TextEditingController();
  final presentacion = TextEditingController();
  final indicacion = TextEditingController();

  bool detallesAbiertos = false;
  String? error;

  /// Horas del recordatorio diario, en minutos desde medianoche.
  List<int> recordatorioMinutos = [];

  BorradorMedicamento.desdeTratamiento(Tratamiento t) {
    nombre.text = t.nombre;
    dosis.text = t.dosis;
    via.text = t.via ?? '';
    frecuencia.text = t.frecuencia;
    presentacion.text = t.presentacion ?? '';
    indicacion.text = t.indicacion ?? '';
    recordatorioMinutos = List.of(t.recordatorioMinutos);
  }

  BorradorMedicamento.vacio();

  void dispose() {
    nombre.dispose();
    dosis.dispose();
    via.dispose();
    frecuencia.dispose();
    presentacion.dispose();
    indicacion.dispose();
  }

  String get nombreGuardado => nombre.text.trim();

  String get dosisGuardada => dosis.text.trim();

  String get frecuenciaGuardada => frecuencia.text.trim();

  String? _oNull(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  String? get viaGuardada => _oNull(via);

  String? get presentacionGuardada => _oNull(presentacion);

  String? get indicacionGuardada => _oNull(indicacion);

  /// Extrae cantidad y unidad si la dosis empieza con un número
  /// (ej. "50 mg" → 50 + "mg"); si no, devuelve nulls.
  (double?, String?) get dosisEstructurada {
    final m = _dosisInicial.firstMatch(dosisGuardada);
    if (m == null) return (null, null);
    final cantidad = double.tryParse(m.group(1)!.replaceAll(',', '.'));
    final unidad = m.group(2)!.trim();
    return (cantidad, unidad.isEmpty ? null : unidad);
  }

  /// Valida R6 y devuelve el motivo del primer problema (o null si está bien).
  String? validar() {
    if (nombreGuardado.isEmpty) return 'Falta el nombre del medicamento';
    if (dosisGuardada.isEmpty) return 'Falta la dosis';
    if (frecuenciaGuardada.isEmpty) return 'Falta la frecuencia';
    return null;
  }
}
