import 'package:flutter/material.dart';

import '../../shared/models/producto.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/productos_service.dart';
import '../../shared/services/ubicacion_service.dart';
import '../../shared/utils/validadores.dart';
import '../../shared/widgets/campo_texto.dart';

/// Formulario para crear una publicación. Funciona sin conexión:
/// si no hay red, la publicación queda en la cola de pendientes.
class FormularioProductoPage extends StatefulWidget {
  const FormularioProductoPage({super.key});

  @override
  State<FormularioProductoPage> createState() => _FormularioProductoPageState();
}

class _FormularioProductoPageState extends State<FormularioProductoPage> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descripcion = TextEditingController();
  final _precio = TextEditingController();
  final _imagen = TextEditingController();

  String _categoria = categoriasProducto.first;
  double _latitud = UbicacionService.latitudPredeterminada;
  double _longitud = UbicacionService.longitudPredeterminada;
  bool _ubicacionReal = false;
  bool _buscandoUbicacion = false;
  bool _guardando = false;

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    _precio.dispose();
    _imagen.dispose();
    super.dispose();
  }

  void _mostrar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Future<void> _usarMiUbicacion() async {
    setState(() => _buscandoUbicacion = true);
    final resultado = await UbicacionService.obtener();
    if (!mounted) return;
    setState(() {
      _buscandoUbicacion = false;
      if (resultado.disponible) {
        _latitud = resultado.latitud!;
        _longitud = resultado.longitud!;
        _ubicacionReal = true;
      }
    });
    if (!resultado.disponible) {
      _mostrar(UbicacionService.mensaje(resultado.estado) ??
          'No fue posible obtener tu ubicación.');
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final sincronizada = await ProductosService.instancia.publicar(
        vendedorNombre: AuthService.instancia.perfil?.nombre ?? 'Vendedor',
        titulo: _titulo.text.trim(),
        descripcion: _descripcion.text.trim(),
        precio: double.parse(_precio.text.trim().replaceAll(',', '.')),
        categoria: _categoria,
        imagenUrl: _imagen.text.trim().isEmpty ? null : _imagen.text.trim(),
        latitud: _latitud,
        longitud: _longitud,
      );
      if (!mounted) return;
      _mostrar(sincronizada
          ? 'Publicación creada.'
          : 'Sin conexión: la publicación se enviará al reconectar.');
      Navigator.of(context).pop(true);
    } on ServicioFallo catch (e) {
      if (mounted) _mostrar(e.mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva publicación')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CampoTexto(
                controlador: _titulo,
                etiqueta: 'Título',
                icono: Icons.title,
                validador: (v) {
                  final requerido = Validadores.requerido(v, campo: 'El título');
                  if (requerido != null) return requerido;
                  return v!.trim().length < 3
                      ? 'El título debe tener al menos 3 caracteres'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              CampoTexto(
                controlador: _descripcion,
                etiqueta: 'Descripción',
                icono: Icons.notes,
                maxLineas: 4,
              ),
              const SizedBox(height: 16),
              CampoTexto(
                controlador: _precio,
                etiqueta: 'Precio',
                icono: Icons.attach_money,
                tipoTeclado:
                const TextInputType.numberWithOptions(decimal: true),
                validador: Validadores.precio,
              ),
              const SizedBox(height: 16),
              CampoTexto(
                controlador: _imagen,
                etiqueta: 'URL de la imagen (opcional)',
                icono: Icons.image_outlined,
                tipoTeclado: TextInputType.url,
                validador: Validadores.urlOpcional,
              ),
              const SizedBox(height: 16),
              Text('Categoría', style: tema.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final categoria in categoriasProducto)
                    ChoiceChip(
                      label: Text(etiquetaCategoria(categoria)),
                      selected: _categoria == categoria,
                      onSelected: (_) => setState(() => _categoria = categoria),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Ubicación', style: tema.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                _ubicacionReal
                    ? 'Tu posición actual'
                    : 'Ubicación predeterminada (centro de la ciudad)',
              ),
              Text(
                '${_latitud.toStringAsFixed(5)}, ${_longitud.toStringAsFixed(5)}',
                style: tema.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _buscandoUbicacion ? null : _usarMiUbicacion,
                  icon: _buscandoUbicacion
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.my_location),
                  label: const Text('Usar mi ubicación'),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Publicar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}