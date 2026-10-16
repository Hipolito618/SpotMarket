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
    this.maxLineas = 1,
  });

  final TextEditingController controlador;
  final String etiqueta;
  final IconData icono;
  final String? Function(String?)? validador;
  final TextInputType? tipoTeclado;
  final bool ocultarTexto;
  final Widget? sufijo;
  final int maxLineas;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controlador,
      validator: validador,
      keyboardType: maxLineas > 1 ? TextInputType.multiline : tipoTeclado,
      obscureText: ocultarTexto,
      maxLines: ocultarTexto ? 1 : maxLineas,
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono),
        suffixIcon: sufijo,
        border: const OutlineInputBorder(),
      ),
    );
  }
}