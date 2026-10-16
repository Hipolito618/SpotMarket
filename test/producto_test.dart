import 'package:flutter_test/flutter_test.dart';
import 'package:spot_market/shared/models/producto.dart';
import 'package:spot_market/shared/utils/formato.dart';
import 'package:spot_market/shared/utils/validadores.dart';

void main() {
  test('formatearPrecio agrega separador de miles y decimales', () {
    expect(formatearPrecio(1200), r'$1,200.00');
    expect(formatearPrecio(900), r'$900.00');
  });

  test('Producto conserva sus datos al convertirse a mapa y regresar', () {
    final original = Producto.fromMap({
      'id': 'a1',
      'vendedor_id': 'v1',
      'vendedor_nombre': 'Ana',
      'titulo': 'Bicicleta',
      'descripcion': 'Buen estado',
      'precio': 3500,
      'categoria': 'deportes',
      'imagen_url': null,
      'latitud': 22.15,
      'longitud': -100.97,
      'estado': 'activo',
      'creado_en': '2026-10-15T12:00:00.000Z',
    });
    final copia = Producto.fromMap(original.toMap());
    expect(copia.titulo, 'Bicicleta');
    expect(copia.precio, 3500.0);
    expect(copia.imagenUrl, isNull);
  });

  test('Validadores.precio rechaza valores inválidos', () {
    expect(Validadores.precio('abc'), isNotNull);
    expect(Validadores.precio('0'), isNotNull);
    expect(Validadores.precio('1200.50'), isNull);
  });
}