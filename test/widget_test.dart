import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:spot_market/main.dart';
import 'package:spot_market/core/controllers/theme_controller.dart';
import 'package:spot_market/models/spot_item.dart';
import 'package:spot_market/screens/auth/register_screen.dart';
import 'package:spot_market/screens/home/map_home_screen.dart';
import 'package:spot_market/screens/profile/profile_screen.dart';
import 'package:spot_market/screens/spots/add_spot_screen.dart';
import 'package:spot_market/services/spot_service.dart';
import 'package:spot_market/services/user_service.dart';
import 'package:spot_market/widgets/spot_preview_modal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  setUp(() {
    AddSpotScreen.mockInitialFiles = [XFile('test/mock_foto.jpg')];
  });

  tearDown(() {
    AddSpotScreen.mockInitialFiles = null;
    AddSpotScreen.mockPickImages = null;
    UserService.mockObtenerPerfil = null;
    UserService.mockObtenerSpots = null;
    UserService.mockSignOut = null;
  });

  testWidgets('spotMarket smoke test and theme toggle', (WidgetTester tester) async {
    await tester.pumpWidget(const SpotMarketApp());
    await tester.pumpAndSettle();

    // Verify spotMarket subtitle and buttons are present
    expect(find.text('El tianguis y bazar de tu colonia en el mapa'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);

    // Initial theme should be light (moon icon displayed in top right toggle)
    expect(ThemeController.instance.isDarkMode, isFalse);
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);

    // Tap top right theme toggle button
    await tester.tap(find.byIcon(Icons.dark_mode_rounded));
    await tester.pumpAndSettle();

    // Verify theme changed to dark (sun icon displayed)
    expect(ThemeController.instance.isDarkMode, isTrue);
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);

    // Tap again to toggle back to light mode
    await tester.tap(find.byIcon(Icons.light_mode_rounded));
    await tester.pumpAndSettle();
    expect(ThemeController.instance.isDarkMode, isFalse);
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
  });

  testWidgets('MapHomeScreen elements and category filtering', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MapHomeScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    // Verify search bar and category chips
    expect(find.text('¿Qué buscas en tu colonia?'), findsOneWidget);
    expect(find.text('🔥 Todos'), findsOneWidget);
    expect(find.text('🍧 Antojitos'), findsOneWidget);
    expect(find.text('👗 Bazar'), findsOneWidget);
    expect(find.text('🟢 Abierto ahora'), findsOneWidget);

    // Verify floating "+ Vender" button
    expect(find.text('Vender'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);

    // Verify floating GPS recenter button and tap without crash
    expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.my_location_rounded));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify DraggableScrollableSheet header
    expect(find.text('Cerca de ti'), findsOneWidget);

    // Clean up animation tickers
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('SpotPreviewModal renders correctly for localBusiness and reseller', (WidgetTester tester) async {
    const localSpot = SpotItem(
      id: 'local_1',
      title: 'Tamales Doña Lucha',
      price: 25.0,
      type: SpotType.localBusiness,
      category: 'Antojitos',
      distance: 'a 120 m',
      exactAddress: 'Calle Jalapa 124, esq. Álvaro Obregón',
    );

    const resellerSpot = SpotItem(
      id: 'reseller_1',
      title: 'Bazar Vintage 90s',
      price: 150.0,
      type: SpotType.reseller,
      category: 'Bazar',
      distance: 'a 300 m',
      meetingPoints: ['OXXO Glorieta', 'Kiosco Plaza'],
    );

    // 1. Probar puesto local / negocio fijo
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SpotPreviewModal(spot: localSpot),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Tamales Doña Lucha'), findsOneWidget);
    expect(find.text('\$25 MXN'), findsOneWidget);
    expect(find.text('Local / Puesto fijo'), findsOneWidget);
    expect(find.text('Calle Jalapa 124, esq. Álvaro Obregón'), findsOneWidget);
    expect(find.text('Cómo llegar'), findsOneWidget);

    await tester.tap(find.text('Cómo llegar'));
    await tester.pump();
    expect(find.text('Abriendo ruta hacia Calle Jalapa 124, esq. Álvaro Obregón'), findsOneWidget);

    // 2. Probar vendedor particular / segunda mano
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SpotPreviewModal(spot: resellerSpot),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Bazar Vintage 90s'), findsOneWidget);
    expect(find.text('\$150 MXN'), findsOneWidget);
    expect(find.text('Vendedor particular'), findsOneWidget);
    expect(find.text('Puntos de entrega:'), findsOneWidget);
    expect(find.text('OXXO Glorieta'), findsOneWidget);
    expect(find.text('Kiosco Plaza'), findsOneWidget);
    expect(find.text('Acordar punto de entrega'), findsOneWidget);

    await tester.tap(find.text('Acordar punto de entrega'));
    await tester.pump();
    expect(find.text('Iniciando chat para acordar entrega'), findsOneWidget);
  });

  testWidgets('AddSpotScreen renders and dynamically toggles fields based on sale type', (WidgetTester tester) async {
    SpotItem? returnedSpot;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  returnedSpot = await Navigator.push<SpotItem>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddSpotScreen(),
                    ),
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap to open AddSpotScreen
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    // Verify title and main elements
    expect(find.text('Agregar punto al mapa'), findsOneWidget);
    expect(find.text('Tipo de venta'), findsOneWidget);
    expect(find.text('Bazar'), findsOneWidget);
    expect(find.text('Puesto de\ncomida'), findsOneWidget);
    expect(find.text('Reventa'), findsOneWidget);

    // Initial selected type is Reventa: check Reventa specific fields
    expect(find.text('Puntos de entrega (puntos medios)'), findsOneWidget);
    expect(
      find.text('Por seguridad, no mostramos tu ubicación exacta, sólo una zona aproximada (300m)'),
      findsOneWidget,
    );

    // Switch to 'Puesto de comida'
    await tester.tap(find.text('Puesto de\ncomida'));
    await tester.pumpAndSettle();

    // Check Puesto de comida specific fields
    expect(find.text('Dirección exacta del local o puesto'), findsOneWidget);
    expect(find.text('Configuración especial'), findsOneWidget);
    expect(find.text('¿Tiene envíos / a domicilio?'), findsOneWidget);

    // Toggle switch for delivery
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Fill fields and submit
    await tester.ensureVisible(find.widgetWithText(TextFormField, 'ej. Calle Morelos #105, frente a la tienda'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'ej. Calle Morelos #105, frente a la tienda'),
      'Calle Hidalgo 300, Centro',
    );
    await tester.ensureVisible(find.widgetWithText(TextFormField, '¿Qué vendes o ofreces?'));
    await tester.enterText(
      find.widgetWithText(TextFormField, '¿Qué vendes o ofreces?'),
      'Gorditas de Morales con guisado casero',
    );

    // Tap "Publicar en el mapa"
    await tester.tap(find.text('Publicar en el mapa'));
    await tester.pumpAndSettle();

    // Check that spot was returned
    expect(returnedSpot, isNotNull);
    expect(returnedSpot!.title, 'Gorditas de Morales con guisado casero');
    expect(returnedSpot!.category, 'Antojitos');
    expect(returnedSpot!.exactAddress, 'Calle Hidalgo 300, Centro');
    expect(returnedSpot!.hasDelivery, isTrue);
  });

  testWidgets('MapHomeScreen "+ Vender" button opens AddSpotScreen and adds spot to map', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MapHomeScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    // Find and tap "+ Vender"
    expect(find.text('Vender'), findsOneWidget);
    await tester.tap(find.text('Vender'));
    await tester.pumpAndSettle();

    // Verify AddSpotScreen is opened
    expect(find.text('Agregar punto al mapa'), findsOneWidget);

    // Enter description and meeting points for Reventa
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ingresa puntos medios (ej. OXXO Glorieta, Kiosco)'),
      'OXXO Carranza esq. Anáhuac',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '¿Qué vendes o ofreces?'),
      'Chamarra de piel noventera',
    );

    // Publish
    await tester.tap(find.text('Publicar en el mapa'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify returning to map and new spot appears in list
    expect(find.text('Chamarra de piel noventera'), findsAtLeast(1));
    expect(find.text('¡Punto publicado exitosamente en el mapa!'), findsOneWidget);

    // Clean up animation tickers
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 200));
  });

  group('SpotService and AddSpotScreen publishing integration', () {
    tearDown(() {
      SpotService.mockObtenerSpots = null;
      SpotService.mockPublicarSpot = null;
    });

    test('obtenerSpotsActivos returns list from mock hook', () async {
      final mockData = [
        const SpotItem(
          id: 'test_1',
          title: 'Tacos Don Pancho',
          price: 50.0,
          type: SpotType.localBusiness,
          category: 'Antojitos',
          distance: 'a 30 m',
          exactAddress: 'Av. Carranza 400',
          isOpen: true,
        ),
      ];

      SpotService.mockObtenerSpots = () async => mockData;

      final result = await SpotService.obtenerSpotsActivos();
      expect(result.length, 1);
      expect(result.first.title, 'Tacos Don Pancho');
      expect(result.first.price, 50.0);
      expect(result.first.type, SpotType.localBusiness);
    });

    test('publicarSpot returns created SpotItem with mock hook', () async {
      SpotService.mockPublicarSpot = ({
        required String titulo,
        required double precio,
        required double latitud,
        required double longitud,
        required String tipo,
        String? categoriaNombre,
        String? descripcion,
        String? direccionExacta,
        bool? tieneEnvio,
        String? costoEnvio,
        String? horario,
        double? radioAprox,
        String? zonaReferencia,
        List<String>? fotosUrls,
      }) async {
        return SpotItem(
          id: 'mock_created_99',
          title: titulo,
          price: precio,
          type: tipo == 'reventa' ? SpotType.reseller : SpotType.localBusiness,
          category: categoriaNombre ?? 'Antojitos',
          distance: 'a 50 m',
          exactAddress: direccionExacta,
          hasDelivery: tieneEnvio ?? false,
          deliveryCost: costoEnvio,
          meetingPoints: zonaReferencia != null ? [zonaReferencia] : null,
          imageUrl: fotosUrls?.first,
          isOpen: true,
        );
      };

      final spot = await SpotService.publicarSpot(
        titulo: 'Elotes Los Compadres',
        precio: 35.0,
        latitud: 22.1600,
        longitud: -100.9650,
        tipo: 'comida',
        categoriaNombre: 'Antojitos',
        descripcion: 'Esquites y elotes asados',
        direccionExacta: 'Calle Juárez 210',
        tieneEnvio: true,
        costoEnvio: '\$15 en la colonia',
        fotosUrls: ['https://example.com/elote.jpg'],
      );

      expect(spot.id, 'mock_created_99');
      expect(spot.title, 'Elotes Los Compadres');
      expect(spot.price, 35.0);
      expect(spot.type, SpotType.localBusiness);
      expect(spot.hasDelivery, isTrue);
      expect(spot.deliveryCost, '\$15 en la colonia');
      expect(spot.imageUrl, 'https://example.com/elote.jpg');
    });

    testWidgets('AddSpotScreen displays error SnackBar on publication failure', (WidgetTester tester) async {
      SpotService.mockPublicarSpot = ({
        required String titulo,
        required double precio,
        required double latitud,
        required double longitud,
        required String tipo,
        String? categoriaNombre,
        String? descripcion,
        String? direccionExacta,
        bool? tieneEnvio,
        String? costoEnvio,
        String? horario,
        double? radioAprox,
        String? zonaReferencia,
        List<String>? fotosUrls,
      }) async {
        throw Exception('Fallo de conexión simulado');
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const AddSpotScreen())),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Rellenar campos válidos para reventa
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ingresa puntos medios (ej. OXXO Glorieta, Kiosco)'),
        'Kiosco de la Plaza',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '¿Qué vendes o ofreces?'),
        'Reloj retro Casio',
      );

      // Presionar publicar
      await tester.tap(find.text('Publicar en el mapa'));
      await tester.pumpAndSettle();

      // Debe mostrar el SnackBar de error
      expect(find.textContaining('Error al publicar: Exception: Fallo de conexión simulado'), findsOneWidget);
      // La pantalla no se cerró y el botón sigue disponible
      expect(find.text('Publicar en el mapa'), findsOneWidget);
    });

    testWidgets('AddSpotScreen handles PostgrestException gracefully with SnackBar', (WidgetTester tester) async {
      SpotService.mockPublicarSpot = ({
        required String titulo,
        required double precio,
        required double latitud,
        required double longitud,
        required String tipo,
        String? categoriaNombre,
        String? descripcion,
        String? direccionExacta,
        bool? tieneEnvio,
        String? costoEnvio,
        String? horario,
        double? radioAprox,
        String? zonaReferencia,
        List<String>? fotosUrls,
      }) async {
        throw const PostgrestException(message: 'duplicate key value violates unique constraint');
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const AddSpotScreen())),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ingresa puntos medios (ej. OXXO Glorieta, Kiosco)'),
        'Kiosco de la Plaza',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '¿Qué vendes o ofreces?'),
        'Reloj retro Casio',
      );

      await tester.tap(find.text('Publicar en el mapa'));
      await tester.pumpAndSettle();

      expect(find.text('Error al publicar: duplicate key value violates unique constraint'), findsOneWidget);
    });

    testWidgets('AddSpotScreen displays CircularProgressIndicator while publishing', (WidgetTester tester) async {
      final completer = Completer<SpotItem>();

      SpotService.mockPublicarSpot = ({
        required String titulo,
        required double precio,
        required double latitud,
        required double longitud,
        required String tipo,
        String? categoriaNombre,
        String? descripcion,
        String? direccionExacta,
        bool? tieneEnvio,
        String? costoEnvio,
        String? horario,
        double? radioAprox,
        String? zonaReferencia,
        List<String>? fotosUrls,
      }) {
        return completer.future;
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const AddSpotScreen())),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Rellenar campos válidos
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ingresa puntos medios (ej. OXXO Glorieta, Kiosco)'),
        'Kiosco Plaza',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '¿Qué vendes o ofreces?'),
        'Colección de tazas',
      );

      // Presionar publicar
      await tester.tap(find.text('Publicar en el mapa'));
      await tester.pump();

      // El botón ahora debe mostrar el CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Completar la publicación
      completer.complete(
        const SpotItem(
          id: 'test_done',
          title: 'Colección de tazas',
          price: 40.0,
          type: SpotType.reseller,
          category: 'Segunda mano',
          distance: 'a 50 m',
        ),
      );
      await tester.pumpAndSettle();

      // Confirma que se muestra el SnackBar de éxito
      expect(find.text('¡Punto publicado exitosamente en el mapa!'), findsOneWidget);
    });

    testWidgets('AddSpotScreen validates that at least 1 photo is required before publishing', (WidgetTester tester) async {
      // Forzar que no haya fotos seleccionadas
      AddSpotScreen.mockInitialFiles = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const AddSpotScreen())),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Rellenar campos de texto válidos
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ingresa puntos medios (ej. OXXO Glorieta, Kiosco)'),
        'Kiosco Plaza',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '¿Qué vendes o ofreces?'),
        'Lámpara de noche vintage',
      );

      // Intentar publicar sin fotos
      await tester.tap(find.text('Publicar en el mapa'));
      await tester.pumpAndSettle();

      // Debe mostrar advertencia de fotos requeridas
      expect(find.text('Por favor agrega al menos una foto de tu producto o puesto.'), findsOneWidget);
    });

    testWidgets('AddSpotScreen renders price field and sends entered price to publicarSpot', (WidgetTester tester) async {
      double? capturedPrice;
      SpotService.mockPublicarSpot = ({
        required String titulo,
        required double precio,
        required double latitud,
        required double longitud,
        required String tipo,
        String? categoriaNombre,
        String? descripcion,
        String? direccionExacta,
        bool? tieneEnvio,
        String? costoEnvio,
        String? horario,
        double? radioAprox,
        String? zonaReferencia,
        List<String>? fotosUrls,
      }) async {
        capturedPrice = precio;
        return SpotItem(
          id: 'price_test_spot',
          title: titulo,
          price: precio,
          type: SpotType.reseller,
          category: 'Segunda mano',
          distance: 'a 50 m',
          isOpen: true,
        );
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const AddSpotScreen())),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Verificar que el campo de precio está presente en la UI
      expect(find.text('Precio (MXN)'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'ej. 45 o 120'), findsOneWidget);

      // Ingresar datos
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ingresa puntos medios (ej. OXXO Glorieta, Kiosco)'),
        'Kiosco Plaza',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '¿Qué vendes o ofreces?'),
        'Bicicleta de montaña rodada 29',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ej. 45 o 120'),
        '1850',
      );

      // Publicar
      await tester.tap(find.text('Publicar en el mapa'));
      await tester.pumpAndSettle();

      expect(capturedPrice, 1850.0);
    });

    testWidgets('AddSpotScreen picks images, shows Portada badge and removes individual photos', (WidgetTester tester) async {
      AddSpotScreen.mockInitialFiles = [];
      AddSpotScreen.mockPickImages = () async => [
        XFile('test/foto_1.jpg'),
        XFile('test/foto_2.jpg'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const AddSpotScreen())),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Al inicio debe mostrar 0/5
      expect(find.text('0 / 5'), findsOneWidget);
      expect(find.text('Agregar fotos\n(máx. 5)'), findsOneWidget);

      // Tocar el botón de agregar fotos
      await tester.ensureVisible(find.text('Agregar fotos\n(máx. 5)'));
      await tester.tap(find.text('Agregar fotos\n(máx. 5)'));
      await tester.pumpAndSettle();

      // Ahora debe mostrar 2/5 y el badge "Portada" en la primera foto
      expect(find.text('2 / 5'), findsOneWidget);
      expect(find.text('Portada'), findsOneWidget);

      // Remover una foto con el botón 'x'
      final closeButtons = find.byIcon(Icons.close_rounded);
      expect(closeButtons, findsNWidgets(2));
      await tester.tap(closeButtons.first);
      await tester.pumpAndSettle();

      // Debe quedar 1 foto (1/5) y seguir mostrando Portada
      expect(find.text('1 / 5'), findsOneWidget);
      expect(find.text('Portada'), findsOneWidget);
    });

    testWidgets('AddSpotScreen interactive map updates coordinates and handles recenter', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => const AddSpotScreen(
                      initialLocation: LatLng(22.1565, -100.9855),
                    ),
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Verificar que el mapa interactivo y coordenadas iniciales se renderizan
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.textContaining('Coordenadas: Lat 22.1565, Lng -100.9855'), findsOneWidget);

      // Verificar botón de recentrar
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.my_location_rounded));
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('ProfileScreen renders identity, stats, listings, settings and nav bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Header
      expect(find.text('spotMarket'), findsOneWidget);
      expect(find.text('My Profile'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      // 2. Identity
      expect(find.text('Gerardo Hipólito'), findsOneWidget);
      expect(find.text('gerardo.h@spotmarket.com'), findsOneWidget);
      expect(find.text('Vecino'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);

      // 3. Stats card
      expect(find.text('5.0'), findsOneWidget);
      expect(find.text('Rating'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('Active Spots'), findsOneWidget);
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('Member since'), findsOneWidget);

      // 4. My Listings
      expect(find.text('My Listings'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);
      expect(find.text('Taco Food Stand'), findsOneWidget);
      expect(find.text('\$6'), findsOneWidget);
      expect(find.text('Vintage Jacket'), findsOneWidget);
      expect(find.text('\$45'), findsOneWidget);
      expect(find.text('Camera Rental'), findsOneWidget);
      expect(find.text('\$25/d'), findsOneWidget);

      // 5. Settings ListTiles
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Upgrade to Business (Local)'), findsOneWidget);
      expect(find.text('Community Rules'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
      expect(find.byIcon(Icons.verified_user_outlined), findsOneWidget);

      // 6. Bottom Navigation Bar
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('ProfileScreen renders dynamic user data and role badge from UserService', (WidgetTester tester) async {
      UserService.mockObtenerPerfil = () async {
        return UserProfileData(
          id: 'mock_user_99',
          nombre: 'Mariana Ruiz',
          correo: 'mariana.r@spotmarket.com',
          fotoPerfil: null, // Probar iniciales
          rolNombre: 'Local',
          reputacion: 4.8,
          fechaRegistro: DateTime(2024, 6, 15),
        );
      };

      UserService.mockObtenerSpots = () async {
        return [
          {
            'clave_spot': 'spot_101',
            'titulo': 'Panadería Artesanal Don Pancho',
            'precio': 35.0,
            'activo': true,
            'fecha_publicacion': '2026-03-01T10:00:00Z',
            'foto_spot': [
              {
                'url_foto': 'https://example.com/pan.jpg',
                'es_portada': true,
              }
            ],
          },
          {
            'clave_spot': 'spot_102',
            'titulo': 'Café de Olla Orgánico',
            'precio': 25.0,
            'activo': true,
            'fecha_publicacion': '2026-03-02T10:00:00Z',
            'foto_spot': [],
          },
        ];
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar nombre, correo, rol y avatar de iniciales
      expect(find.text('Mariana Ruiz'), findsOneWidget);
      expect(find.text('mariana.r@spotmarket.com'), findsOneWidget);
      expect(find.text('Local'), findsOneWidget);
      expect(find.text('MR'), findsOneWidget);

      // Verificar métricas calculadas dinámicamente
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // 2 spots activos
      expect(find.text('2024'), findsOneWidget); // Año de registro

      // Verificar spots renderizados en el carrusel
      expect(find.text('Panadería Artesanal Don Pancho'), findsOneWidget);
      expect(find.text('\$35'), findsOneWidget);
      expect(find.text('Café de Olla Orgánico'), findsOneWidget);
      expect(find.text('\$25'), findsOneWidget);
    });

    testWidgets('ProfileScreen displays Empty State when user has no spots and button opens AddSpotScreen', (WidgetTester tester) async {
      UserService.mockObtenerPerfil = () async {
        return UserProfileData(
          id: 'user_sin_spots',
          nombre: 'Carlos Vecino',
          correo: 'carlos@spotmarket.com',
          rolNombre: 'Vecino',
          reputacion: 5.0,
          fechaRegistro: DateTime(2026, 1, 1),
        );
      };

      UserService.mockObtenerSpots = () async => [];

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar que el estado vacío de "My Listings" se despliega correctamente
      expect(find.text('Aún no tienes publicaciones en el mapa'), findsOneWidget);
      expect(find.text('Publica tus productos, ropa de bazar o antojitos en tu colonia'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Crear publicación'), findsOneWidget);
      expect(find.text('0'), findsOneWidget); // 0 spots activos
    });

    testWidgets('ProfileScreen handles logout and redirects to LoginScreen', (WidgetTester tester) async {
      bool signOutCalled = false;
      UserService.mockSignOut = () async {
        signOutCalled = true;
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Buscar el ListTile de cerrar sesión en la lista de configuración
      await tester.ensureVisible(find.text('Cerrar sesión'));
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      // Verificar que se abre el diálogo de confirmación
      expect(find.text('¿Cerrar sesión?'), findsOneWidget);

      // Confirmar cierre de sesión
      final confirmBtn = find.widgetWithText(TextButton, 'Cerrar sesión');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verificar que se invocó mockSignOut y redirigió a LoginScreen
      expect(signOutCalled, isTrue);
      expect(find.text('Iniciar Sesión'), findsOneWidget);
      expect(find.text('El tianguis y bazar de tu colonia en el mapa'), findsOneWidget);
    });

    testWidgets('RegisterScreen renders all fields, clean layout without social auth, and validates inputs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar encabezado y títulos
      expect(find.text('Crear cuenta'), findsOneWidget);
      expect(find.text('Únete a la comunidad de comercio local en tu colonia'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      // Verificar que NO haya botones ni menciones de redes sociales (Google, Facebook, Apple)
      expect(find.text('Google'), findsNothing);
      expect(find.text('Facebook'), findsNothing);
      expect(find.text('Apple'), findsNothing);

      // Verificar etiquetas de campos
      expect(find.text('Nombre completo'), findsOneWidget);
      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('Confirmar contraseña'), findsOneWidget);
      expect(find.text('Crear Cuenta'), findsOneWidget);
      expect(find.text('Inicia sesión'), findsOneWidget);

      // Pulsar "Crear Cuenta" con campos vacíos para comprobar validaciones
      await tester.ensureVisible(find.text('Crear Cuenta'));
      await tester.tap(find.text('Crear Cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('Por favor ingresa tu nombre completo'), findsOneWidget);
      expect(find.text('Por favor ingresa tu correo electrónico'), findsOneWidget);
      expect(find.text('Por favor ingresa una contraseña'), findsOneWidget);
      expect(find.text('Por favor confirma tu contraseña'), findsOneWidget);

      // Validar formato de email inválido
      await tester.enterText(find.widgetWithText(TextFormField, 'ej. Gerardo Hipólito'), 'Juan Pérez');
      await tester.enterText(find.widgetWithText(TextFormField, 'ej. vecino@spotmarket.com'), 'correo_invalido');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mínimo 6 caracteres'), '12345');
      await tester.enterText(find.widgetWithText(TextFormField, 'Vuelve a escribir tu contraseña'), '123456');

      await tester.ensureVisible(find.text('Crear Cuenta'));
      await tester.tap(find.text('Crear Cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa un correo electrónico válido'), findsOneWidget);
      expect(find.text('La contraseña debe tener al menos 6 caracteres'), findsOneWidget);
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    });

    testWidgets('RegisterScreen handles successful signUp and AuthException error with SnackBar', (WidgetTester tester) async {
      String? capturedEmail;
      String? capturedPassword;
      String? capturedName;

      RegisterScreen.mockSignUp = ({
        required String email,
        required String password,
        Map<String, dynamic>? data,
      }) async {
        capturedEmail = email;
        capturedPassword = password;
        capturedName = data?['full_name'] as String?;
        return AuthResponse(
          session: null,
          user: User(
            id: 'mock_uid_123',
            appMetadata: {},
            userMetadata: data ?? {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Completar campos correctamente
      await tester.enterText(find.widgetWithText(TextFormField, 'ej. Gerardo Hipólito'), 'María del Carmen');
      await tester.enterText(find.widgetWithText(TextFormField, 'ej. vecino@spotmarket.com'), 'maria@spotmarket.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mínimo 6 caracteres'), 'secreto123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Vuelve a escribir tu contraseña'), 'secreto123');

      // Enviar formulario
      await tester.ensureVisible(find.text('Crear Cuenta'));
      await tester.tap(find.text('Crear Cuenta'));
      await tester.pump();

      // Verificar que se invocó con los datos adecuados
      expect(capturedEmail, 'maria@spotmarket.com');
      expect(capturedPassword, 'secreto123');
      expect(capturedName, 'María del Carmen');

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      // Verificar SnackBar verde de bienvenida
      expect(find.text('Cuenta creada con éxito. ¡Bienvenido a spotMarket!'), findsOneWidget);

      // Limpiar tickers del mapa
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 200));

      // Caso de prueba para AuthException
      RegisterScreen.mockSignUp = ({
        required String email,
        required String password,
        Map<String, dynamic>? data,
      }) async {
        throw const AuthException('El correo ya se encuentra registrado.');
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'ej. Gerardo Hipólito'), 'Pedro');
      await tester.enterText(find.widgetWithText(TextFormField, 'ej. vecino@spotmarket.com'), 'pedro@spotmarket.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mínimo 6 caracteres'), 'password');
      await tester.enterText(find.widgetWithText(TextFormField, 'Vuelve a escribir tu contraseña'), 'password');

      await tester.ensureVisible(find.text('Crear Cuenta'));
      await tester.tap(find.text('Crear Cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('El correo ya se encuentra registrado.'), findsOneWidget);

      // Limpiar hook
      RegisterScreen.mockSignUp = null;
    });

    testWidgets('RegisterScreen bottom link navigates back to Login with Navigator.pop', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text('Ir a Registro'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ir a Registro'));
      await tester.pumpAndSettle();

      expect(find.text('Crear cuenta'), findsOneWidget);

      // Tocar enlace "¿Ya tienes una cuenta? Inicia sesión"
      await tester.ensureVisible(find.text('Inicia sesión'));
      await tester.tap(find.text('Inicia sesión'));
      await tester.pumpAndSettle();

      // Debe haber regresado a la pantalla anterior
      expect(find.text('Ir a Registro'), findsOneWidget);
      expect(find.text('Crear cuenta'), findsNothing);
    });
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient();
  }
}

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}

  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {}

  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f) {}

  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String? realm)? f) {}

  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port)? callback) {}

  @override
  set findProxy(String Function(Uri url)? f) {}

  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) => open('delete', host, port, path);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('delete', url);

  @override
  Future<HttpClientRequest> get(String host, int port, String path) => open('get', host, port, path);

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('get', url);

  @override
  Future<HttpClientRequest> head(String host, int port, String path) => open('head', host, port, path);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('head', url);

  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) {
    return openUrl(method, Uri(scheme: 'http', host: host, port: port, path: path));
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    return Future.value(_FakeHttpClientRequest());
  }

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) => open('patch', host, port, path);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('patch', url);

  @override
  Future<HttpClientRequest> post(String host, int port, String path) => open('post', host, port, path);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('post', url);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) => open('put', host, port, path);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('put', url);

  @override
  set connectionFactory(Future<ConnectionTask<Socket>> Function(Uri url, String? proxyHost, int? proxyPort)? f) {}

  @override
  set keyLog(Function(String line)? callback) {}
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  bool bufferOutput = true;
  @override
  int contentLength = -1;
  @override
  Encoding encoding = utf8;
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  bool persistentConnection = true;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain();

  @override
  Future<HttpClientResponse> close() => Future.value(_FakeHttpClientResponse());

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  List<Cookie> get cookies => [];

  @override
  Future<HttpClientResponse> get done => Future.value(_FakeHttpClientResponse());

  @override
  Future<void> flush() => Future.value();

  @override
  String get method => 'GET';

  @override
  Uri get uri => Uri.parse('http://localhost');

  @override
  void write(Object? obj) {}

  @override
  void writeAll(Iterable objects, [String separator = ""]) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? obj = ""]) {}

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  bool chunkedTransferEncoding = false;
  @override
  int contentLength = -1;
  @override
  ContentType? contentType;
  @override
  DateTime? date;
  @override
  DateTime? expires;
  @override
  String? host;
  @override
  DateTime? ifModifiedSince;
  @override
  bool persistentConnection = true;
  @override
  int? port;

  @override
  List<String>? operator [](String name) => [];

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void clear() {}

  @override
  void forEach(void Function(String name, List<String> values) action) {}

  @override
  void noFolding(String name) {}

  @override
  void remove(String name, Object value) {}

  @override
  void removeAll(String name) {}

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  String? value(String name) => null;
}

class _FakeHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  // 1x1 transparent PNG
  static final Uint8List _pngBytes = Uint8List.fromList(<int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
    0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
    0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
    0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
    0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
    0x60, 0x82,
  ]);

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => 'OK';

  @override
  int get contentLength => _pngBytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_pngBytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  List<Cookie> get cookies => [];

  @override
  Future<Socket> detachSocket() => throw UnimplementedError();

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => true;

  @override
  Future<HttpClientResponse> redirect([String? method, Uri? url, bool? followLoops]) =>
      throw UnimplementedError();

  @override
  List<RedirectInfo> get redirects => [];
}
