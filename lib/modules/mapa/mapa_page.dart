import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../shared/models/producto.dart';
import '../../shared/services/catalogo_controller.dart';
import '../../shared/services/ubicacion_service.dart';
import '../../shared/utils/formato.dart';
import '../../shared/widgets/acciones_sesion.dart';
import '../../shared/widgets/tarjeta_producto.dart';
import '../cliente/detalle_producto_page.dart';

/// Mapa de OpenStreetMap con la ubicación del usuario y las publicaciones.
class MapaPage extends StatefulWidget {
  const MapaPage({super.key});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final MapController _mapa = MapController();
  final CatalogoController _catalogo = CatalogoController.instancia;

  LatLng? _miUbicacion;
  EstadoUbicacion? _estadoUbicacion;
  Producto? _seleccionado;
  bool _buscando = false;
  bool _mapaListo = false;

  @override
  void initState() {
    super.initState();
    _ubicar();
  }

  @override
  void dispose() {
    _mapa.dispose();
    super.dispose();
  }

  Future<void> _ubicar() async {
    setState(() => _buscando = true);
    final resultado = await UbicacionService.obtener();
    if (!mounted) return;
    setState(() {
      _buscando = false;
      _estadoUbicacion = resultado.estado;
      if (resultado.disponible) {
        _miUbicacion = LatLng(resultado.latitud!, resultado.longitud!);
      }
    });
    if (resultado.disponible && _mapaListo) _mapa.move(_miUbicacion!, 15);
  }

  Future<void> _accionUbicacion() async {
    if (_estadoUbicacion == EstadoUbicacion.denegadoPermanente) {
      await UbicacionService.abrirAjustes();
    } else {
      await _ubicar();
    }
  }

  Widget _avisoUbicacion(String mensaje) {
    final esquema = Theme.of(context).colorScheme;
    final abrirAjustes = _estadoUbicacion == EstadoUbicacion.denegadoPermanente;
    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Card(
        color: esquema.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mensaje, style: TextStyle(color: esquema.onErrorContainer)),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _accionUbicacion,
                  child: Text(abrirAjustes ? 'Abrir ajustes' : 'Reintentar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaSeleccionada(Producto producto) {
    return Positioned(
      left: 12,
      right: 84,
      bottom: 12,
      child: Card(
        child: ListTile(
          leading: SizedBox(
            width: 48,
            height: 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ImagenProducto(url: producto.imagenUrl),
            ),
          ),
          title: Text(producto.titulo,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(formatearPrecio(producto.precio)),
          trailing: IconButton(
            tooltip: 'Ver detalle',
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => abrirDetalleProducto(context, producto),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final mensajeUbicacion = UbicacionService.mensaje(_estadoUbicacion);
    final seleccionado = _seleccionado;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: accionesSesion(context),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Centrar en mi ubicación',
        onPressed: _buscando ? null : _ubicar,
        child: _buscando
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Icon(Icons.my_location),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapa,
            options: MapOptions(
              initialCenter: LatLng(
                UbicacionService.latitudPredeterminada,
                UbicacionService.longitudPredeterminada,
              ),
              initialZoom: 13,
              onMapReady: () {
                _mapaListo = true;
                if (_miUbicacion != null) _mapa.move(_miUbicacion!, 15);
              },
              onTap: (_, __) => setState(() => _seleccionado = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.spotmarket.spot_market',
              ),
              ListenableBuilder(
                listenable: _catalogo,
                builder: (context, _) => MarkerLayer(
                  markers: [
                    for (final producto in _catalogo.visibles)
                      Marker(
                        point: LatLng(producto.latitud, producto.longitud),
                        width: 44,
                        height: 44,
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          onTap: () => setState(() => _seleccionado = producto),
                          child: Icon(
                            Icons.location_on,
                            size: 44,
                            color: producto.id == seleccionado?.id
                                ? esquema.error
                                : esquema.primary,
                          ),
                        ),
                      ),
                    if (_miUbicacion != null)
                      Marker(
                        point: _miUbicacion!,
                        width: 24,
                        height: 24,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(blurRadius: 6, color: Colors.black38),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SimpleAttributionWidget(
                source: Text('© OpenStreetMap contributors'),
              ),
            ],
          ),
          if (mensajeUbicacion != null) _avisoUbicacion(mensajeUbicacion),
          if (seleccionado != null) _tarjetaSeleccionada(seleccionado),
        ],
      ),
    );
  }
}