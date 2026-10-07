import 'package:flutter/material.dart';

import '../dependencias.dart';
import '../dominio/usuario.dart';
import 'formulario_cambio.dart';
import 'pantalla_cuenta.dart';
import 'pantalla_linea_de_tiempo.dart';
import 'pantalla_login.dart';
import 'pantalla_profesionales.dart';
import 'pantalla_tratamientos.dart';
import 'tema.dart';

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
      PantallaLineaDeTiempo(usuarioId: widget.usuario.id),
      PantallaTratamientos(usuarioId: widget.usuario.id),
      PantallaProfesionales(usuarioId: widget.usuario.id),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transi'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: FranjaTrans(alto: 4),
        ),
        actions: [
          IconButton(
            tooltip: 'Cuenta y respaldo',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PantallaCuenta(
                  usuarioId: widget.usuario.id,
                  email: widget.usuario.email,
                ),
              ),
            ),
            icon: const Icon(Icons.cloud),
          ),
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
