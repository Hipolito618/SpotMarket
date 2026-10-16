import 'package:go_router/go_router.dart';

import '../modules/auth/login_page.dart';
import '../modules/auth/register_page.dart';
import '../modules/home/paneles_por_rol.dart';
import '../shared/models/perfil.dart';
import '../shared/services/auth_service.dart';
import '../shared/widgets/acceso_denegado_page.dart';

import '../modules/cliente/cliente_shell.dart';
import '../modules/vendedor/vendedor_page.dart';

/// Rutas exclusivas de cada rol.
const Map<String, RolUsuario> _rutasProtegidas = {
  '/admin': RolUsuario.administrador,
  '/vendedor': RolUsuario.vendedor,
  '/cliente': RolUsuario.cliente,
};

const Set<String> _rutasPublicas = {'/login', '/registro'};

String _inicioPorRol(RolUsuario rol) {
  switch (rol) {
    case RolUsuario.administrador:
      return '/admin';
    case RolUsuario.vendedor:
      return '/vendedor';
    case RolUsuario.cliente:
      return '/cliente';
  }
}

final AuthService _auth = AuthService.instancia;

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: _auth,
  redirect: (context, state) {
    final ruta = state.matchedLocation;

    // Sin sesión: solo se permiten las pantallas públicas.
    if (!_auth.autenticado) {
      return _rutasPublicas.contains(ruta) ? null : '/login';
    }

    // Con sesión: se redirige al inicio del rol desde login, registro o raíz.
    if (_rutasPublicas.contains(ruta) || ruta == '/') {
      return _inicioPorRol(_auth.rol);
    }

    // Rutas por rol: se bloquea el acceso si el rol no coincide.
    final rolRequerido = _rutasProtegidas[ruta];
    if (rolRequerido != null && rolRequerido != _auth.rol) {
      return '/acceso-denegado';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/registro', builder: (_, __) => const RegisterPage()),
    GoRoute(path: '/admin', builder: (_, __) => const PanelAdminPage()),
    GoRoute(path: '/vendedor', builder: (_, __) => const VendedorPage()),
    GoRoute(path: '/cliente', builder: (_, __) => const ClienteShell()),
    GoRoute(
      path: '/acceso-denegado',
      builder: (_, __) => const AccesoDenegadoPage(),
    ),
  ],
);