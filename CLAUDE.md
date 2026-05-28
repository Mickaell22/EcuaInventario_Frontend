# CLAUDE.md — Facilito Frontend (Flutter)

## Contexto del proyecto

Frontend móvil de **Facilito**, plataforma SaaS gastronómica para pequeños negocios de comida en Ecuador. Flutter único para iOS y Android. Backend: Django REST Framework (ver `../Backend/`).

## Entorno

- Flutter en `/opt/flutter/bin/flutter` (no está en el PATH de root). Siempre usar la ruta completa.
- El usuario del sistema es `mickaell`. Todos los archivos del proyecto deben pertenecerle a él, no a root.
- Dispositivo de prueba: TECNO LH7n (ID `103953736M000152`), Android 14, pantalla 360 dp.

## Comandos frecuentes

```bash
# Análisis estático — debe terminar en "No issues found!"
ANDROID_HOME=/home/mickaell/Android/Sdk PATH=$PATH:/home/mickaell/Android/Sdk/platform-tools \
  /opt/flutter/bin/flutter analyze

# Instalar dependencias
ANDROID_HOME=/home/mickaell/Android/Sdk /opt/flutter/bin/flutter pub get

# Correr en el teléfono físico
ANDROID_HOME=/home/mickaell/Android/Sdk PATH=$PATH:/home/mickaell/Android/Sdk/platform-tools \
  /opt/flutter/bin/flutter run -d 103953736M000152

# Correr apuntando a Railway (por defecto, sin --dart-define)
ANDROID_HOME=/home/mickaell/Android/Sdk PATH=$PATH:/home/mickaell/Android/Sdk/platform-tools \
  /opt/flutter/bin/flutter run -d 103953736M000152

# Correr apuntando al backend local (misma red WiFi)
ANDROID_HOME=/home/mickaell/Android/Sdk PATH=$PATH:/home/mickaell/Android/Sdk/platform-tools \
  /opt/flutter/bin/flutter run -d 103953736M000152 \
  --dart-define=BASE_URL=http://192.168.X.X:8000

# Ver dispositivos conectados
ANDROID_HOME=/home/mickaell/Android/Sdk PATH=$PATH:/home/mickaell/Android/Sdk/platform-tools \
  /opt/flutter/bin/flutter devices
```

## Arquitectura

### Estructura de carpetas

```
lib/
├── main.dart                        # Entrada: initializeDateFormatting('es') → ProviderScope → FacilitoApp
├── app/
│   ├── app.dart                     # MaterialApp.router, consume themeProvider
│   ├── theme/
│   │   ├── app_theme.dart           # buildTheme(seedColor, brightness) + kBrandNavy/kBrandAmber
│   │   └── theme_provider.dart      # ThemeNotifier (Riverpod) persiste en SharedPreferences
│   └── router/
│       └── app_router.dart          # GoRouter + guard de auth + StatefulShellRoute + SplashScreen + MainShell
├── core/
│   ├── config/app_config.dart       # AppConfig.baseUrl vía --dart-define
│   └── api/
│       ├── api_client.dart          # Dio + interceptor JWT + auto-refresh 401 + sessionExpiredNotifier
│       └── api_client_provider.dart # Provider<ApiClient> singleton (Riverpod)
├── features/
│   ├── auth/
│   │   ├── auth_models.dart         # UsuarioDto, NegocioDto, AuthTokens
│   │   ├── auth_service.dart        # login(), registro(), logout(), perfil(), actualizarPerfil(), cambiarPassword()
│   │   ├── auth_provider.dart       # authServiceProvider, usuarioProvider, negocioProvider, AuthServiceX.dioError()
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── onboarding/onboarding_screen.dart
│   ├── home/
│   │   ├── dashboard_models.dart    # DashboardData, UltimoMovimiento
│   │   ├── dashboard_provider.dart  # FutureProvider.autoDispose → GET /api/dashboard/
│   │   └── home_screen.dart
│   ├── chat/
│   │   ├── chat_api_models.dart     # ChatRespuesta, ConfirmarRequest, ConfirmarRespuesta
│   │   ├── chat_service.dart        # enviarMensaje(), confirmar()
│   │   ├── chat_provider.dart       # chatServiceProvider
│   │   └── chat_screen.dart
│   ├── products/
│   │   ├── product_api_models.dart  # ProductoDto, MovimientoDto, ProductCategory, StockStatus
│   │   ├── product_repository.dart  # listar(), obtener(), crear(), actualizar(), eliminar(), registrarMovimiento()
│   │   ├── product_providers.dart   # productRepositoryProvider, productosProvider, productoProvider.family
│   │   ├── product_models.dart      # MockProduct — sin importadores, archivo huérfano (no eliminar aún)
│   │   ├── products_screen.dart
│   │   ├── product_detail_screen.dart
│   │   └── movement_screen.dart
│   ├── suppliers/
│   │   ├── supplier_api_models.dart  # ProveedorDto
│   │   ├── supplier_repository.dart  # listar(), obtener(), crear(), actualizar(), eliminar()
│   │   ├── supplier_providers.dart   # supplierRepositoryProvider, proveedoresProvider, proveedorProvider.family
│   │   ├── supplier_models.dart      # MockSupplier — sin importadores, archivo huérfano (no eliminar aún)
│   │   ├── suppliers_screen.dart
│   │   └── supplier_detail_screen.dart
│   ├── profile/profile_screen.dart
│   └── settings/settings_screen.dart
└── shared/widgets/placeholder_screen.dart
```

### Cliente HTTP (`core/api/api_client.dart`)

`ApiClient` expone un `Dio` configurado con:
- `baseUrl`: `AppConfig.baseUrl` (inyectado vía `--dart-define=BASE_URL=...`)
- Timeouts: `connectTimeout=15s`, `receiveTimeout=30s`, `sendTimeout=30s`
- Interceptor `_AuthInterceptor` que:
  1. Añade `Authorization: Bearer <access_token>` en cada request
  2. En 401: intenta refresh con `refresh_token` → reintenta el request original con `_dio.fetch()` (misma instancia, no `Dio()` nueva)
  3. Si el refresh falla: borra todos los tokens (`deleteAll()`) e incrementa `sessionExpiredNotifier`
  4. Flag `extra['_retried']` en el request reintentado para evitar bucles infinitos

**`sessionExpiredNotifier`** es un `ValueNotifier<int>` exportado desde `api_client.dart`. El `GoRouter` lo escucha con `refreshListenable` para re-evaluar el redirect cuando la sesión expira.

### Providers de autenticación (`features/auth/auth_provider.dart`)

- `authServiceProvider` — `Provider<AuthService>` singleton
- `usuarioProvider` — `StateProvider<UsuarioDto?>` actualizado en login/logout
- `negocioProvider` — `StateProvider<NegocioDto?>` actualizado en login/logout
- `AuthServiceX` — extensión con `static String dioError(Object e)` que extrae mensajes DRF desde `DioException.response.data` (prueba las keys: `detail`, `non_field_errors`, `email`, `password`, `error`)

### Navegación (`app/router/app_router.dart`)

- **Guard de autenticación:** `redirect: _authRedirect` verifica en cada navegación:
  - Si la ruta es pública (`/splash`, `/onboarding`, `/login`, `/register`) → deja pasar
  - Si no hay `access_token` o está expirado (decodifica el JWT sin verificar firma, solo lee `exp`) → redirige a `/login`
- **`refreshListenable: sessionExpiredNotifier`** — el router re-evalúa el redirect automáticamente cuando el interceptor detecta sesión expirada
- **Fuera del shell** (`/splash`, `/login`, `/onboarding`, `/register`, `/profile`): sin barra inferior
- **Dentro del `StatefulShellRoute`** (`/home`, `/products`, `/chat`, `/suppliers`, `/settings`): envueltas en `MainShell` con `_CustomNavBar`
- **PopScope en MainShell:** back desde tab 0 → diálogo de salida → `SystemNavigator.pop()` **solo en Android** (`Platform.isAndroid`); desde otras tabs → vuelve a `/home`
- **`_CustomNavBar`**: barra personalizada con 4 ítems + botón Chat central elevado amber. NO usar `NavigationBar` estándar.

### Theming

`buildTheme(seedColor, brightness)` → `ThemeData` con `ColorScheme.fromSeed`. Constantes de marca:
- `kBrandNavy = Color(0xFF0F2044)` — AppBars, botones primarios, burbujas de usuario en chat
- `kBrandAmber = Color(0xFFF59E0B)` — FAB, botón enviar, botón chat en nav bar

**Regla:** nunca hardcodear `Colors.white`, `Colors.grey.shade*` ni colores arbitrarios en widgets. Usar `Theme.of(context).colorScheme.*`. Excepciones intencionales:
- Fondos de `AppBar` → `kBrandNavy`
- Burbujas de usuario en chat → `kBrandNavy`
- Texto/íconos del `AppBar` de Home (sobre fondo navy) → `Colors.white` con opacidad
- Ícono del botón chat activo → `Colors.white` (sobre fondo navy)

`ThemeNotifier` persiste en `SharedPreferences` (no `FlutterSecureStorage` — el tema no es dato sensible).

### AppBar de Home

`HomeScreen` usa `AppBar` estándar de Material 3 con `backgroundColor: kBrandNavy`. Muestra fecha y nombre del negocio en el título, y el botón de perfil en `actions`. **No usar** `PreferredSize` ni `_SummaryBanner` — ese patrón fue eliminado en el rediseño.

### Manejo de errores de API

Todos los formularios que llaman a la API muestran el error con `_ErrorBanner` inline (no SnackBar, no Dialog). El helper `AuthServiceX.dioError(e)` extrae el mensaje desde `DioException.response.data`.

## Convenciones

- Archivos en `snake_case`, widgets en `PascalCase`, un widget público por archivo
- Imports con ruta de paquete completa (`package:facilito/...`), nunca relativos
- No usar `StatefulWidget` si Riverpod resuelve el estado
- Strings de UI en español
- Análisis estático estricto (`strict-casts`, `strict-inference`, `strict-raw-types`). Debe terminar en `No issues found!`
- Password mínimo **8 caracteres** (validado en login y register)
- `DropdownButtonFormField` usa `initialValue:` (no `value:`, que está deprecado)
- `Color` a hex: `color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()` (no `.value`, deprecado)
- Entradas de mapa condicionales con key literal: usar `if (x != null) 'key': x` + `// ignore: use_null_aware_elements` (el operador `?'key'` genera otro error)

## Estado actual (2026-05-26) — integración completa

### Pantallas MVP — todas conectadas al backend real

| # | Pantalla | Archivo | Estado |
|---|---|---|---|
| 1 | Splash | `app_router.dart` | Lee `onboarding_done`, redirige |
| 2 | Onboarding | `features/onboarding/onboarding_screen.dart` | Guarda `onboarding_done=true` |
| 3 | Login | `features/auth/login_screen.dart` | Conectado — POST `/api/auth/login/` |
| 4 | Registro | `features/auth/register_screen.dart` | Conectado — POST `/api/auth/registro/` con `negocio_seed_color` |
| 5 | Home / Dashboard | `features/home/home_screen.dart` | Conectado — GET `/api/dashboard/` |
| 6 | Chat IA | `features/chat/chat_screen.dart` | Conectado — POST `/api/chat/mensaje/` + `/api/chat/confirmar/` |
| 7 | Productos | `features/products/products_screen.dart` | Conectado — GET `/api/inventario/productos/` |
| 8 | Detalle producto | `features/products/product_detail_screen.dart` | Conectado — CRUD `/api/inventario/productos/` |
| 9 | Movimiento | `features/products/movement_screen.dart` | Conectado — POST `/api/inventario/productos/{id}/movimiento/` |
| 10 | Proveedores | `features/suppliers/suppliers_screen.dart` | Conectado — GET `/api/proveedores/` |
| 11 | Detalle proveedor | `features/suppliers/supplier_detail_screen.dart` | Conectado — CRUD `/api/proveedores/` |
| 12 | Configuración | `features/settings/settings_screen.dart` | Theming dinámico (SharedPreferences) |
| 13 | Perfil | `features/profile/profile_screen.dart` | Conectado — GET/PATCH `/api/auth/perfil/` + cambiar contraseña |

### Flujos de estado confirmados

- Login/registro → tokens en `FlutterSecureStorage` → actualiza `usuarioProvider` + `negocioProvider` → navega a `/home`
- Logout → `authService.logout()` (deleteAll tokens) + limpia providers → navega a `/login`
- Cambio de contraseña → backend blacklistea todos los tokens → frontend hace logout automático → navega a `/login`
- Dashboard: `FutureProvider.autoDispose` + `RefreshIndicator` para pull-to-refresh
- Productos/Proveedores: `FutureProvider.autoDispose` + `ref.invalidate()` al volver de pantallas de edición
- Chat: `_confirming` bool guard contra doble tap en Confirmar; propuesta muestra `resumen` del backend

### Cambios (2026-05-28)

- `AppConfig.baseUrl` apunta a Railway por defecto (`https://web-production-8e7ef.up.railway.app`). Para desarrollo local usar `--dart-define=BASE_URL=http://<IP>:8000`.

### Cambios (2026-05-26)

- App renombrada a **Facilito**: package `facilito`, applicationId `com.facilito.app`, labels Android/iOS, texto UI
- Home rediseñado: `AppBar` simple + sección "Resumen de hoy" como lista plana (sin grilla de tarjetas)
- `product_repository.dart` y `supplier_repository.dart`: `listar()` maneja respuesta paginada `{count, results:[...]}`
- `NegocioDto._safeHexColor()`: valida formato `#RRGGBB` con regex antes de almacenar el seed_color del backend

### Pendientes post-MVP

- Audio y foto en chat (botones ya presentes en `ChatScreen` sin acción)
- Eliminar productos y proveedores (botón pendiente en pantallas de detalle)
- Loading skeleton en pantallas de lista
- Manejo de estado offline (`SocketException`)
- Optimistic updates en listas
- Endpoint PATCH `/api/negocios/` para actualizar nombre del negocio desde perfil
