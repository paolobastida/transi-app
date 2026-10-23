import 'package:flutter_test/flutter_test.dart';
import 'package:transi/presentacion/borrador_medicamento.dart';

/// El borrador quedó en su propio archivo: al no depender de la pantalla, se
/// puede probar solo, sin montar el formulario.
void main() {
  test('validar exige nombre, dosis y frecuencia (R6)', () {
    final b = BorradorMedicamento.vacio();
    addTearDown(b.dispose);

    expect(b.validar(), 'Falta el nombre del medicamento');
    b.nombre.text = 'Estradiol';
    expect(b.validar(), 'Falta la dosis');
    b.dosis.text = '2 mg';
    expect(b.validar(), 'Falta la frecuencia');
    b.frecuencia.text = 'cada día';
    expect(b.validar(), isNull);
  });

  test('dosisEstructurada separa cantidad y unidad si empieza con número', () {
    final b = BorradorMedicamento.vacio();
    addTearDown(b.dispose);

    b.dosis.text = '50 mg';
    expect(b.dosisEstructurada, (50.0, 'mg'));

    b.dosis.text = '1,5 comprimidos';
    expect(b.dosisEstructurada, (1.5, 'comprimidos'));

    b.dosis.text = 'una tableta';
    expect(b.dosisEstructurada, (null, null));
  });
}
