/// Formatea un monto con separador de miles y dos decimales (ej. $1,200.00).
String formatearPrecio(double valor) {
  final partes = valor.toStringAsFixed(2).split('.');
  final entero = partes[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
  );
  return '\$$entero.${partes[1]}';
}

/// Formatea una fecha como dd/mm/aaaa en hora local.
String formatearFecha(DateTime fecha) {
  final local = fecha.toLocal();
  final dia = local.day.toString().padLeft(2, '0');
  final mes = local.month.toString().padLeft(2, '0');
  return '$dia/$mes/${local.year}';
}