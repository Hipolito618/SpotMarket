import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/controllers/theme_controller.dart';
import '../../core/theme/app_colors.dart';
import '../home/map_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Cerrar teclado virtual
    FocusScope.of(context).unfocus();

    // Si los campos están vacíos, permitir autocompletar demo directamente
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty && password.isEmpty) {
      _emailController.text = 'demo';
      _passwordController.text = 'demo';
    }

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      // Simulación de autenticación suave
      await Future<void>.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MapHomeScreen()),
      );
    }
  }

  void _onForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Enlace para restablecer contraseña enviado a tu correo.'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onSocialLogin(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Iniciando sesión con $provider...'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onRegister() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.lightScaffold;
    final inputBg = isDark ? AppColors.darkInputBackground : const Color(0xFFFFFFFF);
    final inputBorderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final secondaryColor = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Stack(
          children: [
            // Contenido desplazable para evitar desbordamiento al abrir el teclado virtual
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),

                      // --- LOGOTIPO ANIMADO spotMarket ---
                      Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 100,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback estético si la imagen de asset tuviera algún problema
                            return Container(
                              height: 90,
                              width: 90,
                              decoration: BoxDecoration(
                                color: primaryColor.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.storefront_rounded, size: 50, color: primaryColor),
                            );
                          },
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 800.ms, curve: Curves.easeOutCubic)
                          .slideY(begin: -0.4, end: 0, duration: 800.ms, curve: Curves.easeOutBack),

                      const SizedBox(height: 14),

                      // Título estilizado: "spot" en color de texto y "Market" en naranja primario
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.rubik(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                            children: [
                              TextSpan(
                                text: 'spot',
                                style: TextStyle(color: textPrimary),
                              ),
                              TextSpan(
                                text: 'Market',
                                style: TextStyle(color: primaryColor),
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOut),

                      const SizedBox(height: 6),

                      // Subtítulo descriptivo del marketplace hiperlocal
                      Center(
                        child: Text(
                          'El tianguis y bazar de tu colonia en el mapa',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ).animate().fadeIn(delay: 300.ms, duration: 600.ms),

                      const SizedBox(height: 36),

                      // --- CAMPO: CORREO ELECTRÓNICO ---
                      _buildFieldLabel('Correo electrónico', textPrimary),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildCapsuleInputDecoration(
                          hintText: 'vecino@correo.com',
                          inputBg: inputBg,
                          borderColor: inputBorderColor,
                          hintColor: textSecondary,
                          focusColor: primaryColor,
                        ),
                        validator: (value) {
                          final val = value?.trim().toLowerCase() ?? '';
                          if (val.isEmpty) {
                            return 'Ingresa tu correo o "demo"';
                          }
                          if (val == 'demo') return null; // Acceso rápido demo
                          if (!val.contains('@') || !val.contains('.')) {
                            return 'Ingresa un correo válido (o escribe "demo")';
                          }
                          return null;
                        },
                      ).animate().fadeIn(delay: 350.ms, duration: 500.ms).slideX(begin: -0.05, end: 0),

                      const SizedBox(height: 18),

                      // --- CAMPO: CONTRASEÑA ---
                      _buildFieldLabel('Contraseña', textPrimary),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildCapsuleInputDecoration(
                          hintText: '•••••••••• (o escribe "demo")',
                          inputBg: inputBg,
                          borderColor: inputBorderColor,
                          hintColor: textSecondary,
                          focusColor: primaryColor,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: textSecondary,
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
                          final val = value?.trim().toLowerCase() ?? '';
                          if (val.isEmpty) {
                            return 'Ingresa tu contraseña o "demo"';
                          }
                          if (val == 'demo') return null; // Acceso rápido demo
                          if (val.length < 4) {
                            return 'La contraseña debe tener al menos 4 caracteres';
                          }
                          return null;
                        },
                      ).animate().fadeIn(delay: 450.ms, duration: 500.ms).slideX(begin: -0.05, end: 0),

                      const SizedBox(height: 10),

                      // Enlaces de ayuda: "Autollenar demo" y "¿Olvidaste tu contraseña?"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _emailController.text = 'demo';
                                _passwordController.text = 'demo';
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt_rounded, size: 16, color: primaryColor),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Autollenar demo',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _onForgotPassword,
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Text(
                                '¿Olvidaste tu contraseña?',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: secondaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 500.ms),

                      const SizedBox(height: 26),

                      // --- BOTÓN PRINCIPAL: INICIAR SESIÓN (CÁPSULA MANDARINA) ---
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: primaryColor.withAlpha(160),
                            elevation: isDark ? 2 : 3,
                            shadowColor: primaryColor.withAlpha(isDark ? 80 : 110),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Iniciar Sesión',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 550.ms, duration: 500.ms)
                          .scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1)),

                      const SizedBox(height: 28),

                      // --- DIVISOR SUTIL CON TEXTO ---
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isDark ? const Color(0xFF2E2B27) : const Color(0xFFE2DDD5),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              '— o inicia con —',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isDark ? const Color(0xFF2E2B27) : const Color(0xFFE2DDD5),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 600.ms),

                      const SizedBox(height: 22),

                      // --- 3 BOTONES CIRCULARES SOCIALES ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(
                            onTap: () => _onSocialLogin('Google'),
                            isDark: isDark,
                            child: const _GoogleIcon(size: 20),
                          ),
                          const SizedBox(width: 18),
                          _buildSocialButton(
                            onTap: () => _onSocialLogin('Facebook'),
                            isDark: isDark,
                            backgroundColor: const Color(0xFF1877F2),
                            child: const Text(
                              'f',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'sans-serif',
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          _buildSocialButton(
                            onTap: () => _onSocialLogin('Redes'),
                            isDark: isDark,
                            backgroundColor: isDark ? const Color(0xFF38342F) : const Color(0xFF757575),
                            child: const Icon(
                              Icons.share_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 650.ms).slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 32),

                      // --- PIE DE PÁGINA: ¿Eres nuevo aquí? Regístrate ---
                      Center(
                        child: InkWell(
                          onTap: _onRegister,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: textPrimary,
                                ),
                                children: [
                                  TextSpan(
                                    text: '¿Eres nuevo aquí? ',
                                    style: TextStyle(color: textSecondary),
                                  ),
                                  TextSpan(
                                    text: 'Regístrate',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: secondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 700.ms),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),

            // --- BOTÓN FLOTANTE CIRCULAR DE TEMA EN ESQUINA SUPERIOR DERECHA ---
            Positioned(
              top: 12,
              right: 18,
              child: _buildThemeToggleButton(isDark),
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

  /// Decoración en forma de cápsula para los campos de texto
  InputDecoration _buildCapsuleInputDecoration({
    required String hintText,
    required Color inputBg,
    required Color borderColor,
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
      filled: true,
      fillColor: inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: focusColor, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
      ),
    );
  }

  /// Botón circular flotante de tema (Luna en claro / Sol brillante en oscuro)
  Widget _buildThemeToggleButton(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ThemeController.instance.toggleTheme(),
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF22201D) : Colors.white,
            boxShadow: [
              if (isDark)
                BoxShadow(
                  color: const Color(0xFFFFB300).withAlpha(50),
                  blurRadius: 14,
                  spreadRadius: 2,
                )
              else
                BoxShadow(
                  color: Colors.black.withAlpha(18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
            ],
            border: Border.all(
              color: isDark ? const Color(0xFF38342F) : const Color(0xFFEBE6DC),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 21,
              color: isDark ? const Color(0xFFFFB300) : const Color(0xFF1E293B),
            )
                .animate(key: ValueKey<bool>(isDark))
                .scale(duration: 250.ms, curve: Curves.easeOutBack)
                .rotate(duration: 350.ms, curve: Curves.easeOut),
          ),
        ),
      ),
    );
  }

  /// Botón circular de acceso social neutro
  Widget _buildSocialButton({
    required VoidCallback onTap,
    required bool isDark,
    required Widget child,
    Color? backgroundColor,
  }) {
    final bgColor = backgroundColor ?? (isDark ? const Color(0xFF2A2723) : Colors.white);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 50 : 15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isDark ? const Color(0xFF38342F) : const Color(0xFFE8E3DA),
              width: 0.8,
            ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Renderizado nítido del logotipo oficial de 4 colores de Google (G)
class _GoogleIcon extends StatelessWidget {
  final double size;

  const _GoogleIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    final strokeWidth = size.width * 0.22;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Arcos característicos de Google 'G'
    canvas.drawArc(rect, -3.14159 * 0.72, 3.14159 * 0.47, false, redPaint);
    canvas.drawArc(rect, -3.14159 * 1.25, 3.14159 * 0.53, false, yellowPaint);
    canvas.drawArc(rect, 3.14159 * 0.28, 3.14159 * 0.48, false, greenPaint);
    canvas.drawArc(rect, -3.14159 * 0.24, 3.14159 * 0.52, false, bluePaint);

    // Barra horizontal azul en el cuadrante derecho
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final barRect = Rect.fromLTWH(
      center.dx - strokeWidth * 0.2,
      center.dy - strokeWidth / 2,
      radius + strokeWidth * 0.1,
      strokeWidth,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
