import 'package:flutter/material.dart';

void main() {
  runApp(const TransiApp());
}

/// Raíz de la app. En la Fase 5 se reemplaza por las pantallas P1–P10.
class TransiApp extends StatelessWidget {
  const TransiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const PantallaInicio(),
    );
  }
}

/// Pantalla mínima de cimientos: acá irá la línea de tiempo (P3).
class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transi')),
      body: const Center(
        child: Text('Acá va tu línea de tiempo'),
      ),
    );
  }
}
