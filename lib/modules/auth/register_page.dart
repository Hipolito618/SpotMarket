import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/services/auth_service.dart';
import '../../shared/utils/validadores.dart';
import '../../shared/widgets/campo_texto.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final _confirmacion = TextEditingController();
  bool _cargando = false;
  bool _ocultarClave = true;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _clave.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      final sesionIniciada = await AuthService.instancia.registrar(
        nombre: _nombre.text.trim(),
        correo: _correo.text.trim(),
        clave: _clave.text,
      );
      if (!sesionIniciada && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta creada. Revisa tu correo para confirmarla.'),
          ),
        );
        context.go('/login');
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        leading: BackButton(onPressed: () => context.go('/login')),
      ),
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
                    CampoTexto(
                      controlador: _nombre,
                      etiqueta: 'Nombre completo',
                      icono: Icons.person_outline,
                      validador: (v) =>
                          Validadores.requerido(v, campo: 'El nombre'),
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    CampoTexto(
                      controlador: _confirmacion,
                      etiqueta: 'Confirmar contraseña',
                      icono: Icons.lock_reset,
                      ocultarTexto: _ocultarClave,
                      validador: (v) =>
                      v != _clave.text ? 'Las contraseñas no coinciden' : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _cargando ? null : _registrar,
                      child: _cargando
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text('Registrarme'),
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