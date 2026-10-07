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

/// Estado vacío reutilizable: ícono suave + mensaje.
class EstadoVacio extends StatelessWidget {
  final IconData icono;
  final String mensaje;

  const EstadoVacio({super.key, required this.icono, required this.mensaje});

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
      backgroundColor: ColoresTrans.rosa.withValues(alpha: 0.35),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
