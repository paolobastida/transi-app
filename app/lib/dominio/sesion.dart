/// Par de tokens de una sesión: el de acceso (corto) y el de refresco (largo).
class Sesion {
  final String acceso;
  final String refresco;

  const Sesion({required this.acceso, required this.refresco});

  factory Sesion.fromJson(Map<String, dynamic> json) => Sesion(
        acceso: json['acceso'] as String,
        refresco: json['refresco'] as String,
      );

  Map<String, dynamic> toJson() => {'acceso': acceso, 'refresco': refresco};
}
