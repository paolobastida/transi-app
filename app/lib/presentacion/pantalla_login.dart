import 'package:flutter/material.dart';

import '../datos/autenticacion.dart';
import 'pantalla_inicio.dart';
import 'pantalla_registro.dart';
import 'tema.dart';

/// P1 · Login (U2). Requiere red.
class PantallaLogin extends StatefulWidget {
  final Autenticacion autenticacion;

  const PantallaLogin({super.key, required this.autenticacion});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _email = TextEditingController();
  final _clave = TextEditingController();
  bool _cargando = false;
  bool _verClave = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final usuario = await widget.autenticacion.entrar(_email.text, _clave.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PantallaInicio(usuario: usuario)),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: degradadoBandera(),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const EncabezadoTransi(
                            subtitulo: 'Tu tratamiento, en tus palabras'),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _clave,
                          obscureText: !_verClave,
                          onSubmitted: (_) => _entrar(),
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            suffixIcon: IconButton(
                              tooltip: _verClave
                                  ? 'Ocultar contraseña'
                                  : 'Mostrar contraseña',
                              onPressed: () =>
                                  setState(() => _verClave = !_verClave),
                              icon: Icon(_verClave
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _cargando ? null : _entrar,
                          child: _cargando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Entrar'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _cargando
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PantallaRegistro(autenticacion: widget.autenticacion),
                                    ),
                                  ),
                          child: const Text('¿No tenés cuenta? Crear una'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
