import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/services/auth_service.dart';
import '../../shared/utils/validadores.dart';
import '../../shared/widgets/campo_texto.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  bool _cargando = false;
  bool _ocultarClave = true;

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await AuthService.instancia.iniciarSesion(
        correo: _correo.text.trim(),
        clave: _clave.text,
      );
      // La navegación la resuelve el router al cambiar el estado de sesión.
    } on AuthFallo catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.mensaje)));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.location_on, size: 72, color: tema.colorScheme.primary),
                    Text(
                      'SpotMarket',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 32),
                    CampoTexto(
                      controlador: _correo,
                      etiqueta: 'Correo electrónico',
                      icono: Icons.email_outlined,
                      tipoTeclado: TextInputType.emailAddress,
                      validador: Validadores.correo,
                    ),
                    const SizedBox(height: 16),
                    CampoTexto(
                      controlador: _clave,
                      etiqueta: 'Contraseña',
                      icono: Icons.lock_outline,
                      ocultarTexto: _ocultarClave,
                      validador: Validadores.clave,
                      sufijo: IconButton(
                        icon: Icon(_ocultarClave
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _ocultarClave = !_ocultarClave),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _cargando ? null : _iniciarSesion,
                      child: _cargando
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text('Iniciar sesión'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/registro'),
                      child: const Text('¿No tienes cuenta? Regístrate'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}