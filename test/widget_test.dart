import 'package:flutter_test/flutter_test.dart';
import 'package:spot_market/shared/models/perfil.dart';
import 'package:spot_market/shared/utils/validadores.dart';

void main() {
  group('Validadores', () {
    test('rechaza correos inválidos', () {
      expect(Validadores.correo('abc'), isNotNull);
      expect(Validadores.correo('a@b.com'), isNull);
    });

    test('exige mínimo 6 caracteres en la contraseña', () {
      expect(Validadores.clave('123'), isNotNull);
      expect(Validadores.clave('123456'), isNull);
    });
  });

  group('RolUsuario', () {
    test('usa cliente como rol por defecto', () {
      expect(RolUsuario.desdeTexto('desconocido'), RolUsuario.cliente);
      expect(RolUsuario.desdeTexto('vendedor'), RolUsuario.vendedor);
    });
  });
}