# CLAUDE.md — EcuaInventario Frontend (Flutter)

## Contexto del proyecto

Frontend móvil de **EcuaInventario**, plataforma SaaS gastronómica para pequeños negocios de comida en Ecuador. Flutter único para iOS y Android. Backend: Django REST Framework (ver `../Backend/`).

El plan completo de desarrollo está en `frontend_movil_plan.md` y el plan de integración en `integracion_backend_plan.md` — leerlos antes de implementar nuevas pantallas o modificar arquitectura.

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
├── main.dart                  # Entrada: initializeDateFormatting('es') → ProviderScope → EcuaInventarioApp
├── app/
│   ├── app.dart               # MaterialApp.router, consume themeProvider
│   ├── theme/
│   │   ├── app_theme.dart     # buildTheme(seedColor, brightness) + kBrandNavy/kBrandAmber
│   │   └── theme_provider.dart # ThemeNotifier (Riverpod) persiste en SharedPreferences
│   └── router/
│       └── app_router.dart    # GoRouter + guard de auth + StatefulShellRoute + SplashScreen + MainShell
├── core/
│   ├── config/app_config.dart # AppConfig.baseUrl vía --dart-define
│   └── api/api_client.dart    # Dio + interceptor JWT + auto-refresh 401 + sessionExpiredNotifier
├── features/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── onboarding/onboarding_screen.dart
│   ├── home/home_screen.dart
│   ├── chat/chat_screen.dart
│   ├── products/
│   │   ├── product_models.dart      # MockProduct (temporal hasta integrar)
│   │   ├── products_screen.dart
│   │   ├── product_detail_screen.dart
│   │   └── movement_screen.dart
│   ├── suppliers/
│   │   ├── supplier_models.dart     # MockSupplier (temporal hasta integrar)
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
- Texto/íconos dentro de `_HomeAppBar` y `_SummaryBanner` → `Colors.white` con opacidad (sobre fondo navy)
- Ícono del botón chat activo → `Colors.white` (sobre fondo navy)

`ThemeNotifier` persiste en `SharedPreferences` (no `FlutterSecureStorage` — el tema no es dato sensible).

### Patrón del AppBar de Home

`HomeScreen` usa `PreferredSize(preferredSize: Size.fromHeight(155))`. Contiene `_HomeAppBar` → `_SummaryBanner` embebida. **No agregar** `AppBar` estándar a `HomeScreen`.

## Convenciones

- Archivos en `snake_case`, widgets en `PascalCase`, un widget público por archivo
- Imports con ruta de paquete completa (`package:ecua_inventario/...`), nunca relativos
- No usar `StatefulWidget` si Riverpod resuelve el estado
- Strings de UI en español
- Análisis estático estricto (`strict-casts`, `strict-inference`, `strict-raw-types`). Debe terminar en `No issues found!`
- Password mínimo **8 caracteres** (validado en login y register)

## Estado actual (2026-05-11)

### Pantallas MVP — todas implementadas con mock data

| # | Pantalla | Archivo | Notas |
|---|---|---|---|
| 1 | Splash | `app_router.dart` (`SplashScreen`) | Lee `onboarding_done`, redirige |
| 2 | Onboarding | `features/onboarding/onboarding_screen.dart` | Guarda `onboarding_done=true` |
| 3 | Login | `features/auth/login_screen.dart` | Mock → lista para conectar |
| 4 | Registro | `features/auth/register_screen.dart` | Captura `seed_color` → enviar como `negocio_seed_color` al integrar |
| 5 | Home / Dashboard | `features/home/home_screen.dart` | AppBar con resumen embebido, mock data |
| 6 | Chat IA | `features/chat/chat_screen.dart` | Flujo propuesta→confirmación mock |
| 7 | Productos | `features/products/products_screen.dart` | Búsqueda + filtros, mock |
| 8 | Detalle producto | `features/products/product_detail_screen.dart` | Cálculo de margen automático |
| 9 | Movimiento | `features/products/movement_screen.dart` | Entrada/salida mock |
| 10 | Proveedores | `features/suppliers/suppliers_screen.dart` | Lista + búsqueda, mock |
| 11 | Detalle proveedor | `features/suppliers/supplier_detail_screen.dart` | Crear/editar mock |
| 12 | Configuración | `features/settings/settings_screen.dart` | Theming dinámico real |
| 13 | Perfil | `features/profile/profile_screen.dart` | Datos + cambio de contraseña mock |

### Infraestructura de integración ya lista

- `api_client.dart`: interceptor JWT con auto-refresh 401 implementado y probado (sin errores de análisis)
- `app_router.dart`: guard de autenticación con verificación de expiración real del JWT
- `sessionExpiredNotifier`: redirect automático a `/login` cuando la sesión expira

### Pendiente (integración Flutter ↔ Django)

Ver `integracion_backend_plan.md` para el plan detallado. Orden:

1. **Auth** — `auth_models.dart`, `auth_service.dart`, `auth_provider.dart`, conectar login/registro
2. **Dashboard** — `dashboard_models.dart`, `dashboard_provider.dart`, conectar home
3. **Productos** — `product_api_models.dart`, `product_repository.dart`, `product_providers.dart`
4. **Proveedores** — `supplier_repository.dart`, `supplier_providers.dart`
5. **Chat** — `chat_models.dart`, `chat_service.dart`, `chat_provider.dart` (flujo propuesta real)
6. **Perfil/Negocio** — cargar datos reales, `negocioProvider`

Al registrar, convertir el `Color` a hex: `'#${_seedColor.value.toRadixString(16).substring(2).toUpperCase()}'` y enviarlo como `negocio_seed_color`.

### Deuda técnica post-integración

- Validar y mostrar errores de campo desde respuestas 400 del backend
- Loading states explícitos en cada pantalla (skeleton o `CircularProgressIndicator`)
- Manejo de estado offline (`SocketException`, `DioException` sin conexión)
- Optimistic updates en listas (productos, proveedores)
- Protección contra doble tap en "Confirmar" del chat
