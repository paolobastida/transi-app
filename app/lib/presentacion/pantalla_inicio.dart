import 'package:flutter/material.dart';

import '../dependencias.dart';
import '../dominio/usuario.dart';
import 'pantalla_login.dart';
import 'pantalla_profesionales.dart';
import 'pantalla_tratamientos.dart';

/// Contenedor principal (P3–P5) con barra de navegación inferior.
class PantallaInicio extends StatefulWidget {
  final Usuario usuario;

  const PantallaInicio({super.key, required this.usuario});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  int _indice = 1;

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

  @override
  Widget build(BuildContext context) {
    final paginas = [
      const _LineaDeTiempoProvisional(),
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

class _LineaDeTiempoProvisional extends StatelessWidget {
  const _LineaDeTiempoProvisional();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Tu línea de tiempo (llega en la Fase 8)'));
  }
}
