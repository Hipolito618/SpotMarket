import 'package:flutter/material.dart';

import '../../shared/services/catalogo_controller.dart';
import '../../shared/services/conectividad_service.dart';
import '../mapa/mapa_page.dart';
import 'explorar_page.dart';
import 'favoritos_page.dart';

/// Estructura de navegación del cliente con barra inferior.
class ClienteShell extends StatefulWidget {
  const ClienteShell({super.key});

  @override
  State<ClienteShell> createState() => _ClienteShellState();
}

class _ClienteShellState extends State<ClienteShell> {
  int _indice = 0;
  // El mapa se construye al visitarlo, para pedir el permiso de ubicación solo entonces.
  final Set<int> _visitadas = {0};

  @override
  void initState() {
    super.initState();
    CatalogoController.instancia.cargar();
    ConectividadService.instancia.enLinea.addListener(_alCambiarConexion);
  }

  @override
  void dispose() {
    ConectividadService.instancia.enLinea.removeListener(_alCambiarConexion);
    super.dispose();
  }

  /// Al recuperar la conexión se actualiza el catálogo.
  void _alCambiarConexion() {
    if (ConectividadService.instancia.enLinea.value) {
      CatalogoController.instancia.cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indice,
        children: [
          const ExplorarPage(),
          _visitadas.contains(1) ? const MapaPage() : const SizedBox.shrink(),
          const FavoritosPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() {
          _indice = i;
          _visitadas.add(i);
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
        ],
      ),
    );
  }
}