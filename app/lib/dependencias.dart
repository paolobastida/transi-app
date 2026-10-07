import 'package:flutter/widgets.dart';

import 'datos/autenticacion.dart';
import 'datos/cambio_repositorio.dart';
import 'datos/linea_de_tiempo.dart';
import 'datos/profesional_repositorio.dart';
import 'datos/tratamiento_repositorio.dart';

/// Reúne las dependencias de la app y las pone a disposición del árbol de
/// widgets. Evita pasar cada repositorio por constructor a cada pantalla.
class Dependencias {
  final Autenticacion autenticacion;
  final ProfesionalRepositorio profesionales;
  final TratamientoRepositorio tratamientos;
  final CambioRepositorio cambios;
  final LineaDeTiempo lineaDeTiempo;

  const Dependencias({
    required this.autenticacion,
    required this.profesionales,
    required this.tratamientos,
    required this.cambios,
    required this.lineaDeTiempo,
  });
}

/// Acceso a las dependencias desde cualquier pantalla: `Alcance.de(context)`.
class Alcance extends InheritedWidget {
  final Dependencias dependencias;

  const Alcance({super.key, required this.dependencias, required super.child});

  static Dependencias de(BuildContext context) {
    final alcance = context.dependOnInheritedWidgetOfExactType<Alcance>();
    assert(alcance != null, 'Falta un Alcance en el árbol de widgets');
    return alcance!.dependencias;
  }

  @override
  bool updateShouldNotify(Alcance anterior) =>
      anterior.dependencias != dependencias;
}
