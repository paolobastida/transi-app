import 'package:flutter/material.dart';

import 'datos/api_client.dart';
import 'datos/autenticacion.dart';
import 'datos/base_local.dart';
import 'datos/cambio_repositorio.dart';
import 'datos/linea_de_tiempo.dart';
import 'datos/profesional_repositorio.dart';
import 'datos/respaldo.dart';
import 'datos/tratamiento_repositorio.dart';
import 'dependencias.dart';
import 'dominio/usuario.dart';
import 'presentacion/pantalla_inicio.dart';
import 'presentacion/pantalla_login.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // La base local es la fuente de verdad de la interfaz (offline-first).
  final base = BaseLocal();
  final tratamientos = TratamientoRepositorio(base);
  final cambios = CambioRepositorio(base);
  final dependencias = Dependencias(
    autenticacion: Autenticacion(),
    profesionales: ProfesionalRepositorio(base),
    tratamientos: tratamientos,
    cambios: cambios,
    lineaDeTiempo: LineaDeTiempo(cambios: cambios, tratamientos: tratamientos),
    respaldo: RespaldoServicio(base, RespaldoApi(ApiClient())),
  );

  runApp(TransiApp(dependencias: dependencias));
}

class TransiApp extends StatelessWidget {
  final Dependencias dependencias;

  const TransiApp({super.key, required this.dependencias});

  @override
  Widget build(BuildContext context) {
    return Alcance(
      dependencias: dependencias,
      child: MaterialApp(
        title: 'Transi',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        ),
        home: const PantallaArranque(),
      ),
    );
  }
}

/// Decide con qué pantalla arrancar: si ya hay sesión guardada, va al inicio
/// (sin usar red); si no, pide entrar.
class PantallaArranque extends StatefulWidget {
  const PantallaArranque({super.key});

  @override
  State<PantallaArranque> createState() => _PantallaArranqueState();
}

class _PantallaArranqueState extends State<PantallaArranque> {
  Future<Usuario?>? _sesion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sesion ??= Alcance.de(context).autenticacion.sesionActual();
  }

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
          return PantallaInicio(usuario: usuario);
        }
        return PantallaLogin(autenticacion: Alcance.de(context).autenticacion);
      },
    );
  }
}
