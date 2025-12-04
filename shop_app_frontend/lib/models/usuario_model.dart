class Usuario {
  final int idUsuario;
  final String nombre;
  final String apellidoPaterno;
  final String correo;
  final String? telefono;
  final int idRol;
  final String rol;
  final String? fullUrl;

  Usuario({
    required this.idUsuario,
    required this.nombre,
    required this.apellidoPaterno,
    required this.correo,
    this.telefono,
    required this.idRol,
    required this.rol,
    this.fullUrl
  });



  // Solo primer nombre
  String get primerNombre => nombre;

  // Crear desde JSON
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['idUsuario'],
      nombre: json['nombre'],
      apellidoPaterno: json['apellidoPaterno'],
      correo: json['correo'],
      telefono: json['telefono'],
      idRol: json['idRol'],
      rol: json['rol'],
      fullUrl: json['fullUrl'],
    );
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'idUsuario': idUsuario,
      'nombre': nombre,
      'apellidoPaterno': apellidoPaterno,
      'correo': correo,
      'telefono': telefono,
      'idRol': idRol,
      'rol': rol,
      'fullUrl': fullUrl,
    };
  }
}