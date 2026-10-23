import 'package:flutter_test/flutter_test.dart';
import 'package:transi/dominio/tratamiento.dart';

void main() {
  group('recordatorio de horas', () {
    test('horaTexto formatea como HH:mm', () {
      expect(horaTexto(0), '00:00');
      expect(horaTexto(8 * 60), '08:00');
      expect(horaTexto(13 * 60 + 5), '13:05');
      expect(horaTexto(23 * 60 + 59), '23:59');
    });

    test('horasTexto serializa y horasDesdeTexto parsea (ida y vuelta)', () {
      final minutos = [8 * 60, 20 * 60 + 30];
      final texto = horasTexto(minutos);
      expect(texto, '08:00,20:30');
      expect(horasDesdeTexto(texto), minutos);
    });

    test('horasDesdeTexto descarta basura y ordena sin repetir', () {
      expect(horasDesdeTexto('20:00, inválida, 08:00, 20:00, 25:00, 12:99'),
          [8 * 60, 20 * 60]);
      expect(horasDesdeTexto(null), isEmpty);
      expect(horasDesdeTexto(''), isEmpty);
    });
  });
}
