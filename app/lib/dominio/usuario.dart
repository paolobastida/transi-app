/// Cuenta de la persona que usa Transi.
class Usuario {
  final String id;
  final String email;

  const Usuario({required this.id, required this.email});

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as String,
        email: json['email'] as String,
      );
}
