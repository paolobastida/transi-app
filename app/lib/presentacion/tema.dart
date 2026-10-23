import 'package:flutter/material.dart';

/// Paleta basada en la bandera transgénero:
/// celeste · rosa · blanco · rosa · celeste.
class ColoresTrans {
  static const celeste = Color(0xFF5BCEFA);
  static const rosa = Color(0xFFF5A9B8);
  static const blanco = Colors.white;

  // Variantes más saturadas, para texto y botones (mejor contraste).
  static const celesteFuerte = Color(0xFF2E9CC9);
  static const rosaFuerte = Color(0xFFE27D95);

  static const tinta = Color(0xFF26323A);
  static const fondo = Color(0xFFF6FAFC);

  // Semántica de estado: activo (verde) · finalizado (gris neutro).
  static const verdeFondo = Color(0xFFDDF3E7);
  static const verdeTinta = Color(0xFF1F6F4E);
  static const grisFondo = Color(0xFFE7ECEF);
  static const grisTinta = Color(0xFF566771);
}

/// Etiqueta de estado de un tratamiento, con color semántico.
class EtiquetaEstado extends StatelessWidget {
  final bool activo;

  const EtiquetaEstado({super.key, required this.activo});

  @override
  Widget build(BuildContext context) {
    final fondo = activo ? ColoresTrans.verdeFondo : ColoresTrans.grisFondo;
    final tinta = activo ? ColoresTrans.verdeTinta : ColoresTrans.grisTinta;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        activo ? 'Activo' : 'Finalizado',
        style: TextStyle(
          color: tinta,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Franja decorativa con las cinco franjas de la bandera.
class FranjaTrans extends StatelessWidget {
  final double alto;

  const FranjaTrans({super.key, this.alto = 6});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: alto,
      child: const Row(
        children: [
          Expanded(child: ColoredBox(color: ColoresTrans.celeste)),
          Expanded(child: ColoredBox(color: ColoresTrans.rosa)),
          Expanded(child: ColoredBox(color: ColoresTrans.blanco)),
          Expanded(child: ColoredBox(color: ColoresTrans.rosa)),
          Expanded(child: ColoredBox(color: ColoresTrans.celeste)),
        ],
      ),
    );
  }
}

/// Isotipo de Transi: círculo con las cinco franjas de la bandera
/// transgénero y el símbolo ⚧ (flechas de Marte y Mercurio + cruz de Venus).
class LogoTransi extends StatelessWidget {
  final double size;
  final Color colorSimbolo;

  const LogoTransi({
    super.key,
    this.size = 32,
    this.colorSimbolo = ColoresTrans.tinta,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _LogoTransiPainter(colorSimbolo),
    );
  }
}

class _LogoTransiPainter extends CustomPainter {
  final Color simbolo;

  _LogoTransiPainter(this.simbolo);

  Path _triangulo(
    double ax, double ay,
    double bx, double by,
    double cx, double cy,
    double e,
  ) {
    return Path()
      ..moveTo(ax * e, ay * e)
      ..lineTo(bx * e, by * e)
      ..lineTo(cx * e, cy * e)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final e = size.width / 160;

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: Offset(80 * e, 80 * e), radius: 80 * e)),
    );
    const franjas = [
      ColoresTrans.celeste,
      ColoresTrans.rosa,
      ColoresTrans.blanco,
      ColoresTrans.rosa,
      ColoresTrans.celeste,
    ];
    final pincelFranja = Paint();
    for (var i = 0; i < franjas.length; i++) {
      pincelFranja.color = franjas[i];
      canvas.drawRect(
        Rect.fromLTWH(0, i * 32 * e, 160 * e, 32 * e),
        pincelFranja,
      );
    }
    canvas.restore();

    final trazo = Paint()
      ..color = simbolo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * e
      ..strokeCap = StrokeCap.round;
    final relleno = Paint()..color = simbolo;

    // Anillo central.
    canvas.drawCircle(Offset(80 * e, 82 * e), 22 * e, trazo);

    // Flecha superior derecha (Marte).
    canvas.drawLine(Offset(96 * e, 66 * e), Offset(114 * e, 48 * e), trazo);
    canvas.drawPath(_triangulo(126, 36, 118, 52, 108, 42, e), relleno);

    // Flecha superior izquierda.
    canvas.drawLine(Offset(64 * e, 66 * e), Offset(46 * e, 48 * e), trazo);
    canvas.drawPath(_triangulo(34, 36, 42, 52, 52, 42, e), relleno);

    // Cruz inferior (Venus).
    canvas.drawLine(Offset(80 * e, 104 * e), Offset(80 * e, 132 * e), trazo);
    canvas.drawLine(Offset(66 * e, 120 * e), Offset(94 * e, 120 * e), trazo);
  }

  @override
  bool shouldRepaint(covariant _LogoTransiPainter viejo) =>
      viejo.simbolo != simbolo;
}

/// Degradé suave con los colores de la bandera, para fondos de acceso.
BoxDecoration degradadoBandera() => BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          ColoresTrans.celeste.withValues(alpha: 0.45),
          ColoresTrans.blanco,
          ColoresTrans.rosa.withValues(alpha: 0.45),
        ],
        stops: const [0, 0.5, 1],
      ),
    );

/// Encabezado con la franja de la bandera y el nombre de la app.
class EncabezadoTransi extends StatelessWidget {
  final String subtitulo;

  const EncabezadoTransi({super.key, required this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: const FranjaTrans(alto: 8),
        ),
        const SizedBox(height: 20),
        const LogoTransi(size: 72),
        const SizedBox(height: 16),
        Text(
          'Transi',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .displaySmall
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
        const SizedBox(height: 6),
        Text(
          subtitulo,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}

/// Estado vacío reutilizable: ícono suave + mensaje, con acción opcional.
class EstadoVacio extends StatelessWidget {
  final IconData icono;
  final String mensaje;
  final String? etiquetaAccion;
  final IconData? iconoAccion;
  final VoidCallback? onAccion;

  const EstadoVacio({
    super.key,
    required this.icono,
    required this.mensaje,
    this.etiquetaAccion,
    this.iconoAccion,
    this.onAccion,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ColoresTrans.celeste.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, size: 40, color: ColoresTrans.celesteFuerte),
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
            ),
            if (etiquetaAccion != null && onAccion != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: onAccion,
                icon: Icon(iconoAccion ?? Icons.add),
                label: Text(etiquetaAccion!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

ThemeData temaTransi() {
  final esquema = ColorScheme.fromSeed(
    seedColor: ColoresTrans.celesteFuerte,
    brightness: Brightness.light,
  ).copyWith(
    primary: ColoresTrans.celesteFuerte,
    onPrimary: Colors.white,
    secondary: ColoresTrans.rosaFuerte,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: ColoresTrans.tinta,
  );

  final radio = BorderRadius.circular(14);

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: ColoresTrans.fondo,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: ColoresTrans.tinta,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD7E3EA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD7E3EA)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: radio),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: radio),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: ColoresTrans.celeste.withValues(alpha: 0.35),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: ColoresTrans.celeste.withValues(alpha: 0.35),
      side: const BorderSide(color: Color(0xFFD7E3EA)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
