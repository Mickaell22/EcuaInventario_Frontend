# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Contexto del proyecto

Frontend móvil de **EcuaInventario**, plataforma SaaS gastronómica para pequeños negocios de comida en Ecuador. Flutter único para iOS y Android. El backend es Django REST Framework (aún no disponible); todas las pantallas actuales trabajan con datos mock.

El plan completo de desarrollo está en `frontend_movil_plan.md` — leerlo antes de implementar nuevas pantallas o modificar arquitectura.

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
│       └── app_router.dart    # GoRouter + StatefulShellRoute + SplashScreen + MainShell
├── core/
│   ├── config/app_config.dart # AppConfig.baseUrl vía --dart-define
│   └── api/api_client.dart    # Dio + interceptor JWT (flutter_secure_storage)
├── features/
│   ├── auth/login_screen.dart
│   ├── onboarding/onboarding_screen.dart
│   ├── home/home_screen.dart
│   ├── chat/chat_screen.dart
│   └── settings/settings_screen.dart
└── shared/widgets/
    └── placeholder_screen.dart  # Rutas pendientes de fase 2
```

### Navegación

- **Fuera del shell** (`/splash`, `/login`, `/onboarding`, `/register`): sin barra inferior.
- **Dentro del `StatefulShellRoute`** (`/home`, `/products`, `/chat`, `/suppliers`, `/settings`): envueltas en `MainShell` con `NavigationBar` y `PopScope` (atrás → va a `/home`; desde `/home` muestra diálogo de salida con `SystemNavigator.pop()`).
- **Flujo de primera vez:** `SplashScreen` lee `onboarding_done` de `SharedPreferences`. Si es `false` (o no existe) → `/onboarding`; si es `true` → `/login`. El onboarding guarda el flag al presionar "Empezar" u "Omitir`.

### Theming

`buildTheme(seedColor, brightness)` → `ThemeData` con `ColorScheme.fromSeed`. Constantes de marca:
- `kBrandNavy = Color(0xFF0F2044)` — AppBars, botones primarios, burbujas de usuario en chat
- `kBrandAmber = Color(0xFFF59E0B)` — FAB, botón enviar, ícono IA

**Regla importante:** nunca usar `Colors.white`, `Colors.grey.shade*` ni colores hardcodeados en widgets. Siempre usar `Theme.of(context).colorScheme.*` para garantizar compatibilidad con modo oscuro. La única excepción son los fondos de `AppBar` y las burbujas de usuario en chat, que usan `kBrandNavy` intencionalmente.

### Theming — colores del sistema a usar

| Necesidad | Token a usar |
|---|---|
| Fondo de superficie/card | `colorScheme.surface` / `colorScheme.surfaceContainerHighest` |
| Texto principal | `colorScheme.onSurface` |
| Texto secundario/hint | `colorScheme.onSurfaceVariant` |
| Bordes/divisores | `colorScheme.outlineVariant` |
| Color primario adaptable | `colorScheme.primary` |
| Iconos secundarios | `colorScheme.onSurfaceVariant` |

## Convenciones

- Archivos en `snake_case`, widgets en `PascalCase`, un widget público por archivo.
- Imports con ruta de paquete completa (`package:ecua_inventario/...`), nunca relativos.
- No usar `StatefulWidget` si Riverpod resuelve el estado.
- Strings de UI en español.
- Análisis estático estricto (`strict-casts`, `strict-inference`, `strict-raw-types`). Debe terminar en `No issues found!`.
- Código DRY y KISS: preferir `AppBar` estándar sobre headers custom, `ListView` sobre `CustomScrollView` cuando no haya slivers reales, `for` en lugar de `.map().toList()`.

## Estado actual

### Fase 1 — implementadas (datos mock)

| Pantalla | Archivo | Notas |
|---|---|---|
| Splash | `app_router.dart` (`SplashScreen`) | Completa. Lee `onboarding_done` y redirige a onboarding o login |
| Onboarding | `features/onboarding/onboarding_screen.dart` | Completa. Guarda `onboarding_done=true` al finalizar u omitir |
| Login | `features/auth/login_screen.dart` | Completa, logo de marca incluido |
| Home / Dashboard | `features/home/home_screen.dart` | Completa, mock data |
| Chat IA | `features/chat/chat_screen.dart` | Flujo mock completo (texto → propuesta → confirmar) |
| Settings | `features/settings/settings_screen.dart` | Theming dinámico funcional |

### Fase 1 — pendientes

| Pantalla | Ruta | Estado |
|---|---|---|
| Registro de negocio | `/register` | Placeholder — por implementar |

### Fase 2 — pendientes (placeholders)

| Pantalla | Ruta |
|---|---|
| Productos / Insumos | `/products` |
| Proveedores | `/suppliers` |
| Detalle de producto | (sub-ruta de products) |
| Registro rápido de movimiento | (sub-ruta) |
| Perfil del usuario | (pendiente de ruta) |

### Deuda técnica conocida

- **No hay integración real con backend.** Al conectar, los cambios van en los archivos de cada feature; el cliente HTTP en `core/api/api_client.dart` ya tiene el interceptor JWT listo.

### Correcciones aplicadas (historial)

- **Modo oscuro resuelto:** se eliminaron todos los `Colors.grey` y `kBrandNavy` hardcodeados en texto/botones. Ahora se usan `colorScheme.primary`, `colorScheme.onPrimary` y `colorScheme.onSurfaceVariant` en `login_screen.dart`, `home_screen.dart`, `chat_screen.dart`, `settings_screen.dart` y `app_theme.dart` (NavigationBar).
- **Crash al salir:** el `PopScope` de `MainShell` usaba `Navigator.pop()` que crasheaba con GoRouter; corregido a `SystemNavigator.pop()`.
