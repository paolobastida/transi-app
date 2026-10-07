import 'package:flutter/material.dart';

import '../dependencias.dart';
import '../dominio/cambio.dart';
import '../dominio/usuario.dart';
import 'formulario_cambio.dart';
import 'pantalla_detalle_cambio.dart';
import 'pantalla_login.dart';
import 'pantalla_profesionales.dart';
import 'pantalla_tratamientos.dart';

/// Contenedor principal con barra de navegación y el botón "Registrar cambio".
class PantallaInicio extends StatefulWidget {
  final Usuario usuario;

  const PantallaInicio({super.key, required this.usuario});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  int _indice = 0;

  Future<void> _salir() async {
    final dependencias = Alcance.de(context);
    await dependencias.autenticacion.salir();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => PantallaLogin(autenticacion: dependencias.autenticacion),
      ),
      (ruta) => false,
    );
  }

  Future<void> _registrarCambio() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormularioCambio(usuarioId: widget.usuario.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paginas = [
      _LineaDeTiempo(usuarioId: widget.usuario.id),
      PantallaTratamientos(usuarioId: widget.usuario.id),
      PantallaProfesionales(usuarioId: widget.usuario.id),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transi'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión (${widget.usuario.email})',
            onPressed: _salir,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: paginas[_indice],
      floatingActionButton: _indice == 0
          ? FloatingActionButton.extended(
              onPressed: _registrarCambio,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Registrar cambio'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (indice) => setState(() => _indice = indice),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.timeline), label: 'Línea de tiempo'),
          NavigationDestination(icon: Icon(Icons.medication), label: 'Tratamientos'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Profesionales'),
        ],
      ),
    );
  }
}

/// P3 provisional: por ahora lista los cambios. La línea de tiempo completa
/// (tratamientos + cambios unidos por fecha) llega en la Fase 8.
class _LineaDeTiempo extends StatelessWidget {
  final String usuarioId;

  const _LineaDeTiempo({required this.usuarioId});

  @override
  Widget build(BuildContext context) {
    final repositorio = Alcance.de(context).cambios;

    return StreamBuilder<List<Cambio>>(
      stream: repositorio.observar(usuarioId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final cambios = snapshot.data!;
        if (cambios.isEmpty) {
          return const Center(
            child: Text('Todavía no registraste cambios.\nTocá "Registrar cambio".'),
          );
        }
        return ListView.builder(
          itemCount: cambios.length,
          itemBuilder: (context, indice) {
            final cambio = cambios[indice];
            return ListTile(
              leading: Icon(_iconoDe(cambio)),
              title: Text(
                cambio.descripcion.isEmpty ? 'Cambio' : cambio.descripcion,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(_fechaTexto(cambio.fecha)),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PantallaDetalleCambio(cambio: cambio),
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _iconoDe(Cambio cambio) {
    if (cambio.adjuntos.any((a) => a.esFoto)) return Icons.photo;
    if (cambio.adjuntos.isNotEmpty) return Icons.mic;
    return Icons.notes;
  }
}

String _fechaTexto(DateTime fecha) =>
    '${fecha.year.toString().padLeft(4, '0')}-'
    '${fecha.month.toString().padLeft(2, '0')}-'
    '${fecha.day.toString().padLeft(2, '0')}';
