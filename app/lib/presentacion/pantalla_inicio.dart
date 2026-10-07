import 'package:flutter/material.dart';

import '../datos/autenticacion.dart';
import '../dominio/usuario.dart';
import 'pantalla_login.dart';

/// Pantalla principal provisional. En la Fase 6 se reemplaza por la línea de
/// tiempo (P3) con la barra de navegación.
class PantallaInicio extends StatelessWidget {
  final Autenticacion autenticacion;
  final Usuario usuario;

  const PantallaInicio({
    super.key,
    required this.autenticacion,
    required this.usuario,
  });

  Future<void> _salir(BuildContext context) async {
    await autenticacion.salir();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => PantallaLogin(autenticacion: autenticacion)),
      (ruta) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transi'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => _salir(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hola, ${usuario.email}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Acá va tu línea de tiempo'),
          ],
        ),
      ),
    );
  }
}
