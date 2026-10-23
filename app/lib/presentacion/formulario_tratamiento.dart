import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../dependencias.dart';
import '../dominio/tratamiento.dart';
import 'borrador_medicamento.dart';
import 'confirmaciones.dart';
import 'formato_fecha.dart';
import 'retroalimentacion.dart';

/// P6 · Alta / edición de tratamiento (U8/U9). Guarda **solo en la base local**.
///
/// Es **libre y general**: sirve para cualquier medicamento, con todos los
/// campos en texto libre. Se pueden cargar **varios medicamentos** de una
/// (cada uno queda como un tratamiento propio, compartiendo fechas y
/// profesional).
class FormularioTratamiento extends StatefulWidget {
  final String usuarioId;
  final Tratamiento? tratamiento;

  const FormularioTratamiento({
    super.key,
    required this.usuarioId,
    this.tratamiento,
  });

  @override
  State<FormularioTratamiento> createState() => _FormularioTratamientoState();
}

class _FormularioTratamientoState extends State<FormularioTratamiento> {
  final List<BorradorMedicamento> _medicamentos = [];

  DateTime _fechaInicio = DateTime.now();
  DateTime? _fechaFin;

  final _profesional = TextEditingController();
  final _especialidad = TextEditingController();

  bool get _editando => widget.tratamiento != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tratamiento;
    if (t != null) {
      _medicamentos.add(BorradorMedicamento.desdeTratamiento(t));
      _fechaInicio = t.fechaInicio;
      _fechaFin = t.fechaFin;
      _profesional.text = t.profesionalNombre ?? '';
      _especialidad.text = t.profesionalEspecialidad ?? '';
    } else {
      _medicamentos.add(BorradorMedicamento.vacio());
    }
  }

  @override
  void dispose() {
    for (final m in _medicamentos) {
      m.dispose();
    }
    _profesional.dispose();
    _especialidad.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha(bool esInicio) async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: (esInicio ? _fechaInicio : _fechaFin) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (elegida == null) return;
    setState(() {
      if (esInicio) {
        _fechaInicio = elegida;
      } else {
        _fechaFin = elegida;
      }
    });
  }

  String? get _profesionalGuardado {
    final t = _profesional.text.trim();
    return t.isEmpty ? null : t;
  }

  String? get _especialidadGuardada {
    final t = _especialidad.text.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _guardar() async {
    for (final m in _medicamentos) {
      m.error = m.validar();
    }
    final primerError =
        _medicamentos.map((m) => m.error).whereType<String>().firstOrNull;
    if (primerError != null) {
      setState(() {});
      mostrarError(context, primerError);
      return;
    }
    if (_fechaFin != null && _fechaFin!.isBefore(_fechaInicio)) {
      mostrarError(context, 'La fecha de fin no puede ser anterior a la de inicio');
      return;
    }

    final repositorio = Alcance.de(context).tratamientos;
    final recordatorios = Alcance.de(context).recordatorios;
    if (_medicamentos.any((m) => m.recordatorioMinutos.isNotEmpty)) {
      await recordatorios.solicitarAlarmasExactas();
    }

    if (_editando) {
      final m = _medicamentos.first;
      final (cantidad, unidad) = m.dosisEstructurada;
      final guardado = Tratamiento(
        id: widget.tratamiento!.id,
        usuarioId: widget.usuarioId,
        nombre: m.nombreGuardado,
        dosis: m.dosisGuardada,
        frecuencia: m.frecuenciaGuardada,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        via: m.viaGuardada,
        presentacion: m.presentacionGuardada,
        dosisCantidad: cantidad,
        dosisUnidad: unidad,
        indicacion: m.indicacionGuardada,
        profesionalNombre: _profesionalGuardado,
        profesionalEspecialidad: _especialidadGuardada,
        recordatorioMinutos: m.recordatorioMinutos,
      );
      await repositorio.actualizar(guardado);
      await recordatorios.programar(guardado);
    } else {
      for (final m in _medicamentos) {
        final (cantidad, unidad) = m.dosisEstructurada;
        final creado = await repositorio.crear(
          usuarioId: widget.usuarioId,
          nombre: m.nombreGuardado,
          dosis: m.dosisGuardada,
          frecuencia: m.frecuenciaGuardada,
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
          via: m.viaGuardada,
          presentacion: m.presentacionGuardada,
          dosisCantidad: cantidad,
          dosisUnidad: unidad,
          indicacion: m.indicacionGuardada,
          profesionalNombre: _profesionalGuardado,
          profesionalEspecialidad: _especialidadGuardada,
          recordatorioMinutos: m.recordatorioMinutos,
        );
        await recordatorios.programar(creado);
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _desactivar() async {
    final repositorio = Alcance.de(context).tratamientos;
    final recordatorios = Alcance.de(context).recordatorios;
    final confirmar = await confirmarOcultar(context, que: 'este tratamiento');
    if (!confirmar) return;
    await repositorio.desactivar(widget.tratamiento!.id, widget.usuarioId);
    await recordatorios.cancelar(widget.tratamiento!.id);
    if (mounted) Navigator.of(context).pop();
  }

  void _agregarMedicamento() {
    setState(() => _medicamentos.add(BorradorMedicamento.vacio()));
  }

  void _quitarMedicamento(int indice) {
    setState(() {
      _medicamentos.removeAt(indice).dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cuantos = _medicamentos.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar tratamiento' : 'Nuevo tratamiento'),
        actions: [
          if (_editando)
            IconButton(
              tooltip: 'Ocultar',
              onPressed: _desactivar,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          for (var i = 0; i < _medicamentos.length; i++) ...[
            _BloqueMedicamento(
              key: ObjectKey(_medicamentos[i]),
              borrador: _medicamentos[i],
              indice: i + 1,
              mostrarQuitar: !_editando && cuantos > 1,
              onQuitar: () => _quitarMedicamento(i),
            ),
            const SizedBox(height: 12),
          ],
          if (!_editando)
            OutlinedButton.icon(
              onPressed: _agregarMedicamento,
              icon: const Icon(Icons.add),
              label: const Text('Agregar otro medicamento'),
            ),
          const SizedBox(height: 24),
          _titulo(context, 'Fechas'),
          _FilaFecha(
            etiqueta: 'Inicio',
            fecha: _fechaInicio,
            onTap: () => _elegirFecha(true),
          ),
          _FilaFecha(
            etiqueta: 'Fin (opcional)',
            fecha: _fechaFin,
            textoVacio: 'Sin finalizar',
            onTap: () => _elegirFecha(false),
            onLimpiar: _fechaFin == null
                ? null
                : () => setState(() => _fechaFin = null),
          ),
          const SizedBox(height: 24),
          _titulo(context, 'Profesional (opcional)'),
          TextField(
            controller: _profesional,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              helperText: 'Ej. Dra. García',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _especialidad,
            decoration: const InputDecoration(
              labelText: 'Especialidad',
              helperText: 'Escribí lo que sea, o dejalo vacío',
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _guardar,
            icon: const Icon(Icons.check),
            label: Text(
              _editando
                  ? 'Guardar cambios'
                  : cuantos > 1
                      ? 'Guardar $cuantos medicamentos'
                      : 'Guardar',
            ),
          ),
        ),
      ),
    );
  }

  Widget _titulo(BuildContext context, String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          texto,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      );
}

/// Un bloque repetible de medicamento. Cada uno se convierte en un tratamiento.
class _BloqueMedicamento extends StatefulWidget {
  final BorradorMedicamento borrador;
  final int indice;
  final bool mostrarQuitar;
  final VoidCallback onQuitar;

  const _BloqueMedicamento({
    super.key,
    required this.borrador,
    required this.indice,
    required this.mostrarQuitar,
    required this.onQuitar,
  });

  @override
  State<_BloqueMedicamento> createState() => _BloqueMedicamentoState();
}

class _BloqueMedicamentoState extends State<_BloqueMedicamento> {
  BorradorMedicamento get b => widget.borrador;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Medicamento ${widget.indice}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (widget.mostrarQuitar)
                  IconButton(
                    tooltip: 'Quitar',
                    onPressed: widget.onQuitar,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: b.nombre,
              decoration: const InputDecoration(
                labelText: 'Nombre del medicamento',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: b.dosis,
              decoration: const InputDecoration(
                labelText: 'Dosis',
                helperText: 'Ej. 50 mg, 1 tableta, 1 parche',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: b.via,
              decoration: const InputDecoration(
                labelText: 'Vía (opcional)',
                helperText: 'Ej. oral, inyectable, transdérmica',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: b.frecuencia,
              decoration: const InputDecoration(
                labelText: 'Frecuencia',
                helperText: 'Ej. cada día, 2 veces por semana',
              ),
            ),
            if (!kIsWeb) ...[
              const SizedBox(height: 16),
              _RecordatorioHoras(borrador: b),
            ],
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                initiallyExpanded: b.detallesAbiertos,
                onExpansionChanged: (abierto) => b.detallesAbiertos = abierto,
                title: const Text('Más detalles (opcional)'),
                children: [
                  TextField(
                    controller: b.presentacion,
                    decoration: const InputDecoration(
                      labelText: 'Presentación',
                      helperText: 'Ej. cipionato 200 mg/mL, parche 0,1 mg/día',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: b.indicacion,
                    decoration: const InputDecoration(
                      labelText: 'Indicación',
                      helperText: 'Ej. feminización, bloqueo de andrógenos',
                    ),
                  ),
                ],
              ),
            ),
            if (b.error != null) ...[
              const SizedBox(height: 8),
              Text(
                b.error!,
                style: TextStyle(color: esquema.error, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Horas del recordatorio diario de un medicamento: chips eliminables +
/// botón para agregar una hora con el selector de hora del sistema.
class _RecordatorioHoras extends StatelessWidget {
  final BorradorMedicamento borrador;

  const _RecordatorioHoras({required this.borrador});

  Future<void> _agregarHora(BuildContext context) async {
    final elegida = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (elegida == null) return;
    final minutos = elegida.hour * 60 + elegida.minute;
    if (borrador.recordatorioMinutos.contains(minutos)) return;
    borrador.recordatorioMinutos = [
      ...borrador.recordatorioMinutos,
      minutos,
    ]..sort();
  }

  @override
  Widget build(BuildContext context) {
    return _HorasEditor(
      horas: borrador.recordatorioMinutos,
      onQuitar: (minutos) {
        borrador.recordatorioMinutos =
            List.of(borrador.recordatorioMinutos)..remove(minutos);
      },
      onAgregar: _agregarHora,
    );
  }
}

/// Chips de horas + "Agregar hora". El botón "Agregar" es un StatefulBuilder
/// para repintar sin setState del formulario completo.
class _HorasEditor extends StatelessWidget {
  final List<int> horas;
  final ValueChanged<int> onQuitar;
  final Future<void> Function(BuildContext) onAgregar;

  const _HorasEditor({
    required this.horas,
    required this.onQuitar,
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recordatorio (opcional)'),
          const SizedBox(height: 4),
          Text(
            'Te avisamos todos los días a las horas que elijas',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black.withValues(alpha: 0.55),
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in horas)
                Chip(
                  label: Text(horaTexto(m)),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    onQuitar(m);
                    setState(() {});
                  },
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Agregar hora'),
                onPressed: () async {
                  await onAgregar(context);
                  setState(() {});
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilaFecha extends StatelessWidget {
  final String etiqueta;
  final DateTime? fecha;
  final String textoVacio;
  final VoidCallback onTap;
  final VoidCallback? onLimpiar;

  const _FilaFecha({
    required this.etiqueta,
    required this.fecha,
    this.textoVacio = 'Elegir',
    required this.onTap,
    this.onLimpiar,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(etiqueta),
      subtitle: Text(fecha == null ? textoVacio : fechaTexto(fecha!)),
      trailing: fecha == null
          ? const Icon(Icons.calendar_today)
          : IconButton(icon: const Icon(Icons.clear), onPressed: onLimpiar),
      onTap: onTap,
    );
  }
}

extension _PrimeroNulo<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
