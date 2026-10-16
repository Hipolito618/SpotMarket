import 'package:geolocator/geolocator.dart';

enum EstadoUbicacion {
  disponible,
  servicioDesactivado,
  denegado,
  denegadoPermanente,
  error,
}

class ResultadoUbicacion {
  const ResultadoUbicacion(this.estado, {this.latitud, this.longitud});

  final EstadoUbicacion estado;
  final double? latitud;
  final double? longitud;

  bool get disponible => estado == EstadoUbicacion.disponible;
}

/// Solicita permisos y obtiene la ubicación actual del dispositivo.
class UbicacionService {
  UbicacionService._();

  /// Centro por defecto del mapa cuando no hay ubicación disponible.
  static const double latitudPredeterminada = 22.1565;
  static const double longitudPredeterminada = -100.9855;

  static Future<ResultadoUbicacion> obtener() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const ResultadoUbicacion(EstadoUbicacion.servicioDesactivado);
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied) {
        return const ResultadoUbicacion(EstadoUbicacion.denegado);
      }
      if (permiso == LocationPermission.deniedForever) {
        return const ResultadoUbicacion(EstadoUbicacion.denegadoPermanente);
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return ResultadoUbicacion(
        EstadoUbicacion.disponible,
        latitud: posicion.latitude,
        longitud: posicion.longitude,
      );
    } catch (_) {
      return const ResultadoUbicacion(EstadoUbicacion.error);
    }
  }

  static Future<void> abrirAjustes() => Geolocator.openAppSettings();

  /// Mensaje en español para cada estado que impide obtener la ubicación.
  static String? mensaje(EstadoUbicacion? estado) {
    switch (estado) {
      case EstadoUbicacion.servicioDesactivado:
        return 'El GPS está desactivado. Actívalo para ver tu ubicación.';
      case EstadoUbicacion.denegado:
        return 'Sin el permiso de ubicación no podemos mostrar tu posición.';
      case EstadoUbicacion.denegadoPermanente:
        return 'El permiso de ubicación fue denegado. Habilítalo desde los ajustes de la aplicación.';
      case EstadoUbicacion.error:
        return 'No fue posible obtener tu ubicación. Inténtalo de nuevo.';
      case EstadoUbicacion.disponible:
      case null:
        return null;
    }
  }
}