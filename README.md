# SpotMarket

Marketplace móvil de compra y venta local desarrollado con Flutter y Supabase.

## Requisitos
- Flutter SDK y Dart (ver `pubspec.yaml`)
- Android Studio con un emulador o dispositivo físico
- Proyecto de Supabase con el esquema de `docs/esquema.sql`

## Instalación
1. `flutter pub get`
2. Configurar `lib/shared/services/supabase_config.dart` con la URL y la anon key.
3. `flutter run`
4. `flutter test`

## Roles
| Rol | Alcance |
|---|---|
| Administrador | Modera publicaciones y gestiona usuarios |
| Vendedor | Publica y administra productos |
| Cliente | Explora productos y guarda favoritos (rol base al registrarse) |

## Cuentas demo
| Rol | Correo | Contraseña |
|---|---|---|
| Administrador | admin@spotmarket.com | contra123 |
| Vendedor | vendedor@spotmarket.com | contra123 |
| Cliente | cliente@spotmarket.com | contra123 |

## Paquetes de impacto
| Paquete | Uso |
|---|---|
| adaptive_theme | Modo claro/oscuro persistente en toda la app |
| google_fonts | Tipografía Poppins global |
| go_router | Navegación y rutas protegidas por rol |