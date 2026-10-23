import 'package:flutter/material.dart';

import '../dependencias.dart';
import '../dominio/tratamiento.dart';
import 'formato_fecha.dart';
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
                  return EstadoVacio(
                    icono: Icons.medication_outlined,
                    mensaje: 'No hay tratamientos todavía.',
                    etiquetaAccion: 'Agregar tratamiento',
                    onAccion: () => _abrirFormulario(),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: tratamientos.length,
                  itemBuilder: (context, indice) {
                    final t = tratamientos[indice];
                    final detalles = [
                      t.dosis,
                      if (t.via != null) t.via,
                      t.frecuencia,
                    ].join(' · ');
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
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$detalles · desde ${fechaTexto(t.fechaInicio)}'),
                            if (t.profesionalNombre != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_outline, size: 14),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        t.profesionalEspecialidad == null
                                            ? t.profesionalNombre!
                                            : '${t.profesionalNombre} · ${t.profesionalEspecialidad}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        trailing: EtiquetaEstado(activo: !t.finalizado),
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
