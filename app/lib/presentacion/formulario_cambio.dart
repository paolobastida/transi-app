import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';

import '../dependencias.dart';
import '../dominio/cambio.dart';

/// P8 · Registrar cambio (U12). Descripción + foto + nota de voz.
/// Guarda **solo en la base local**: nunca espera a la red.
class FormularioCambio extends StatefulWidget {
  final String usuarioId;

  const FormularioCambio({super.key, required this.usuarioId});

  @override
  State<FormularioCambio> createState() => _FormularioCambioState();
}

class _FormularioCambioState extends State<FormularioCambio> {
  final _descripcion = TextEditingController();
  final _picker = ImagePicker();
  final _grabadora = AudioRecorder();
  final List<EntradaAdjunto> _adjuntos = [];
  DateTime _fecha = DateTime.now();
  String? _error;

  bool _grabando = false;
  StreamSubscription<Uint8List>? _suscripcion;
  final List<int> _bufferAudio = [];
  Completer<void>? _finGrabacion;

  @override
  void dispose() {
    _suscripcion?.cancel();
    _grabadora.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // R3: no se permite fecha futura
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  Future<void> _agregarFoto() async {
    final foto = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (foto == null) return;
    final bytes = await foto.readAsBytes();
    setState(() => _adjuntos.add(
          EntradaAdjunto(tipo: 'foto', nombre: foto.name, contenido: bytes),
        ));
  }

  Future<void> _alternarGrabacion() async {
    if (_grabando) {
      await _detenerGrabacion();
    } else {
      await _iniciarGrabacion();
    }
  }

  Future<void> _iniciarGrabacion() async {
    if (!await _grabadora.hasPermission()) {
      setState(() => _error = 'Necesito permiso para usar el micrófono');
      return;
    }
    _bufferAudio.clear();
    final fin = Completer<void>();
    _finGrabacion = fin;
    final stream = await _grabadora.startStream(const RecordConfig());
    _suscripcion = stream.listen(
      _bufferAudio.addAll,
      onDone: () {
        if (!fin.isCompleted) fin.complete();
      },
      onError: (_) {
        if (!fin.isCompleted) fin.complete();
      },
    );
    setState(() {
      _grabando = true;
      _error = null;
    });
  }

  Future<void> _detenerGrabacion() async {
    await _grabadora.stop();
    await _finGrabacion?.future;
    await _suscripcion?.cancel();
    final bytes = Uint8List.fromList(_bufferAudio);
    setState(() {
      _grabando = false;
      if (bytes.isNotEmpty) {
        _adjuntos.add(
          EntradaAdjunto(tipo: 'audio', nombre: 'nota.m4a', contenido: bytes),
        );
      }
    });
  }

  Future<void> _guardar() async {
    if (_descripcion.text.trim().isEmpty && _adjuntos.isEmpty) {
      setState(() => _error = 'Escribí algo o agregá una foto o nota de voz');
      return;
    }
    await Alcance.de(context).cambios.crear(
          usuarioId: widget.usuarioId,
          fecha: _fecha,
          descripcion: _descripcion.text.trim(),
          adjuntos: _adjuntos,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo cambio')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fecha'),
            subtitle: Text(_fechaTexto(_fecha)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _elegirFecha,
          ),
          TextField(
            controller: _descripcion,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '¿Qué notaste?',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _agregarFoto,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Foto'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _alternarGrabacion,
                  icon: Icon(_grabando ? Icons.stop : Icons.mic),
                  label: Text(_grabando ? 'Detener' : 'Voz'),
                ),
              ),
            ],
          ),
          if (_grabando)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Grabando…', style: TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 12),
          for (var i = 0; i < _adjuntos.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_adjuntos[i].tipo == 'foto' ? Icons.image : Icons.audiotrack),
              title: Text(_adjuntos[i].nombre),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _adjuntos.removeAt(i)),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: _guardar, child: const Text('Guardar')),
        ],
      ),
    );
  }
}

String _fechaTexto(DateTime fecha) =>
    '${fecha.year.toString().padLeft(4, '0')}-'
    '${fecha.month.toString().padLeft(2, '0')}-'
    '${fecha.day.toString().padLeft(2, '0')}';
