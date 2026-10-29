import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/controllers/theme_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../services/spot_service.dart';
import '../home/map_home_screen.dart';

/// Pantalla de registro para nuevos usuarios en spotMarket integrada con Supabase Auth
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  /// Hook para pruebas unitarias y de widgets
  @visibleForTesting
  static Future<AuthResponse> Function({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  })? mockSignUp;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Cerrar teclado virtual
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final nombre = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      if (RegisterScreen.mockSignUp != null) {
        await RegisterScreen.mockSignUp!(
          email: email,
          password: password,
          data: {'full_name': nombre},
        );
      } else if (SpotService.isSupabaseInitialized) {
        await supabase.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': nombre},
        );
      } else {
        // Modo sin conexión o desarrollo local
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Desplegar SnackBar verde de bienvenida
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Cuenta creada con éxito. ¡Bienvenido a spotMarket!',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF1B7F4B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      // Navegar a la pantalla principal del mapa
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MapHomeScreen()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message.isNotEmpty ? e.message : 'Error al registrar la cuenta.',
          ),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffoldBg = isDark ? AppColors.darkScaffold : const Color(0xFFF8F6F2);
    final inputBg = isDark ? AppColors.darkInputBackground : Colors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? AppColors.darkTextSecondary : const Color(0xFF5F6368);
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE5E0D8);
    const primaryColor = Color(0xFFF05A24);
    const greyIconColor = Color(0xFF757575);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Botón superior para volver atrás
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: borderColor, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(isDark ? 30 : 8),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: textPrimary,
                                size: 18,
                              ),
                            ),
                          ),
                        ),

                        // Botón flotante de alternancia de tema (Claro / Oscuro)
                        _buildThemeToggleButton(isDark),
                      ],
                    ).animate().fadeIn(duration: 300.ms),

                    const SizedBox(height: 24),

                    // Icono distintivo de spotMarket
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha(isDark ? 40 : 20),
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor.withAlpha(80), width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.storefront_rounded,
                          color: primaryColor,
                          size: 28,
                        ),
                      ),
                    ).animate().scale(delay: 100.ms, duration: 350.ms),

                    const SizedBox(height: 18),

                    // Título principal
                    Text(
                      'Crear cuenta',
                      style: GoogleFonts.rubik(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 6),

                    // Subtítulo descriptivo
                    Text(
                      'Únete a la comunidad de comercio local en tu colonia',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: textSecondary,
                        height: 1.35,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 28),

                    // 1. CAMPO: NOMBRE COMPLETO
                    _buildFieldLabel('Nombre completo', textPrimary),
                    const SizedBox(height: 8),
                    _buildInputFieldContainer(
                      inputBg: inputBg,
                      borderColor: borderColor,
                      child: TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.plusJakartaSans(color: textPrimary, fontSize: 15),
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: _buildInputDecoration(
                          hintText: 'ej. Gerardo Hipólito',
                          icon: Icons.person_outline_rounded,
                          iconColor: greyIconColor,
                          hintColor: textSecondary,
                          focusColor: primaryColor,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa tu nombre completo';
                          }
                          if (value.trim().length < 2) {
                            return 'El nombre debe tener al menos 2 caracteres';
                          }
                          return null;
                        },
                      ),
                    ).animate().fadeIn(delay: 250.ms),

                    const SizedBox(height: 18),

                    // 2. CAMPO: CORREO ELECTRÓNICO
                    _buildFieldLabel('Correo electrónico', textPrimary),
                    const SizedBox(height: 8),
                    _buildInputFieldContainer(
                      inputBg: inputBg,
                      borderColor: borderColor,
                      child: TextFormField(
                        controller: _emailController,
                        style: GoogleFonts.plusJakartaSans(color: textPrimary, fontSize: 15),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: _buildInputDecoration(
                          hintText: 'ej. vecino@spotmarket.com',
                          icon: Icons.email_outlined,
                          iconColor: greyIconColor,
                          hintColor: textSecondary,
                          focusColor: primaryColor,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa tu correo electrónico';
                          }
                          final email = value.trim();
                          final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegExp.hasMatch(email) || !email.contains('.') || !email.contains('@')) {
                            return 'Ingresa un correo electrónico válido';
                          }
                          return null;
                        },
                      ),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 18),

                    // 3. CAMPO: CONTRASEÑA
                    _buildFieldLabel('Contraseña', textPrimary),
                    const SizedBox(height: 8),
                    _buildInputFieldContainer(
                      inputBg: inputBg,
                      borderColor: borderColor,
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: GoogleFonts.plusJakartaSans(color: textPrimary, fontSize: 15),
                        textInputAction: TextInputAction.next,
                        decoration: _buildInputDecoration(
                          hintText: 'Mínimo 6 caracteres',
                          icon: Icons.lock_outline_rounded,
                          iconColor: greyIconColor,
                          hintColor: textSecondary,
                          focusColor: primaryColor,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: greyIconColor,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa una contraseña';
                          }
                          if (value.trim().length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                    ).animate().fadeIn(delay: 350.ms),

                    const SizedBox(height: 18),

                    // 4. CAMPO: CONFIRMAR CONTRASEÑA
                    _buildFieldLabel('Confirmar contraseña', textPrimary),
                    const SizedBox(height: 8),
                    _buildInputFieldContainer(
                      inputBg: inputBg,
                      borderColor: borderColor,
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        style: GoogleFonts.plusJakartaSans(color: textPrimary, fontSize: 15),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleRegister(),
                        decoration: _buildInputDecoration(
                          hintText: 'Vuelve a escribir tu contraseña',
                          icon: Icons.lock_reset_rounded,
                          iconColor: greyIconColor,
                          hintColor: textSecondary,
                          focusColor: primaryColor,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: greyIconColor,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor confirma tu contraseña';
                          }
                          if (value.trim() != _passwordController.text.trim()) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 32),

                    // BOTÓN PRINCIPAL "CREAR CUENTA"
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          disabledBackgroundColor: primaryColor.withAlpha(160),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: primaryColor.withAlpha(120),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Crear Cuenta',
                                style: GoogleFonts.rubik(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 28),

                    // 5. NAVEGACIÓN AL LOGIN
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '¿Ya tienes una cuenta? ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                color: textSecondary,
                              ),
                            ),
                            Text(
                              'Inicia sesión',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 500.ms),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Etiqueta superior para campos de formulario
  Widget _buildFieldLabel(String label, Color color) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  /// Contenedor blanco/oscuro redondeado para los inputs (BorderRadius.circular(16))
  Widget _buildInputFieldContainer({
    required Widget child,
    required Color inputBg,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Decoración limpia para campos de texto
  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
    required Color iconColor,
    required Color hintColor,
    required Color focusColor,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: hintColor.withAlpha(160),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(icon, color: iconColor, size: 20),
      suffixIcon: suffixIcon,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );
  }

  /// Botón circular flotante de tema (Luna en claro / Sol en oscuro)
  Widget _buildThemeToggleButton(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ThemeController.instance.toggleTheme(),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE5E0D8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 30 : 8),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 19,
              color: isDark ? const Color(0xFFFFB300) : const Color(0xFF1E293B),
            ),
          ),
        ),
      ),
    );
  }
}
