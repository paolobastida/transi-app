import 'package:flutter/material.dart';

import '../dependencias.dart';
import '../dominio/profesional.dart';
import 'formulario_profesional.dart';
import 'tema.dart';

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
            return const EstadoVacio(
              icono: Icons.people_outline,
              mensaje: 'No hay profesionales todavía.\nTocá + para agregar uno.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: profesionales.length,
            itemBuilder: (context, indice) {
              final p = profesionales[indice];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(p.nombre),
                  subtitle: Text(p.especialidad),
                  onTap: () => _abrirFormulario(context, p),
                ),
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
