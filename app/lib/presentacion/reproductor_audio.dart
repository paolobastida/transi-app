import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// Reproductor de una nota de voz guardada en memoria (bytes).
/// Funciona igual en móvil y en navegador gracias a `setSourceBytes`.
class ReproductorAudio extends StatefulWidget {
  final Uint8List contenido;

  const ReproductorAudio({super.key, required this.contenido});

  @override
  State<ReproductorAudio> createState() => _ReproductorAudioState();
}

class _ReproductorAudioState extends State<ReproductorAudio> {
  final _player = AudioPlayer();
  Duration _posicion = Duration.zero;
  Duration _duracion = Duration.zero;
  bool _sonando = false;
  bool _listo = false;

  @override
  void initState() {
    super.initState();
    _preparar();
  }

  Future<void> _preparar() async {
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duracion = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _posicion = p);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _sonando = false;
          _posicion = Duration.zero;
        });
      }
    });
    try {
      await _player.setSourceBytes(widget.contenido);
      if (mounted) setState(() => _listo = true);
    } catch (_) {
      if (mounted) setState(() => _listo = true);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _alternar() async {
    if (_sonando) {
      await _player.pause();
      if (mounted) setState(() => _sonando = false);
    } else {
      await _player.resume();
      if (mounted) setState(() => _sonando = true);
    }
  }

  Future<void> _buscar(double milisegundos) async {
    final destino = Duration(milliseconds: milisegundos.round());
    await _player.seek(destino);
    if (mounted) setState(() => _posicion = destino);
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final maxMs = _duracion.inMilliseconds == 0
        ? 1.0
        : _duracion.inMilliseconds.toDouble();
    final valorMs = _posicion.inMilliseconds.toDouble().clamp(0.0, maxMs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: esquema.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _listo ? _alternar : null,
            tooltip: _sonando ? 'Pausar' : 'Reproducir',
            icon: Icon(_sonando ? Icons.pause_circle : Icons.play_circle),
          ),
          Expanded(
            child: Slider(
              value: valorMs,
              max: maxMs,
              onChanged: _listo ? _buscar : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              _tiempoTexto(_duracion == Duration.zero ? _posicion : _duracion),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

String _tiempoTexto(Duration d) {
  final minutos = d.inMinutes;
  final segundos = d.inSeconds.remainder(60);
  return '$minutos:${segundos.toString().padLeft(2, '0')}';
}
