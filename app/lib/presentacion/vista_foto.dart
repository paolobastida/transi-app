import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Muestra un adjunto de foto con una altura máxima razonable, para que una
/// imagen vertical no ocupe toda la pantalla.
class VistaFoto extends StatelessWidget {
  final Uint8List contenido;
  final double altoMaximo;

  const VistaFoto({
    super.key,
    required this.contenido,
    this.altoMaximo = 280,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: altoMaximo),
        child: Image.memory(
          contenido,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      ),
    );
  }
}
