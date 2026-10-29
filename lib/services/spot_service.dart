import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/spot_item.dart';

/// Instancia global de SupabaseClient accesible desde los servicios
SupabaseClient get supabase => Supabase.instance.client;

/// Servicio para la gestión y persistencia de Spots, Categorías y Fotos en Supabase
class SpotService {
  /// Acceso a la instancia singleton del cliente Supabase
  static SupabaseClient get client => Supabase.instance.client;

  /// Verifica si Supabase ha sido inicializado correctamente
  static bool get isSupabaseInitialized {
    try {
      final _ = Supabase.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Hook para pruebas unitarias y de widgets
  @visibleForTesting
  static Future<List<SpotItem>> Function()? mockObtenerSpots;

  /// Hook para pruebas unitarias de publicación
  @visibleForTesting
  static Future<SpotItem> Function({
    required String titulo,
    required double precio,
    required double latitud,
    required double longitud,
    required String tipo,
    String? categoriaNombre,
    String? descripcion,
    String? direccionExacta,
    bool? tieneEnvio,
    String? costoEnvio,
    String? horario,
    double? radioAprox,
    String? zonaReferencia,
    List<String>? fotosUrls,
  })? mockPublicarSpot;

  /// Hook para pruebas unitarias de subida de imágenes a Supabase Storage
  @visibleForTesting
  static Future<List<String>> Function(List<XFile> imagenes)? mockSubirImagenes;

  /// Sube los archivos de imágenes locales al bucket 'spots-media' de Supabase Storage
  /// y retorna la lista de URLs públicas generadas.
  static Future<List<String>> subirImagenesStorage(List<XFile> imagenes) async {
    if (imagenes.isEmpty) return [];

    if (mockSubirImagenes != null) {
      return await mockSubirImagenes!(imagenes);
    }

    if (!isSupabaseInitialized) {
      debugPrint('Supabase no está inicializado (modo test o respaldo). Retornando rutas locales.');
      return imagenes.map((img) => img.path).toList();
    }

    final currentUser = client.auth.currentUser;
    final userId = currentUser?.id ?? 'usuario_${DateTime.now().millisecondsSinceEpoch}';
    final urls = <String>[];

    for (var i = 0; i < imagenes.length; i++) {
      final img = imagenes[i];
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = img.name.contains('.') ? img.name.split('.').last.toLowerCase() : 'jpg';
      final fileName = '$userId/${timestamp}_$i.$extension';

      try {
        final bytes = await img.readAsBytes();
        await client.storage.from('spots-media').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$extension',
            upsert: true,
          ),
        );
        final publicUrl = client.storage.from('spots-media').getPublicUrl(fileName);
        urls.add(publicUrl);
      } catch (e) {
        debugPrint('Nota al subir imagen a Supabase Storage: $e');
        // Si el bucket aún no existe o falla la subida en desarrollo, usa la ruta local o imagen representativa
        if (img.path.startsWith('http')) {
          urls.add(img.path);
        } else {
          urls.add('https://images.unsplash.com/photo-1551782450-a2132b4ba21d?w=400&q=80');
        }
      }
    }

    return urls;
  }

  /// Obtiene los spots activos con sus relaciones de categorías, detalles y fotos
  static Future<List<SpotItem>> obtenerSpotsActivos() async {
    if (mockObtenerSpots != null) {
      return await mockObtenerSpots!();
    }

    if (!isSupabaseInitialized) {
      debugPrint('Supabase no está inicializado (modo test o respaldo). Retornando lista vacía.');
      return [];
    }

    try {
      final response = await client
          .from('spot')
          .select('*, categoria(*), comida(*), bazar(*), reventa(*), foto_spot(*)')
          .eq('activo', true);

      final list = response as List<dynamic>;
      final spots = <SpotItem>[];

      for (final raw in list) {
        if (raw is! Map<String, dynamic>) continue;
        final row = raw;

        final spotId = (row['clave_spot'] ?? row['Clave_spot'] ?? row['id'] ?? '').toString();
        final title = (row['titulo'] ?? row['Titulo'] ?? 'Puesto en colonia').toString();
        final price = (row['precio'] ?? row['Precio'] as num?)?.toDouble() ?? 0.0;
        final lat = (row['latitud'] ?? row['Latitud'] as num?)?.toDouble() ?? 22.1565;
        final lng = (row['longitud'] ?? row['Longitud'] as num?)?.toDouble() ?? -100.9855;
        final isOpen = (row['activo'] ?? row['Activo'] ?? true) == true;

        // Extraer categoría
        final categoriaData = _extractRelation(row['categoria'] ?? row['Categoria']);
        final categoriaNombre = (categoriaData?['nombre'] ?? categoriaData?['Nombre'] ?? '').toString();

        // Extraer especializaciones según el tipo
        final comidaData = _extractRelation(row['comida'] ?? row['Comida']);
        final bazarData = _extractRelation(row['bazar'] ?? row['Bazar']);
        final reventaData = _extractRelation(row['reventa'] ?? row['Reventa']);

        SpotType spotType = SpotType.localBusiness;
        String category = categoriaNombre.isNotEmpty ? categoriaNombre : 'Comercio Local';
        String? exactAddress;
        List<String>? meetingPoints;
        bool hasDelivery = false;
        String? deliveryCost;
        String? description = (row['descripcion'] ?? row['Descripcion'])?.toString();

        if (comidaData != null) {
          spotType = SpotType.localBusiness;
          if (categoriaNombre.isEmpty) category = 'Antojitos';
          exactAddress = (comidaData['direccion_exacta'] ?? comidaData['Direccion_exacta'])?.toString();
          hasDelivery = (comidaData['tiene_envio'] ?? comidaData['Tiene_envio'] ?? false) == true;
          deliveryCost = (comidaData['costo_envio'] ?? comidaData['Costo_envio'])?.toString();
        } else if (bazarData != null) {
          spotType = SpotType.localBusiness;
          if (categoriaNombre.isEmpty) category = 'Bazar';
          exactAddress = (bazarData['direccion_exacta'] ?? bazarData['Direccion_exacta'])?.toString();
          final horario = (bazarData['horario'] ?? bazarData['Horario'])?.toString();
          if (horario != null && horario.isNotEmpty) {
            description = description != null ? '$description\nHorario: $horario' : 'Horario: $horario';
          }
        } else if (reventaData != null) {
          spotType = SpotType.reseller;
          if (categoriaNombre.isEmpty) category = 'Segunda mano';
          final zona = (reventaData['zona_referencia'] ?? reventaData['Zona_referencia'])?.toString();
          if (zona != null && zona.isNotEmpty) {
            meetingPoints = zona.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          }
        } else {
          if (category.toLowerCase().contains('reventa') || category.toLowerCase().contains('segunda')) {
            spotType = SpotType.reseller;
          }
        }

        // Extraer fotos asociadas
        String? imageUrl;
        final fotosRaw = row['foto_spot'] ?? row['Foto_spot'];
        if (fotosRaw is List && fotosRaw.isNotEmpty) {
          for (final f in fotosRaw) {
            if (f is Map) {
              final esPortada = (f['es_portada'] ?? f['Es_portada']) == true;
              if (esPortada) {
                imageUrl = (f['url_foto'] ?? f['Url_foto'])?.toString();
                break;
              }
            }
          }
          if (imageUrl == null) {
            final first = fotosRaw.first;
            if (first is Map) {
              imageUrl = (first['url_foto'] ?? first['Url_foto'])?.toString();
            }
          }
        }

        imageUrl ??= _getDefaultImageForCategory(category, spotType);

        spots.add(
          SpotItem(
            id: spotId,
            title: title,
            price: price,
            type: spotType,
            category: category,
            distance: 'a 50 m',
            exactAddress: exactAddress,
            meetingPoints: meetingPoints,
            imageUrl: imageUrl,
            position: LatLng(lat, lng),
            description: description,
            isOpen: isOpen,
            hasDelivery: hasDelivery,
            deliveryCost: deliveryCost,
          ),
        );
      }

      return spots;
    } catch (e) {
      debugPrint('Error en SpotService.obtenerSpotsActivos: $e');
      rethrow;
    }
  }

  /// Publica un spot en Supabase ejecutando inserciones en cascada (Spot, Detalle y Foto_spot)
  static Future<SpotItem> publicarSpot({
    required String titulo,
    required double precio,
    required double latitud,
    required double longitud,
    required String tipo, // 'comida', 'bazar', 'reventa'
    String? categoriaNombre,
    String? descripcion,
    String? direccionExacta,
    bool? tieneEnvio,
    String? costoEnvio,
    String? horario,
    double? radioAprox,
    String? zonaReferencia,
    List<String>? fotosUrls,
  }) async {
    if (mockPublicarSpot != null) {
      return await mockPublicarSpot!(
        titulo: titulo,
        precio: precio,
        latitud: latitud,
        longitud: longitud,
        tipo: tipo,
        categoriaNombre: categoriaNombre,
        descripcion: descripcion,
        direccionExacta: direccionExacta,
        tieneEnvio: tieneEnvio,
        costoEnvio: costoEnvio,
        horario: horario,
        radioAprox: radioAprox,
        zonaReferencia: zonaReferencia,
        fotosUrls: fotosUrls,
      );
    }

    if (!isSupabaseInitialized) {
      debugPrint('Supabase no está inicializado (modo test o respaldo). Creando Spot local.');
      final isReseller = tipo.toLowerCase().contains('reventa') || tipo.toLowerCase().contains('segunda');
      final resolvedCategory = categoriaNombre ??
          (isReseller
              ? 'Segunda mano'
              : (tipo.toLowerCase().contains('comida') ? 'Antojitos' : 'Bazar'));

      return SpotItem(
        id: 'spot_local_${DateTime.now().millisecondsSinceEpoch}',
        title: titulo,
        price: precio,
        type: isReseller ? SpotType.reseller : SpotType.localBusiness,
        category: resolvedCategory,
        distance: 'a 50 m',
        exactAddress: !isReseller ? direccionExacta : null,
        meetingPoints: isReseller && zonaReferencia != null ? [zonaReferencia] : null,
        imageUrl: (fotosUrls != null && fotosUrls.isNotEmpty)
            ? fotosUrls.first
            : _getDefaultImageForCategory(resolvedCategory, isReseller ? SpotType.reseller : SpotType.localBusiness),
        position: LatLng(latitud, longitud),
        description: descripcion,
        isOpen: true,
        hasDelivery: tieneEnvio ?? false,
        deliveryCost: costoEnvio,
      );
    }

    // 1. Obtener ID del usuario autenticado actual (o ID temporal de prueba)
    final currentUser = client.auth.currentUser;
    final userId = currentUser?.id ?? '00000000-0000-0000-0000-000000000000';

    // Resolver Clave_categoria
    final claveCategoria = await _obtenerClaveCategoria(categoriaNombre ?? tipo);

    // Paso 1: Insertar en la tabla base 'spot' (excluye 'descripcion' que no existe en el schema de Supabase)
    final spotInsertData = {
      'clave_categoria': claveCategoria,
      'clave_usuario': userId,
      'titulo': titulo,
      'precio': precio,
      'latitud': latitud,
      'longitud': longitud,
      'activo': true,
    };

    final spotResponse = await client
        .from('spot')
        .insert(spotInsertData)
        .select('clave_spot')
        .single();

    final claveSpot = spotResponse['clave_spot'] ?? spotResponse['Clave_spot'] ?? spotResponse['id'];

    // Paso 2: Especialización según el tipo
    final tipoNormalizado = tipo.toLowerCase();
    if (tipoNormalizado.contains('comida') || tipoNormalizado.contains('antojito')) {
      await client.from('comida').insert({
        'clave_spot': claveSpot,
        'direccion_exacta': direccionExacta ?? '',
        'tiene_envio': tieneEnvio ?? false,
        if (costoEnvio != null && costoEnvio.isNotEmpty) 'costo_envio': costoEnvio,
      });
    } else if (tipoNormalizado.contains('bazar')) {
      await client.from('bazar').insert({
        'clave_spot': claveSpot,
        'direccion_exacta': direccionExacta ?? '',
        'horario': horario ?? '10:00 - 18:00',
      });
    } else if (tipoNormalizado.contains('reventa') || tipoNormalizado.contains('segunda')) {
      await client.from('reventa').insert({
        'clave_spot': claveSpot,
        'radio_aprox': radioAprox ?? 300.0,
        'zona_referencia': zonaReferencia ?? 'Puntos medios acordados',
      });
    }

    // Paso 3: Inserción de fotos en foto_spot (la primera marcada con es_portada = true)
    if (fotosUrls != null && fotosUrls.isNotEmpty) {
      final fotosBatch = <Map<String, dynamic>>[];
      for (var i = 0; i < fotosUrls.length; i++) {
        fotosBatch.add({
          'clave_spot': claveSpot,
          'url_foto': fotosUrls[i],
          'es_portada': i == 0,
          'orden': i + 1,
        });
      }
      await client.from('foto_spot').insert(fotosBatch);
    }

    // Instanciar y retornar el SpotItem publicado
    final isReseller = tipoNormalizado.contains('reventa') || tipoNormalizado.contains('segunda');
    final resolvedCategory = categoriaNombre ??
        (isReseller
            ? 'Segunda mano'
            : (tipoNormalizado.contains('comida') ? 'Antojitos' : 'Bazar'));

    return SpotItem(
      id: claveSpot.toString(),
      title: titulo,
      price: precio,
      type: isReseller ? SpotType.reseller : SpotType.localBusiness,
      category: resolvedCategory,
      distance: 'a 50 m',
      exactAddress: !isReseller ? direccionExacta : null,
      meetingPoints: isReseller && zonaReferencia != null ? [zonaReferencia] : null,
      imageUrl: (fotosUrls != null && fotosUrls.isNotEmpty)
          ? fotosUrls.first
          : _getDefaultImageForCategory(resolvedCategory, isReseller ? SpotType.reseller : SpotType.localBusiness),
      position: LatLng(latitud, longitud),
      description: descripcion,
      isOpen: true,
      hasDelivery: tieneEnvio ?? false,
      deliveryCost: costoEnvio,
    );
  }

  /// Consulta la tabla 'categoria' para encontrar la clave adecuada
  static Future<dynamic> _obtenerClaveCategoria(String tipoOcategoria) async {
    try {
      final response = await client.from('categoria').select('*');
      final list = response as List<dynamic>;
      for (final item in list) {
        if (item is Map) {
          final nombre = (item['nombre'] ?? item['Nombre'] ?? '').toString().toLowerCase();
          final target = tipoOcategoria.toLowerCase();
          if (nombre.contains(target) || target.contains(nombre)) {
            return item['clave_categoria'] ?? item['Clave_categoria'] ?? item['id'];
          }
        }
      }
      if (list.isNotEmpty && list.first is Map) {
        final first = list.first as Map;
        return first['clave_categoria'] ?? first['Clave_categoria'] ?? first['id'];
      }
    } catch (e) {
      debugPrint('Nota al consultar categoria en Supabase: $e');
    }

    // Fallback estándar en caso de tablas en inicialización
    final t = tipoOcategoria.toLowerCase();
    if (t.contains('comida') || t.contains('antojito')) return 1;
    if (t.contains('bazar')) return 2;
    return 3;
  }

  /// Extrae un mapa tanto de respuestas 1:1 ({...}) como de listas ([{...}])
  static Map<String, dynamic>? _extractRelation(dynamic relation) {
    if (relation == null) return null;
    if (relation is Map<String, dynamic>) return relation;
    if (relation is List && relation.isNotEmpty) {
      final first = relation.first;
      if (first is Map<String, dynamic>) return first;
    }
    return null;
  }

  /// Imagen representativa de respaldo según categoría
  static String _getDefaultImageForCategory(String category, SpotType type) {
    final lower = category.toLowerCase();
    if (lower.contains('antojito') || lower.contains('comida')) {
      return 'https://images.unsplash.com/photo-1551782450-a2132b4ba21d?w=300&q=80';
    } else if (lower.contains('bazar') || lower.contains('ropa')) {
      return 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=300&q=80';
    } else {
      return 'https://images.unsplash.com/photo-1588702547923-7093a6c3ba33?w=300&q=80';
    }
  }
}
