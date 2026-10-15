import 'package:flutter/material.dart';

import '../../shared/widgets/panel_base.dart';

/// Pantalla de inicio del administrador.
class PanelAdminPage extends StatelessWidget {
  const PanelAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PanelBase(
      titulo: 'Panel de administración',
      descripcion: 'Aquí se moderarán publicaciones y se gestionarán usuarios.',
      icono: Icons.admin_panel_settings,
    );
  }
}

/// Pantalla de inicio del vendedor.
class PanelVendedorPage extends StatelessWidget {
  const PanelVendedorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PanelBase(
      titulo: 'Mis publicaciones',
      descripcion: 'Aquí se publicarán y administrarán los productos en venta.',
      icono: Icons.storefront,
    );
  }
}

/// Pantalla de inicio del cliente.
class PanelClientePage extends StatelessWidget {
  const PanelClientePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PanelBase(
      titulo: 'Explorar SpotMarket',
      descripcion: 'Aquí se explorarán productos, favoritos y ubicaciones cercanas.',
      icono: Icons.shopping_bag,
    );
  }
}