import 'package:flutter/material.dart';

import '../dependencias.dart';
import '../dominio/profesional.dart';

/// P7 · Alta / edición de profesional (U4/U6). Guarda solo en la base local.
class FormularioProfesional extends StatefulWidget {
  final String usuarioId;
  final Profesional? profesional;

  const FormularioProfesional({
    super.key,
    required this.usuarioId,
    this.profesional,
  });

  @override
  State<FormularioProfesional> createState() => _FormularioProfesionalState();
}

class _FormularioProfesionalState extends State<FormularioProfesional> {
  final _nombre = TextEditingController();
  final _especialidad = TextEditingController();
  String? _error;

  bool get _editando => widget.profesional != null;

  @override
  void initState() {
    super.initState();
    final p = widget.profesional;
    if (p != null) {
      _nombre.text = p.nombre;
      _especialidad.text = p.especialidad;
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _especialidad.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nombre.text.trim().isEmpty || _especialidad.text.trim().isEmpty) {
      setState(() => _error = 'Nombre y especialidad son obligatorios');
      return;
    }
    final repositorio = Alcance.de(context).profesionales;
    if (_editando) {
      await repositorio.actualizar(Profesional(
        id: widget.profesional!.id,
        usuarioId: widget.usuarioId,
        nombre: _nombre.text.trim(),
        especialidad: _especialidad.text.trim(),
      ));
    } else {
      await repositorio.crear(
        usuarioId: widget.usuarioId,
        nombre: _nombre.text.trim(),
        especialidad: _especialidad.text.trim(),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _desactivar() async {
    await Alcance.de(context)
        .profesionales
        .desactivar(widget.profesional!.id, widget.usuarioId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar profesional' : 'Nuevo profesional'),
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
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          TextField(
            controller: _especialidad,
            decoration: const InputDecoration(labelText: 'Especialidad'),
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
