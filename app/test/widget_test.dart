import 'package:flutter_test/flutter_test.dart';

import 'package:transi/main.dart';

void main() {
  testWidgets('la pantalla de inicio muestra el título de Transi', (tester) async {
    await tester.pumpWidget(const TransiApp());

    expect(find.text('Transi'), findsOneWidget);
    expect(find.text('Acá va tu línea de tiempo'), findsOneWidget);
  });
}
