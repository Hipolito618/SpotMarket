import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/spot_item.dart';
import 'connectivity_service.dart';
import 'local_cache.dart';
import 'spot_service.dart';

/// Datos de una publicación, serializables para guardarse en la cola local.
class PendingSpot {
  PendingSpot({
    String? id,
    String? usuarioId,
    DateTime? creadoEn,
    this.intentos = 0,
    required this.titulo,
    required this.precio,
    required this.latitud,
    required this.longitud,
    required this.tipo,
    this.categoriaNombre,
    this.descripcion,
    this.direccionExacta,
    this.tieneEnvio,
    this.costoEnvio,
    this.horario,
    this.radioAprox,
    this.zonaReferencia,
    this.fotosPaths = const [],
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        usuarioId = usuarioId ?? LocalCache.usuarioId,
        creadoEn = creadoEn ?? DateTime.now();

  final String id;
  final String usuarioId;
  final DateTime creadoEn;
  int intentos;
  final String titulo;
  final double precio;
  final double latitud;
  final double longitud;
  final String tipo;
  final String? categoriaNombre;
  final String? descripcion;
  final String? direccionExacta;
  final bool? tieneEnvio;
  final String? costoEnvio;
  final String? horario;
  final double? radioAprox;
  final String? zonaReferencia;
  final List<String> fotosPaths;

  factory PendingSpot.fromMap(Map<String, dynamic> m) {
    return PendingSpot(
      id: m['id'] as String?,
      usuarioId: m['usuarioId'] as String?,
      creadoEn: DateTime.tryParse((m['creadoEn'] ?? '').toString()),
      intentos: (m['intentos'] as num?)?.toInt() ?? 0,
      titulo: m['titulo'] as String,
      precio: (m['precio'] as num).toDouble(),
      latitud: (m['latitud'] as num).toDouble(),
      longitud: (m['longitud'] as num).toDouble(),
      tipo: m['tipo'] as String,
      categoriaNombre: m['categoriaNombre'] as String?,
      descripcion: m['descripcion'] as String?,
      direccionExacta: m['direccionExacta'] as String?,
      tieneEnvio: m['tieneEnvio'] as bool?,
      costoEnvio: m['costoEnvio'] as String?,
      horario: m['horario'] as String?,
      radioAprox: (m['radioAprox'] as num?)?.toDouble(),
      zonaReferencia: m['zonaReferencia'] as String?,
      fotosPaths:
      (m['fotosPaths'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'usuarioId': usuarioId,
    'creadoEn': creadoEn.toIso8601String(),
    'intentos': intentos,
    'titulo': titulo,
    'precio': precio,
    'latitud': latitud,
    'longitud': longitud,
    'tipo': tipo,
    'categoriaNombre': categoriaNombre,
    'descripcion': descripcion,
    'direccionExacta': direccionExacta,
    'tieneEnvio': tieneEnvio,
    'costoEnvio': costoEnvio,
    'horario': horario,
    'radioAprox': radioAprox,
    'zonaReferencia': zonaReferencia,
    'fotosPaths': fotosPaths,
  };

  /// Representación local del spot, usada para mostrarlo en el mapa mientras está pendiente.
  SpotItem toSpotItem() {
    final tipoMinusculas = tipo.toLowerCase();
    final esReventa =
        tipoMinusculas.contains('reventa') || tipoMinusculas.contains('segunda');
    final categoria = categoriaNombre ??
        (esReventa
            ? 'Segunda mano'
            : (tipoMinusculas.contains('comida') ? 'Antojitos' : 'Bazar'));
    final zona = zonaReferencia;

    return SpotItem(
      id: 'pendiente_$id',
      title: titulo,
      price: precio,
      type: esReventa ? SpotType.reseller : SpotType.localBusiness,
      category: categoria,
      distance: 'a 50 m',
      exactAddress: esReventa ? null : direccionExacta,
      meetingPoints: (esReventa && zona != null)
          ? zona
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList()
          : null,
      position: LatLng(latitud, longitud),
      description: descripcion,
      isOpen: true,
      hasDelivery: tieneEnvio ?? false,
      deliveryCost: costoEnvio,
    );
  }
}

/// Resultado de intentar publicar un spot.
class ResultadoPublicacion {
  const ResultadoPublicacion({required this.spot, required this.pendiente});

  final SpotItem spot;

  /// `true` si la publicación quedó en la cola local por falta de conexión.
  final bool pendiente;
}

/// Cola de publicaciones creadas sin conexión.
///
/// Las publicaciones se guardan en el dispositivo y se envían en orden cuando
/// vuelve la red. Cada elemento solo se envía con la sesión del usuario que lo creó.
class PendingQueue extends ChangeNotifier {
  PendingQueue._();

  static final PendingQueue instance = PendingQueue._();

  /// Intentos máximos ante rechazos del servidor antes de descartar un elemento.
  static const int _maxIntentos = 3;

  List<PendingSpot> _items = [];
  Future<void>? _carga;
  Future<void>? _sincronizacion;
  bool _sincronizando = false;

  List<PendingSpot> get _delUsuario =>
      _items.where((p) => p.usuarioId == LocalCache.usuarioId).toList();

  /// Publicaciones pendientes del usuario en sesión.
  int get cantidad => _delUsuario.length;

  bool get sincronizando => _sincronizando;

  /// Spots pendientes, para mostrarlos en el mapa antes de sincronizarse.
  List<SpotItem> get spotsPendientes =>
      _delUsuario.map((p) => p.toSpotItem()).toList();

  /// Carga la cola guardada y sincroniza cada vez que vuelve la conexión.
  Future<void> iniciar() async {
    await _cargar();
    ConnectivityService.instance.isOnline.addListener(() {
      if (ConnectivityService.instance.isOnline.value) {
        unawaited(sincronizar());
      }
    });
    unawaited(sincronizar());
  }

  Future<void> _cargar() => _carga ??= _leerCola();

  Future<void> _leerCola() async {
    final guardados = await LocalCache.leerPendientes();
    final items = <PendingSpot>[];
    for (final mapa in guardados) {
      try {
        items.add(PendingSpot.fromMap(mapa));
      } catch (e) {
        debugPrint('Elemento de la cola con formato inválido: $e');
      }
    }
    _items = items;
    notifyListeners();
  }

  Future<void> _guardarCola() =>
      LocalCache.guardarPendientes(_items.map((p) => p.toMap()).toList());

  /// Publica en línea; sin conexión (o ante un fallo de red) guarda la publicación en la cola.
  /// Los rechazos del servidor se propagan como [PostgrestException].
  Future<ResultadoPublicacion> publicar(
      PendingSpot datos,
      List<XFile> archivos,
      ) async {
    await _cargar();

    if (ConnectivityService.instance.isOnline.value &&
        SpotService.isSupabaseInitialized) {
      try {
        final spot = await _publicarEnServidor(datos, archivos)
            .timeout(const Duration(seconds: 30));
        return ResultadoPublicacion(spot: spot, pendiente: false);
      } on PostgrestException {
        rethrow;
      } catch (e) {
        if (!_esErrorDeRed(e)) rethrow;
        debugPrint('Sin red al publicar, se guarda en la cola: $e');
      }
    }

    _items.add(datos);
    await _guardarCola();
    notifyListeners();
    return ResultadoPublicacion(spot: datos.toSpotItem(), pendiente: true);
  }

  Future<SpotItem> _publicarEnServidor(
      PendingSpot d,
      List<XFile> archivos,
      ) async {
    final urls = await SpotService.subirImagenesStorage(archivos);
    return SpotService.publicarSpot(
      titulo: d.titulo,
      precio: d.precio,
      latitud: d.latitud,
      longitud: d.longitud,
      tipo: d.tipo,
      categoriaNombre: d.categoriaNombre,
      descripcion: d.descripcion,
      direccionExacta: d.direccionExacta,
      tieneEnvio: d.tieneEnvio,
      costoEnvio: d.costoEnvio,
      horario: d.horario,
      radioAprox: d.radioAprox,
      zonaReferencia: d.zonaReferencia,
      fotosUrls: urls,
    );
  }

  /// Envía las publicaciones pendientes. Si ya hay un envío en curso, espera a ese mismo.
  Future<void> sincronizar() =>
      _sincronizacion ??= _sincronizar().whenComplete(() => _sincronizacion = null);

  Future<void> _sincronizar() async {
    await _cargar();
    if (!SpotService.isSupabaseInitialized) return;
    if (Supabase.instance.client.auth.currentUser == null) return;
    if (!ConnectivityService.instance.isOnline.value) return;

    final pendientes = _delUsuario;
    if (pendientes.isEmpty) return;

    _sincronizando = true;
    notifyListeners();

    try {
      for (final item in pendientes) {
        if (!ConnectivityService.instance.isOnline.value) break;
        try {
          await _enviar(item);
          _items.removeWhere((p) => p.id == item.id);
        } catch (e) {
          debugPrint('No se pudo sincronizar la publicación ${item.id}: $e');
          // Un fallo de red se reintenta más tarde conservando la cola.
          if (_esErrorDeRed(e)) break;
          // Un rechazo del servidor no se reintenta indefinidamente.
          item.intentos++;
          if (item.intentos >= _maxIntentos) {
            _items.removeWhere((p) => p.id == item.id);
          }
        }
        await _guardarCola();
        notifyListeners();
      }
    } finally {
      _sincronizando = false;
      await _guardarCola();
      notifyListeners();
    }
  }

  Future<void> _enviar(PendingSpot d) async {
    final archivos = d.fotosPaths.map((ruta) => XFile(ruta)).toList();
    final urls = await _subirFotos(archivos);
    await SpotService.publicarSpot(
      titulo: d.titulo,
      precio: d.precio,
      latitud: d.latitud,
      longitud: d.longitud,
      tipo: d.tipo,
      categoriaNombre: d.categoriaNombre,
      descripcion: d.descripcion,
      direccionExacta: d.direccionExacta,
      tieneEnvio: d.tieneEnvio,
      costoEnvio: d.costoEnvio,
      horario: d.horario,
      radioAprox: d.radioAprox,
      zonaReferencia: d.zonaReferencia,
      fotosUrls: urls,
    );
  }

  /// Sube las fotos al bucket 'spots-media'. A diferencia de
  /// [SpotService.subirImagenesStorage], propaga los errores para reintentar
  /// la publicación en lugar de usar imágenes de respaldo.
  Future<List<String>> _subirFotos(List<XFile> archivos) async {
    final cliente = SpotService.client;
    final usuarioId = cliente.auth.currentUser?.id ?? LocalCache.usuarioId;
    final urls = <String>[];

    for (var i = 0; i < archivos.length; i++) {
      final archivo = archivos[i];
      final extension = archivo.name.contains('.')
          ? archivo.name.split('.').last.toLowerCase()
          : 'jpg';
      final ruta =
          '$usuarioId/${DateTime.now().millisecondsSinceEpoch}_$i.$extension';

      final bytes = await archivo.readAsBytes();
      await cliente.storage.from('spots-media').uploadBinary(
        ruta,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$extension',
          upsert: true,
        ),
      );
      urls.add(cliente.storage.from('spots-media').getPublicUrl(ruta));
    }
    return urls;
  }

  /// Distingue un fallo de conexión de un rechazo del servidor.
  static bool _esErrorDeRed(Object e) {
    if (e is PostgrestException) return false;
    if (e is SocketException || e is TimeoutException) return true;
    final texto = e.toString();
    return texto.contains('ClientException') ||
        texto.contains('SocketException') ||
        texto.contains('RetryableFetch') ||
        texto.contains('Failed host lookup');
  }
}