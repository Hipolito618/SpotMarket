# SpotMarket

Marketplace móvil hiperlocal para comprar y vender en la colonia: antojitos, bazar y artículos de segunda mano, ubicados en un mapa. Desarrollado con Flutter y Supabase.

## Funcionalidades

- Registro, inicio de sesión y perfil de usuario con rol.
- Mapa con OpenStreetMap, ubicación actual en tiempo real y marcadores por puesto.
- Publicación de puestos con fotos (hasta 5), ubicación en el mapa y datos según el tipo de venta.
- Modo offline: lectura desde caché local, indicador de conexión y cola de publicaciones pendientes.
- Gestos: tap, doble tap, mantener presionado, deslizar y arrastrar.
- Modo claro y oscuro.

## Requisitos

- Flutter SDK con Dart `^3.13.2`
- Android Studio (emulador o dispositivo físico)
- Proyecto de Supabase con las tablas y el bucket descritos en [Base de datos](#base-de-datos)

## Instalación

```bash
git clone https://github.com/Hipolito618/SpotMarket.git
cd SpotMarket
flutter pub get
flutter run
flutter test
```

Las credenciales públicas de Supabase se configuran en `lib/core/config/supabase_config.dart`. No se debe usar la clave `service_role` en la aplicación.

## Estructura del proyecto

```
lib/
├── main.dart
├── core/
│   ├── config/        Configuración de Supabase
│   ├── controllers/   Controlador de tema
│   └── theme/         Colores y temas claro/oscuro
├── models/            Modelos de datos (SpotItem)
├── screens/
│   ├── auth/          Inicio de sesión y registro
│   ├── home/          Mapa principal
│   ├── profile/       Perfil y publicaciones del usuario
│   └── spots/         Alta de puestos
├── services/          Supabase, caché local, conectividad y cola de pendientes
└── widgets/           Componentes reutilizables
```

## Dependencias

### Base del proyecto

| Paquete | Uso |
|---|---|
| `supabase_flutter` | Autenticación, base de datos y almacenamiento de imágenes |
| `flutter_map` + `latlong2` | Mapa con OpenStreetMap y marcadores |
| `geolocator` | Ubicación actual y permisos |
| `shared_preferences` | Sesión, caché de spots y perfil, favoritos y cola de pendientes |
| `connectivity_plus` | Detección de conexión para el modo offline |

### Herramientas de impacto (FlutterGems)

| Paquete | Uso |
|---|---|
| `google_fonts` | Tipografías Rubik y Plus Jakarta Sans en toda la app |
| `flutter_animate` | Animaciones de entrada y del botón de tema |
| `flutter_rating_bar` | Calificación de reputación en el perfil |

### Extra

| Paquete | Uso |
|---|---|
| `image_picker` | Selección de fotos desde la galería al publicar |

## Modo offline

| Elemento | Comportamiento |
|---|---|
| Detección | `connectivity_plus` actualiza el estado de red en tiempo real |
| Indicador | Franja superior "Sin conexión · modo offline" con botón **Reintentar** |
| Lectura | Los spots y el perfil se guardan al consultarlos y se leen del dispositivo si no hay red |
| Escritura | Las publicaciones creadas sin conexión se guardan en una cola local y aparecen en el mapa como pendientes |
| Sincronización | Al volver la conexión, la cola se envía en orden y la franja muestra el progreso |

## Gestos

| Gesto | Dónde | Acción |
|---|---|---|
| Tap | Marcadores y tarjetas | Abre el detalle del puesto |
| Doble tap | Tarjetas de puestos | Agrega o quita de favoritos |
| Mantener presionado | Tarjetas de puestos | Menú de opciones |
| Deslizar | Perfil, lista de publicaciones | Elimina la publicación |
| Arrastrar | Hoja inferior del mapa | Expande o repliega la lista |
| Pellizcar | Mapa | Acerca o aleja |

## Base de datos

Tablas en Supabase: `usuario`, `rol`, `categoria`, `spot`, `comida`, `bazar`, `reventa` y `foto_spot`.
Almacenamiento: bucket público `spots-media` para las fotos de las publicaciones.

## Roles

| Rol | Alcance |
|---|---|
| (completar) | (completar) |
| (completar) | (completar) |
| (completar) | (completar) |

## Cuentas de demostración

| Rol | Correo | Contraseña |
|---|---|---|
| (completar) | (completar) | (completar) |
| (completar) | (completar) | (completar) |
| (completar) | (completar) | (completar) |

## Equipo

(completar)