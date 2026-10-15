import 'package:flutter/material.dart';

/// Campo de formulario con el estilo común de la aplicación.
class CampoTexto extends StatelessWidget {
  const CampoTexto({
    super.key,
    required this.controlador,
    required this.etiqueta,
    required this.icono,
    this.validador,
    this.tipoTeclado,
    this.ocultarTexto = false,
    this.sufijo,
  });

  final TextEditingController controlador;
  final String etiqueta;
  final IconData icono;
  final String? Function(String?)? validador;
  final TextInputType? tipoTeclado;
  final bool ocultarTexto;
  final Widget? sufijo;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controlador,
      validator: validador,
      keyboardType: tipoTeclado,
      obscureText: ocultarTexto,
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono),
        suffixIcon: sufijo,
        border: const OutlineInputBorder(),
      ),
    );
  }
}