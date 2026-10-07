import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transi/datos/autenticacion.dart';
import 'package:transi/presentacion/pantalla_login.dart';
import 'package:transi/presentacion/pantalla_registro.dart';

void main() {
  testWidgets('P2 · login muestra email, contraseña y acceso a registro',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PantallaLogin(autenticacion: Autenticacion())),
    );

    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Contraseña'), findsOneWidget);
    expect(find.text('¿No tenés cuenta? Crear una'), findsOneWidget);
  });

  testWidgets('P1 · registro pide email y contraseña', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PantallaRegistro(autenticacion: Autenticacion())),
    );

    expect(find.text('Crear cuenta'), findsWidgets);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Contraseña'), findsOneWidget);
  });
}
