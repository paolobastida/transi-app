import 'package:flutter/material.dart';

/// Aviso neutro y flotante (éxito de acciones, información breve).
void mostrarMensaje(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

/// Aviso de error consistente: mismo estilo en toda la app.
void mostrarError(BuildContext context, String mensaje) {
  final esquema = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(mensaje, style: TextStyle(color: esquema.onError)),
        backgroundColor: esquema.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
}
