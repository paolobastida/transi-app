import 'package:flutter/material.dart';

import '../dependencias.dart';

/// P10 · Cuenta y respaldo (U3 + U16).
class PantallaCuenta extends StatefulWidget {
  final String usuarioId;
  final String email;

  const PantallaCuenta({
    super.key,
    required this.usuarioId,
    required this.email,
  });

  @override
  State<PantallaCuenta> createState() => _PantallaCuentaState();
}

class _PantallaCuentaState extends State<PantallaCuenta> {
  Future<DateTime?>? _ultimo;
  Future<int>? _pendientes;
  bool _ocupado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _asignarFuturos();
  }

  void _asignarFuturos() {
    final servicio = Alcance.de(context).respaldo;
    _ultimo = servicio.ultimoRespaldo();
    _pendientes = servicio.pendientes();
  }

  void _recargar() => setState(_asignarFuturos);

  Future<void> _respaldar() async {
    setState(() => _ocupado = true);
    try {
      await Alcance.de(context).respaldo.respaldar(widget.usuarioId);
      if (mounted) _avisar('Respaldo listo');
    } catch (e) {
      if (mounted) _avisar('No se pudo respaldar: $e');
    } finally {
      if (mounted) {
        setState(() => _ocupado = false);
        _recargar();
      }
    }
  }

  Future<void> _restaurar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar respaldo'),
        content: const Text(
          'Se van a reemplazar los datos de este dispositivo con el último '
          'respaldo guardado. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (!mounted || confirmar != true) return;

    setState(() => _ocupado = true);
    try {
      await Alcance.de(context).respaldo.restaurar(widget.usuarioId);
      if (mounted) _avisar('Datos restaurados');
    } catch (e) {
      if (mounted) _avisar('No se pudo restaurar: $e');
    } finally {
      if (mounted) {
        setState(() => _ocupado = false);
        _recargar();
      }
    }
  }

  void _avisar(String mensaje) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta y respaldo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person),
            title: Text(widget.email),
            subtitle: const Text('Tu cuenta'),
          ),
          const Divider(),
          FutureBuilder<DateTime?>(
            future: _ultimo,
            builder: (context, snapshot) {
              final ultimo = snapshot.data;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history),
                title: const Text('Último respaldo'),
                subtitle: Text(
                  ultimo == null ? 'Todavía no respaldaste' : _fechaHora(ultimo),
                ),
              );
            },
          ),
          FutureBuilder<int>(
            future: _pendientes,
            builder: (context, snapshot) {
              final cantidad = snapshot.data;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cloud_queue),
                title: const Text('Pendientes de respaldar'),
                subtitle: Text(cantidad == null ? '…' : '$cantidad'),
              );
            },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _ocupado ? null : _respaldar,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Respaldar ahora'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _ocupado ? null : _restaurar,
            icon: const Icon(Icons.cloud_download),
            label: const Text('Restaurar'),
          ),
          const SizedBox(height: 16),
          const Text(
            'El respaldo guarda una copia completa de tus datos en el servidor. '
            'Usalo para pasar tu información a otro teléfono.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

String _fechaHora(DateTime fecha) =>
    '${fecha.year.toString().padLeft(4, '0')}-'
    '${fecha.month.toString().padLeft(2, '0')}-'
    '${fecha.day.toString().padLeft(2, '0')} '
    '${fecha.hour.toString().padLeft(2, '0')}:'
    '${fecha.minute.toString().padLeft(2, '0')}';
