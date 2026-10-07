import 'package:flutter/material.dart';

import '../dependencias.dart';
import '../dominio/profesional.dart';
import '../dominio/tratamiento.dart';

/// P6 · Alta / edición de tratamiento (U8/U9). Guarda **solo en la base local**.
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
  final _nombre = TextEditingController();
  final _dosis = TextEditingController();
  final _frecuencia = TextEditingController();
  DateTime _fechaInicio = DateTime.now();
  DateTime? _fechaFin;
  String? _profesionalId;
  String? _error;
  Future<List<Profesional>>? _profesionales;

  bool get _editando => widget.tratamiento != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tratamiento;
    if (t != null) {
      _nombre.text = t.nombre;
      _dosis.text = t.dosis;
      _frecuencia.text = t.frecuencia;
      _fechaInicio = t.fechaInicio;
      _fechaFin = t.fechaFin;
      _profesionalId = t.profesionalId;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profesionales ??=
        Alcance.de(context).profesionales.observar(widget.usuarioId).first;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _dosis.dispose();
    _frecuencia.dispose();
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

  Future<void> _guardar() async {
    if (_nombre.text.trim().isEmpty ||
        _dosis.text.trim().isEmpty ||
        _frecuencia.text.trim().isEmpty) {
      setState(() => _error = 'Nombre, dosis y frecuencia son obligatorios');
      return;
    }
    if (_fechaFin != null && _fechaFin!.isBefore(_fechaInicio)) {
      setState(() => _error = 'La fecha de fin no puede ser anterior a la de inicio');
      return;
    }

    final repositorio = Alcance.de(context).tratamientos;
    if (_editando) {
      await repositorio.actualizar(Tratamiento(
        id: widget.tratamiento!.id,
        usuarioId: widget.usuarioId,
        nombre: _nombre.text.trim(),
        dosis: _dosis.text.trim(),
        frecuencia: _frecuencia.text.trim(),
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        profesionalId: _profesionalId,
      ));
    } else {
      await repositorio.crear(
        usuarioId: widget.usuarioId,
        nombre: _nombre.text.trim(),
        dosis: _dosis.text.trim(),
        frecuencia: _frecuencia.text.trim(),
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        profesionalId: _profesionalId,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _desactivar() async {
    await Alcance.de(context)
        .tratamientos
        .desactivar(widget.tratamiento!.id, widget.usuarioId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar tratamiento' : 'Nuevo tratamiento'),
        actions: [
          if (_editando)
            IconButton(
              tooltip: 'Desactivar',
              onPressed: _desactivar,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nombre,
            decoration: const InputDecoration(labelText: 'Nombre (ej. Estradiol)'),
          ),
          TextField(
            controller: _dosis,
            decoration: const InputDecoration(labelText: 'Dosis (ej. 2 mg)'),
          ),
          TextField(
            controller: _frecuencia,
            decoration: const InputDecoration(labelText: 'Frecuencia (ej. cada día)'),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fecha de inicio'),
            subtitle: Text(_fecha(_fechaInicio)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _elegirFecha(true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fecha de fin (opcional)'),
            subtitle: Text(_fechaFin == null ? 'Sin finalizar' : _fecha(_fechaFin!)),
            trailing: _fechaFin == null
                ? const Icon(Icons.calendar_today)
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _fechaFin = null),
                  ),
            onTap: () => _elegirFecha(false),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Profesional>>(
            future: _profesionales,
            builder: (context, snapshot) {
              final profesionales = snapshot.data ?? const <Profesional>[];
              return DropdownButtonFormField<String?>(
                initialValue: _profesionalId,
                decoration: const InputDecoration(labelText: 'Profesional (opcional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Ninguno')),
                  for (final p in profesionales)
                    DropdownMenuItem(value: p.id, child: Text(p.nombre)),
                ],
                onChanged: (valor) => setState(() => _profesionalId = valor),
              );
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: _guardar, child: const Text('Guardar')),
        ],
      ),
    );
  }
}

String _fecha(DateTime fecha) =>
    '${fecha.year.toString().padLeft(4, '0')}-'
    '${fecha.month.toString().padLeft(2, '0')}-'
    '${fecha.day.toString().padLeft(2, '0')}';
