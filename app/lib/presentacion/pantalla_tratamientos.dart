import 'package:flutter/material.dart';

import '../dependencias.dart';
import '../dominio/tratamiento.dart';
import 'formulario_tratamiento.dart';
import 'tema.dart';

/// P4 · Tratamientos (activos / finalizados / todos).
class PantallaTratamientos extends StatefulWidget {
  final String usuarioId;

  const PantallaTratamientos({super.key, required this.usuarioId});

  @override
  State<PantallaTratamientos> createState() => _PantallaTratamientosState();
}

class _PantallaTratamientosState extends State<PantallaTratamientos> {
  String _filtro = 'activo';

  String? get _estado => _filtro == 'todos' ? null : _filtro;

  Future<void> _abrirFormulario([Tratamiento? tratamiento]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormularioTratamiento(
          usuarioId: widget.usuarioId,
          tratamiento: tratamiento,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repositorio = Alcance.de(context).tratamientos;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'activo', label: Text('Activos')),
                ButtonSegment(value: 'finalizado', label: Text('Finalizados')),
                ButtonSegment(value: 'todos', label: Text('Todos')),
              ],
              selected: {_filtro},
              onSelectionChanged: (seleccion) =>
                  setState(() => _filtro = seleccion.first),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Tratamiento>>(
              stream: repositorio.observar(widget.usuarioId, estado: _estado),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tratamientos = snapshot.data!;
                if (tratamientos.isEmpty) {
                  return const EstadoVacio(
                    icono: Icons.medication_outlined,
                    mensaje: 'No hay tratamientos todavía.\nTocá + para agregar uno.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: tratamientos.length,
                  itemBuilder: (context, indice) {
                    final t = tratamientos[indice];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondaryContainer,
                          child: Icon(
                            Icons.medication,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                        ),
                        title: Text(t.nombre),
                        subtitle: Text(
                            '${t.dosis} · ${t.frecuencia} · desde ${_fecha(t.fechaInicio)}'),
                        trailing: Chip(
                          label: Text(t.finalizado ? 'Finalizado' : 'Activo'),
                        ),
                        onTap: () => _abrirFormulario(t),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

String _fecha(DateTime fecha) =>
    '${fecha.year.toString().padLeft(4, '0')}-'
    '${fecha.month.toString().padLeft(2, '0')}-'
    '${fecha.day.toString().padLeft(2, '0')}';
