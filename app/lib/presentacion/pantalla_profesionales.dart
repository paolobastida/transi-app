import 'package:flutter/material.dart';

import '../dependencias.dart';
import '../dominio/profesional.dart';
import 'formulario_profesional.dart';

/// P5 · Profesionales.
class PantallaProfesionales extends StatelessWidget {
  final String usuarioId;

  const PantallaProfesionales({super.key, required this.usuarioId});

  Future<void> _abrirFormulario(
    BuildContext context, [
    Profesional? profesional,
  ]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormularioProfesional(
          usuarioId: usuarioId,
          profesional: profesional,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repositorio = Alcance.de(context).profesionales;

    return Scaffold(
      body: StreamBuilder<List<Profesional>>(
        stream: repositorio.observar(usuarioId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profesionales = snapshot.data!;
          if (profesionales.isEmpty) {
            return const Center(
              child: Text('No hay profesionales todavía.\nTocá + para agregar uno.'),
            );
          }
          return ListView.builder(
            itemCount: profesionales.length,
            itemBuilder: (context, indice) {
              final p = profesionales[indice];
              return ListTile(
                title: Text(p.nombre),
                subtitle: Text(p.especialidad),
                onTap: () => _abrirFormulario(context, p),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
