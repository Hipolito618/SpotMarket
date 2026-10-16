/// Validaciones reutilizables para formularios.
class Validadores {
  Validadores._();

  static String? requerido(String? valor, {String campo = 'Este campo'}) {
    if (valor == null || valor.trim().isEmpty) {
      return '$campo es obligatorio';
    }
    return null;
  }

  static String? correo(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'El correo es obligatorio';
    }
    final valido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(valor.trim());
    return valido ? null : 'Ingresa un correo válido';
  }

  static String? clave(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (valor.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  static String? precio(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'El precio es obligatorio';
    }
    final numero = double.tryParse(valor.trim().replaceAll(',', '.'));
    if (numero == null || numero <= 0) {
      return 'Ingresa un precio válido mayor a 0';
    }
    if (numero >= 100000000) {
      return 'El precio es demasiado alto';
    }
    return null;
  }

  static String? urlOpcional(String? valor) {
    if (valor == null || valor.trim().isEmpty) return null;
    final uri = Uri.tryParse(valor.trim());
    final valida = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return valida ? null : 'Ingresa una URL válida (http o https)';
  }
}