import 'package:flutter/material.dart';

import 'datos/autenticacion.dart';
import 'dominio/usuario.dart';
import 'presentacion/pantalla_inicio.dart';
import 'presentacion/pantalla_login.dart';

void main() {
  runApp(TransiApp(autenticacion: Autenticacion()));
}

class TransiApp extends StatelessWidget {
  final Autenticacion autenticacion;

  const TransiApp({super.key, required this.autenticacion});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: PantallaArranque(autenticacion: autenticacion),
    );
  }
}

/// Decide con qué pantalla arrancar: si ya hay sesión guardada, va al inicio;
/// si no, pide entrar.
class PantallaArranque extends StatefulWidget {
  final Autenticacion autenticacion;

  const PantallaArranque({super.key, required this.autenticacion});

  @override
  State<PantallaArranque> createState() => _PantallaArranqueState();
}

class _PantallaArranqueState extends State<PantallaArranque> {
  late final Future<Usuario?> _sesion = widget.autenticacion.sesionActual();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Usuario?>(
      future: _sesion,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final usuario = snapshot.data;
        if (usuario != null) {
          return PantallaInicio(
            autenticacion: widget.autenticacion,
            usuario: usuario,
          );
        }
        return PantallaLogin(autenticacion: widget.autenticacion);
      },
    );
  }
}
