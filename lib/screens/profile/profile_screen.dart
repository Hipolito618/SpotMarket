import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/user_service.dart';
import '../auth/login_screen.dart';
import '../home/map_home_screen.dart';
import '../spots/add_spot_screen.dart';

/// Pantalla de perfil de usuario ('ProfileScreen') para spotMarket conectada a Supabase
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Índice del elemento activo en la barra inferior (Perfil = 4)
  int _currentNavIndex = 4;

  // Estados de carga y error para la consulta de Supabase
  bool _isLoading = true;
  String? _errorMessage;

  // Datos dinámicos del perfil y publicaciones del usuario
  UserProfileData? _profile;
  List<Map<String, dynamic>> _userSpots = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  /// Consulta en paralelo el perfil de usuario y sus spots en Supabase
  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fullData = await UserService.obtenerDatosCompletos();
      if (!mounted) return;

      setState(() {
        _profile = fullData.perfil;
        _userSpots = fullData.spots;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar datos del perfil desde Supabase: $e');
      if (!mounted) return;

      setState(() {
        _errorMessage = 'No se pudo cargar la información del perfil.';
        _isLoading = false;
      });
    }
  }

  /// Cierra la sesión activa en Supabase Auth y redirige a LoginScreen
  Future<void> _handleSignOut({bool showConfirmation = true}) async {
    if (showConfirmation) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            '¿Cerrar sesión?',
            style: GoogleFonts.rubik(fontWeight: FontWeight.bold),
          ),
          content: Text(
            '¿Estás seguro de que deseas salir de tu cuenta de spotMarket?',
            style: GoogleFonts.plusJakartaSans(),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    try {
      await UserService.cerrarSesion();
    } catch (e) {
      debugPrint('Nota al cerrar sesión: $e');
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// Obtiene las iniciales del nombre para el avatar de respaldo
  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  /// Extrae la URL de foto de portada desde la lista de fotos del spot
  String? _getSpotCoverPhoto(dynamic fotosRaw) {
    if (fotosRaw == null || fotosRaw is! List || fotosRaw.isEmpty) return null;

    // 1. Buscar aquella con es_portada == true
    for (final f in fotosRaw) {
      if (f is Map && (f['es_portada'] == true || f['Es_portada'] == true)) {
        final url = (f['url_foto'] ?? f['Url_foto'])?.toString();
        if (url != null && url.isNotEmpty) return url;
      }
    }

    // 2. Fallback a la primera URL disponible
    final first = fotosRaw.first;
    if (first is Map) {
      final url = (first['url_foto'] ?? first['Url_foto'])?.toString();
      if (url != null && url.isNotEmpty) return url;
    }

    return null;
  }

  /// Formatea el precio del spot amigablemente
  String _formatPrice(dynamic rawPrice) {
    if (rawPrice == null) return '\$0';
    if (rawPrice is num) {
      return rawPrice % 1 == 0 ? '\$${rawPrice.toInt()}' : '\$${rawPrice.toStringAsFixed(2)}';
    }
    final str = rawPrice.toString().trim();
    if (str.startsWith('\$')) return str;
    return '\$$str';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Paleta de colores cálida y adaptativa
    final scaffoldBg = isDark ? AppColors.darkScaffold : const Color(0xFFF8F6F2);
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? AppColors.darkTextSecondary : const Color(0xFF757575);
    final borderColor = isDark ? const Color(0xFF33302B) : const Color(0xFFEBE6DC);
    const primaryColor = Color(0xFFF05A24);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      strokeWidth: 2.8,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Cargando perfil...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Colors.redAccent.withAlpha(200),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _cargarDatos,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Reintentar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargarDatos,
                    color: primaryColor,
                    backgroundColor: cardBg,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      child: Column(
                        children: [
                          // 1. CABECERA SUPERIOR
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'spotMarket',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF9E9E9E),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                Text(
                                  'My Profile',
                                  style: GoogleFonts.rubik(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.logout_rounded,
                                        color: textSecondary,
                                        size: 22,
                                      ),
                                      tooltip: 'Cerrar sesión',
                                      onPressed: () => _handleSignOut(showConfirmation: true),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: Icon(
                                        Icons.settings_outlined,
                                        color: textPrimary,
                                        size: 24,
                                      ),
                                      tooltip: 'Configuración',
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Ajustes de cuenta spotMarket.'),
                                            backgroundColor: primaryColor,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // 2. TARJETA DE IDENTIDAD DEL USUARIO (AVATAR, NOMBRE, CORREO, ROL)
                          _buildUserIdentitySection(
                            isDark: isDark,
                            primaryColor: primaryColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),

                          const SizedBox(height: 22),

                          // 3. TARJETA DE ESTADÍSTICAS (RATING, ACTIVE SPOTS, MEMBER SINCE)
                          _buildStatsCard(
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                          ),

                          const SizedBox(height: 26),

                          // 4. SECCIÓN "MY LISTINGS" (SPOTS DEL USUARIO)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'My Listings',
                                  style: GoogleFonts.rubik(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Total de publicaciones: ${_userSpots.length}'),
                                        backgroundColor: primaryColor,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Text(
                                      'See All',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Carrusel horizontal o Empty State
                          _buildListingsSection(
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),

                          const SizedBox(height: 26),

                          // 5. MENÚ DE CONFIGURACIÓN Y ACCIONES DE CUENTA
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                _buildSettingsTile(
                                  icon: Icons.person_outline,
                                  title: 'Edit Profile',
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  textPrimary: textPrimary,
                                  isDark: isDark,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Editar información de perfil.'),
                                        backgroundColor: primaryColor,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                _buildSettingsTile(
                                  icon: Icons.storefront_outlined,
                                  title: 'Upgrade to Business (Local)',
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  textPrimary: textPrimary,
                                  isDark: isDark,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Solicitud para registrarse como negocio local enviada.'),
                                        backgroundColor: const Color(0xFF1B7F4B),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                _buildSettingsTile(
                                  icon: Icons.verified_user_outlined,
                                  title: 'Community Rules',
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  textPrimary: textPrimary,
                                  isDark: isDark,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Reglas de convivencia de colonia y bazar spotMarket.'),
                                        backgroundColor: primaryColor,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                _buildSettingsTile(
                                  icon: Icons.logout_rounded,
                                  title: 'Cerrar sesión',
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  textPrimary: Colors.redAccent,
                                  iconColor: Colors.redAccent,
                                  isDark: isDark,
                                  onTap: () => _handleSignOut(showConfirmation: true),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
      ),

      // 6. BARRA DE NAVEGACIÓN INFERIOR
      bottomNavigationBar: _buildBottomNavigationBar(
        cardBg: cardBg,
        borderColor: borderColor,
        textSecondary: textSecondary,
        primaryColor: primaryColor,
        isDark: isDark,
      ),
    );
  }

  /// Sección de identidad: Avatar centrado, nombre, correo y badge de rol dinámico
  Widget _buildUserIdentitySection({
    required bool isDark,
    required Color primaryColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final nombre = _profile?.nombre ?? 'Gerardo Hipólito';
    final correo = _profile?.correo ?? 'gerardo.h@spotmarket.com';
    final rolNombre = _profile?.rolNombre ?? 'Vecino';
    final fotoUrl = _profile?.fotoPerfil;
    final initials = _getInitials(nombre);

    return Center(
      child: Column(
        children: [
          // Avatar con NetworkImage o Iniciales y badge de cámara
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF3A3631) : Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 40 : 15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: (fotoUrl != null && fotoUrl.isNotEmpty)
                      ? Image.network(
                          fotoUrl,
                          fit: BoxFit.cover,
                          width: 90,
                          height: 90,
                          errorBuilder: (context, error, stackTrace) => _buildInitialsContainer(initials, primaryColor, isDark),
                        )
                      : _buildInitialsContainer(initials, primaryColor, isDark),
                ),
              ),
              // Badge circular naranja de cámara
              Positioned(
                right: -2,
                bottom: -2,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Actualizar foto de perfil.'),
                        backgroundColor: primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.darkScaffold : Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Nombre de usuario
          Text(
            nombre,
            style: GoogleFonts.rubik(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),

          const SizedBox(height: 4),

          // Correo electrónico
          Text(
            correo,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: textSecondary,
            ),
          ),

          const SizedBox(height: 12),

          // Badge de rol dinámico
          _buildRoleBadge(rolNombre, isDark),
        ],
      ),
    );
  }

  /// Contenedor de iniciales para el avatar
  Widget _buildInitialsContainer(String initials, Color primaryColor, bool isDark) {
    return Container(
      width: 90,
      height: 90,
      color: isDark ? const Color(0xFF2D2A26) : const Color(0xFFEDE9E3),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.rubik(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ),
    );
  }

  /// Badge dinámico según el Rol ("Vecino", "Local" o "Administrador")
  Widget _buildRoleBadge(String roleName, bool isDark) {
    final roleLower = roleName.toLowerCase();

    Color bgColor;
    Color borderColor;
    Color textColor;

    if (roleLower.contains('admin')) {
      bgColor = isDark ? const Color(0xFF331626) : const Color(0xFFFCE4EC);
      borderColor = isDark ? const Color(0xFF6B1D48) : const Color(0xFFF8BBD0);
      textColor = isDark ? const Color(0xFFF48FB1) : const Color(0xFFD81B60);
    } else if (roleLower.contains('local') || roleLower.contains('comercio') || roleLower.contains('negocio')) {
      bgColor = isDark ? const Color(0xFF143021) : const Color(0xFFE8F5E9);
      borderColor = isDark ? const Color(0xFF1B5E20) : const Color(0xFFC8E6C9);
      textColor = isDark ? const Color(0xFF81C784) : const Color(0xFF1B7F4B);
    } else {
      // Por defecto: Vecino
      bgColor = isDark ? const Color(0xFF382512) : const Color(0xFFFDEBD0);
      borderColor = isDark ? const Color(0xFF5E3A1A) : const Color(0xFFF8D7B0);
      textColor = isDark ? const Color(0xFFFF9E43) : const Color(0xFFD35400);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        roleName,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  /// Tarjeta con las 3 métricas principales: Rating, Active Spots y Member Since
  Widget _buildStatsCard({
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    final ratingValue = _profile?.reputacion ?? 5.0;
    final ratingText = ratingValue.toStringAsFixed(1);
    final activeCount = _userSpots.where((s) => (s['activo'] ?? s['Activo']) == true).length;
    final memberYear = _profile != null ? _profile!.fechaRegistro.year.toString() : '2026';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Columna a: Calificación con RatingBarIndicator
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ratingText,
                      style: GoogleFonts.rubik(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    RatingBarIndicator(
                      rating: ratingValue,
                      itemCount: 1,
                      itemSize: 16,
                      itemBuilder: (context, _) => Icon(
                        Icons.star,
                        color: isDark ? const Color(0xFFFFC107) : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Rating',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Divisor vertical 1
          Container(
            height: 36,
            width: 1,
            color: isDark ? const Color(0xFF3A3631) : const Color(0xFFEEEEEE),
          ),

          // Columna b: Spots activos dinámicos
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activeCount.toString(),
                  style: GoogleFonts.rubik(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Active Spots',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Divisor vertical 2
          Container(
            height: 36,
            width: 1,
            color: isDark ? const Color(0xFF3A3631) : const Color(0xFFEEEEEE),
          ),

          // Columna c: Año de registro (Member since)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  memberYear,
                  style: GoogleFonts.rubik(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Member since',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sección de listings: Carrusel horizontal de spots o estado vacío (Empty State)
  Widget _buildListingsSection({
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
    required Color primaryColor,
  }) {
    if (_userSpots.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 25 : 8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 40,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFFBDBDBD),
            ),
            const SizedBox(height: 10),
            Text(
              'Aún no tienes publicaciones en el mapa',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Publica tus productos, ropa de bazar o antojitos en tu colonia',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () async {
                final nuevoSpot = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddSpotScreen()),
                );
                if (nuevoSpot != null) {
                  _cargarDatos();
                }
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Crear publicación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 172,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _userSpots.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final spot = _userSpots[index];
          final coverPhoto = _getSpotCoverPhoto(spot['foto_spot'] ?? spot['Foto_spot']);
          final priceFormatted = _formatPrice(spot['Precio'] ?? spot['precio']);
          final title = (spot['Titulo'] ?? spot['titulo'] ?? 'Publicación').toString();

          return _buildListingCard(
            title: title,
            price: priceFormatted,
            imageUrl: coverPhoto,
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            isDark: isDark,
            primaryColor: primaryColor,
          );
        },
      ),
    );
  }

  /// Tarjeta individual del carrusel de listings
  Widget _buildListingCard({
    required String title,
    required String price,
    required String? imageUrl,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Container(
      width: 148,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen con etiqueta de precio superpuesta
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 108,
                  width: double.infinity,
                  child: (imageUrl != null && imageUrl.isNotEmpty)
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: isDark ? const Color(0xFF2D2A26) : const Color(0xFFEDE9E3),
                            child: Icon(Icons.image_outlined, color: textPrimary.withAlpha(120)),
                          ),
                        )
                      : Container(
                          color: isDark ? const Color(0xFF2D2A26) : const Color(0xFFEDE9E3),
                          child: Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 32,
                              color: textPrimary.withAlpha(120),
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    price,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Nombre del producto o puesto
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.rubik(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta individual del menú de configuración
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required bool isDark,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 25 : 8),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor ?? textPrimary,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.rubik(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF9E9E9E),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Barra de navegación inferior con 5 accesos directos
  Widget _buildBottomNavigationBar({
    required Color cardBg,
    required Color borderColor,
    required Color textSecondary,
    required Color primaryColor,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 15),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Mapa
              _buildNavItem(
                index: 0,
                icon: Icons.map_outlined,
                activeIcon: Icons.map_rounded,
                primaryColor: primaryColor,
                textSecondary: textSecondary,
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MapHomeScreen()),
                    );
                  }
                },
              ),

              // 2. Búsqueda
              _buildNavItem(
                index: 1,
                icon: Icons.search_rounded,
                activeIcon: Icons.search_rounded,
                primaryColor: primaryColor,
                textSecondary: textSecondary,
                onTap: () {
                  setState(() => _currentNavIndex = 1);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Búsqueda de productos y puestos en colonia.'),
                      backgroundColor: primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),

              // 3. Botón central flotante "+" (Agregar publicación)
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddSpotScreen()),
                  );
                  if (result != null) {
                    _cargarDatos();
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withAlpha(120),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),

              // 4. Notificaciones
              _buildNavItem(
                index: 3,
                icon: Icons.notifications_none_rounded,
                activeIcon: Icons.notifications_rounded,
                primaryColor: primaryColor,
                textSecondary: textSecondary,
                onTap: () {
                  setState(() => _currentNavIndex = 3);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('No tienes notificaciones pendientes.'),
                      backgroundColor: primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),

              // 5. Perfil activo (destacado en mandarina #F05A24)
              _buildNavItem(
                index: 4,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                primaryColor: primaryColor,
                textSecondary: textSecondary,
                onTap: () {
                  setState(() => _currentNavIndex = 4);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Elemento individual de navegación
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required Color primaryColor,
    required Color textSecondary,
    required VoidCallback onTap,
  }) {
    final isSelected = _currentNavIndex == index;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? primaryColor : textSecondary,
          size: 26,
        ),
      ),
    );
  }
}
