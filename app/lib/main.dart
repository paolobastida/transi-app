import 'dart:async';

import 'package:flutter/material.dart';

import 'datos/api_client.dart';
import 'datos/autenticacion.dart';
import 'datos/base_local.dart';
import 'datos/cambio_repositorio.dart';
import 'datos/linea_de_tiempo.dart';
import 'datos/recordatorios.dart';
import 'datos/respaldo.dart';
import 'datos/tratamiento_repositorio.dart';
import 'dependencias.dart';
import 'dominio/usuario.dart';
import 'presentacion/pantalla_inicio.dart';
import 'presentacion/pantalla_login.dart';
import 'presentacion/tema.dart';

import 'config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // En un build de publicación el servidor tiene que ser HTTPS: en claro
  // viajarían la contraseña, los tokens y los respaldos con fotos y notas de
  // voz. Solo se permite HTTP cuando se compila en modo debug (desarrollo
  // contra el servidor local).
  assert(
    Config.enDebug || Config.apiBaseUrl.startsWith('https://'),
    'API_BASE_URL debe ser https:// en un build de publicación. Se recibió: '
    '${Config.apiBaseUrl}',
  );

  // La base local es la fuente de verdad de la interfaz (offline-first).
  final base = BaseLocal();
  final tratamientos = TratamientoRepositorio(base);
  final cambios = CambioRepositorio(base);
  final recordatorios = RecordatorioServicio(base);
  // En web el servicio no hace nada (las notificaciones locales no existen).
  await recordatorios.iniciar();
  // Vuelve a programar los avisos guardados (app actualizada, celular
  // reiniciado, etc.). No bloquea el arranque.
  unawaited(recordatorios.reprogramarTodos());
  final dependencias = Dependencias(
    autenticacion: Autenticacion(base: base),
    tratamientos: tratamientos,
    cambios: cambios,
    lineaDeTiempo: LineaDeTiempo(cambios: cambios, tratamientos: tratamientos),
    respaldo: RespaldoServicio(base, RespaldoApi(ApiClient())),
    recordatorios: recordatorios,
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
        theme: temaTransi(),
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
