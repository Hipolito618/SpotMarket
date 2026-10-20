import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spot_market/main.dart';
import 'package:spot_market/core/controllers/theme_controller.dart';
import 'package:spot_market/models/spot_item.dart';
import 'package:spot_market/screens/home/map_home_screen.dart';
import 'package:spot_market/widgets/spot_preview_modal.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
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
