import 'package:flutter/material.dart';

/// Pide confirmación antes de ocultar (desactivar) un registro.
///
/// El dominio dice que el historial nunca se borra físicamente: el copy lo
/// aclara para que la persona se sienta tranquila. Devuelve `true` si confirma.
Future<bool> confirmarOcultar(
  BuildContext context, {
  required String que,
}) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Ocultar $que'),
      content: Text(
        'Se va a ocultar de tus listas. Tus datos no se borran: '
        'quedan guardados por si querés volver a verlos.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Ocultar'),
        ),
      ],
    ),
  );
  return confirmar == true;
}
