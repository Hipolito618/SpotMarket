/// Roles disponibles en la aplicación.
enum RolUsuario {
  administrador('Administrador'),
  vendedor('Vendedor'),
  cliente('Cliente');

  const RolUsuario(this.etiqueta);

  /// Nombre legible para mostrar en la interfaz.
  final String etiqueta;

  static RolUsuario desdeTexto(String? valor) {
    return RolUsuario.values.firstWhere(
          (rol) => rol.name == valor,
      orElse: () => RolUsuario.cliente,
    );
  }
}

/// Datos del usuario autenticado y su rol.
class Perfil {
  const Perfil({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
  });

  final String id;
  final String nombre;
  final String correo;
  final RolUsuario rol;

  factory Perfil.fromMap(Map<String, dynamic> mapa) {
    return Perfil(
      id: mapa['id'] as String,
      nombre: mapa['nombre'] as String,
      correo: mapa['correo'] as String,
      rol: RolUsuario.desdeTexto(mapa['rol'] as String?),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'correo': correo,
    'rol': rol.name,
  };
}