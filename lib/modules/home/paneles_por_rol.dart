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

