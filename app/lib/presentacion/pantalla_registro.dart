import 'package:flutter/material.dart';

import '../datos/autenticacion.dart';
import 'pantalla_inicio.dart';
import 'tema.dart';

/// P1 · Registro (U1). Al crear la cuenta, entra directo.
class PantallaRegistro extends StatefulWidget {
  final Autenticacion autenticacion;

  const PantallaRegistro({super.key, required this.autenticacion});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
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

  Future<void> _crear() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await widget.autenticacion.registrar(_email.text, _clave.text);
      final usuario = await widget.autenticacion.entrar(_email.text, _clave.text);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => PantallaInicio(usuario: usuario)),
        (ruta) => false,
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
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: FranjaTrans(alto: 2),
        ),
      ),
      extendBodyBehindAppBar: true,
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
                            subtitulo: 'Empezá a registrar tu evolución'),
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
                          onSubmitted: (_) => _crear(),
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            helperText: 'Al menos 8 caracteres',
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
                          onPressed: _cargando ? null : _crear,
                          child: _cargando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Crear cuenta'),
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
