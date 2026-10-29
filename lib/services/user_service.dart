import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'spot_service.dart';

/// Modelo con los datos del perfil de usuario en spotMarket
class UserProfileData {
  final String id;
  final String nombre;
  final String correo;
  final String? fotoPerfil;
  final String rolNombre;
  final double reputacion;
  final DateTime fechaRegistro;

  const UserProfileData({
    required this.id,
    required this.nombre,
    required this.correo,
    this.fotoPerfil,
    required this.rolNombre,
    required this.reputacion,
    required this.fechaRegistro,
  });

  factory UserProfileData.fromMap(Map<String, dynamic> map, {String? defaultEmail}) {
    // 1. Extraer nombre de rol desde la relación 'rol(*)' o 'Rol(*)'
    String rol = 'Vecino';
    final rolData = map['rol'] ?? map['Rol'];
    if (rolData is Map) {
      final nombreRol = rolData['nombre_rol'] ?? rolData['Nombre_rol'] ?? rolData['nombre'];
      if (nombreRol != null) rol = nombreRol.toString();
    } else if (map['nombre_rol'] != null || map['Nombre_rol'] != null) {
      rol = (map['nombre_rol'] ?? map['Nombre_rol']).toString();
    }

    // 2. Extraer reputación numérica
    double rep = 5.0;
    final repVal = map['reputacion'] ?? map['Reputacion'];
    if (repVal != null) {
      rep = double.tryParse(repVal.toString()) ?? 5.0;
    }

    // 3. Extraer fecha de registro
    DateTime fecha = DateTime.now();
    final fechaVal = map['fecha_registro'] ?? map['Fecha_registro'];
    if (fechaVal != null) {
      fecha = DateTime.tryParse(fechaVal.toString()) ?? DateTime.now();
    }

    return UserProfileData(
      id: (map['clave_usuario'] ?? map['Clave_usuario'] ?? map['id'] ?? '').toString(),
      nombre: (map['nombre_usuario'] ?? map['Nombre_usuario'] ?? map['nombre'] ?? 'Usuario').toString(),
      correo: (map['correo_electronico'] ?? map['Correo_electronico'] ?? defaultEmail ?? 'usuario@spotmarket.com').toString(),
      fotoPerfil: (map['foto_perfil'] ?? map['Foto_perfil'])?.toString(),
      rolNombre: rol,
      reputacion: rep,
      fechaRegistro: fecha,
    );
  }
}

/// Contenedor completo con el perfil de usuario y sus spots propios
class UserFullProfile {
  final UserProfileData perfil;
  final List<Map<String, dynamic>> spots;

  const UserFullProfile({
    required this.perfil,
    required this.spots,
  });
}

/// Servicio encargado de la consulta y sincronización de datos de perfil y publicaciones en Supabase
class UserService {
  /// Acceso al cliente global de Supabase
  static SupabaseClient get client => Supabase.instance.client;

  /// Hook para pruebas unitarias de perfil
  @visibleForTesting
  static Future<UserProfileData> Function()? mockObtenerPerfil;

  /// Hook para pruebas unitarias de publicaciones del usuario
  @visibleForTesting
  static Future<List<Map<String, dynamic>>> Function()? mockObtenerSpots;

  /// Hook para pruebas unitarias de cierre de sesión
  @visibleForTesting
  static Future<void> Function()? mockSignOut;

  /// Obtiene los datos del perfil del usuario autenticado actual desde la tabla 'Usuario'
  static Future<UserProfileData> obtenerPerfil() async {
    if (mockObtenerPerfil != null) {
      return await mockObtenerPerfil!();
    }

    if (!SpotService.isSupabaseInitialized) {
      debugPrint('Supabase no inicializado. Retornando perfil predeterminado.');
      return _defaultProfile;
    }

    final currentUser = client.auth.currentUser;
    if (currentUser == null) {
      debugPrint('No hay usuario autenticado en Supabase. Retornando perfil predeterminado.');
      return _defaultProfile;
    }

    try {
      final response = await client
          .from('usuario')
          .select('*, rol(*)')
          .eq('clave_usuario', currentUser.id)
          .single();

      return UserProfileData.fromMap(
        response,
        defaultEmail: currentUser.email,
      );
    } catch (e) {
      debugPrint('Nota al consultar tabla usuario en Supabase: $e');
      // Fallback a los metadatos de Supabase Auth si la fila aún no existe en la tabla usuario
      final nombre = currentUser.userMetadata?['full_name']?.toString() ??
          currentUser.email?.split('@').first ??
          'Vecino spotMarket';

      return UserProfileData(
        id: currentUser.id,
        nombre: nombre,
        correo: currentUser.email ?? 'usuario@spotmarket.com',
        fotoPerfil: currentUser.userMetadata?['avatar_url']?.toString(),
        rolNombre: 'Vecino',
        reputacion: 5.0,
        fechaRegistro: DateTime.tryParse(currentUser.createdAt) ?? DateTime.now(),
      );
    }
  }

  /// Obtiene las publicaciones propias del usuario autenticado desde la tabla 'spot'
  static Future<List<Map<String, dynamic>>> obtenerSpotsPropios() async {
    if (mockObtenerSpots != null) {
      return await mockObtenerSpots!();
    }

    if (!SpotService.isSupabaseInitialized) {
      debugPrint('Supabase no inicializado. Retornando listings predeterminados.');
      return _defaultSpots;
    }

    final currentUser = client.auth.currentUser;
    if (currentUser == null) {
      return _defaultSpots;
    }

    try {
      final response = await client
          .from('spot')
          .select('*, foto_spot(*)')
          .eq('clave_usuario', currentUser.id)
          .order('fecha_publicacion', ascending: false);

      final list = response as List<dynamic>;
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (e) {
      debugPrint('Error al consultar spots del usuario en Supabase: $e');
      return [];
    }
  }

  /// Ejecuta en paralelo las consultas de perfil y spots propios
  static Future<UserFullProfile> obtenerDatosCompletos() async {
    final results = await Future.wait([
      obtenerPerfil(),
      obtenerSpotsPropios(),
    ]);

    return UserFullProfile(
      perfil: results[0] as UserProfileData,
      spots: results[1] as List<Map<String, dynamic>>,
    );
  }

  /// Cierra la sesión activa en Supabase Auth
  static Future<void> cerrarSesion() async {
    if (mockSignOut != null) {
      await mockSignOut!();
      return;
    }

    if (SpotService.isSupabaseInitialized) {
      await client.auth.signOut();
    }
  }

  /// Perfil predeterminado para pruebas o modo sin conexión
  static final UserProfileData _defaultProfile = UserProfileData(
    id: 'demo_user',
    nombre: 'Gerardo Hipólito',
    correo: 'gerardo.h@spotmarket.com',
    fotoPerfil: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&q=80',
    rolNombre: 'Vecino',
    reputacion: 5.0,
    fechaRegistro: DateTime(2026, 1, 1),
  );

  /// Spots predeterminados para pruebas o modo sin conexión
  static final List<Map<String, dynamic>> _defaultSpots = [
    {
      'Clave_spot': '1',
      'Titulo': 'Taco Food Stand',
      'Precio': 6,
      'Activo': true,
      'Fecha_publicacion': '2026-02-01T10:00:00Z',
      'foto_spot': [
        {
          'Url_foto': 'https://images.unsplash.com/photo-1551782450-a2132b4ba21d?w=300&q=80',
          'Es_portada': true,
        }
      ],
      'Foto_spot': [
        {
          'Url_foto': 'https://images.unsplash.com/photo-1551782450-a2132b4ba21d?w=300&q=80',
          'Es_portada': true,
        }
      ],
    },
    {
      'Clave_spot': '2',
      'Titulo': 'Vintage Jacket',
      'Precio': 45,
      'Activo': true,
      'Fecha_publicacion': '2026-02-02T10:00:00Z',
      'foto_spot': [
        {
          'Url_foto': 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=300&q=80',
          'Es_portada': true,
        }
      ],
      'Foto_spot': [
        {
          'Url_foto': 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=300&q=80',
          'Es_portada': true,
        }
      ],
    },
    {
      'Clave_spot': '3',
      'Titulo': 'Camera Rental',
      'Precio': '25/d',
      'Activo': true,
      'Fecha_publicacion': '2026-02-03T10:00:00Z',
      'foto_spot': [
        {
          'Url_foto': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=300&q=80',
          'Es_portada': true,
        }
      ],
      'Foto_spot': [
        {
          'Url_foto': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=300&q=80',
          'Es_portada': true,
        }
      ],
    },
    {
      'Clave_spot': '4',
      'Titulo': 'Spot 4',
      'Precio': 20,
      'Activo': true,
      'Fecha_publicacion': '2026-02-04T10:00:00Z',
      'foto_spot': [],
      'Foto_spot': [],
    },
    {
      'Clave_spot': '5',
      'Titulo': 'Spot 5',
      'Precio': 30,
      'Activo': true,
      'Fecha_publicacion': '2026-02-05T10:00:00Z',
      'foto_spot': [],
      'Foto_spot': [],
    },
    {
      'Clave_spot': '6',
      'Titulo': 'Spot 6',
      'Precio': 15,
      'Activo': true,
      'Fecha_publicacion': '2026-02-06T10:00:00Z',
      'foto_spot': [],
      'Foto_spot': [],
    },
  ];
}

