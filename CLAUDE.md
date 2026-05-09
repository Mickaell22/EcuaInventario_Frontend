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
│       └── app_router.dart    # GoRouter + StatefulShellRoute + SplashScreen + MainShell + _CustomNavBar
├── core/
│   ├── config/app_config.dart # AppConfig.baseUrl vía --dart-define
│   └── api/api_client.dart    # Dio + interceptor JWT (flutter_secure_storage)
├── features/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── onboarding/onboarding_screen.dart
│   ├── home/home_screen.dart
│   ├── chat/chat_screen.dart
│   ├── products/
│   │   ├── product_models.dart      # MockProduct, ProductCategory, StockStatus, kMockProducts
│   │   ├── products_screen.dart     # Lista con búsqueda y filtros
│   │   ├── product_detail_screen.dart # Crear/editar producto, cálculo de margen
│   │   └── movement_screen.dart     # Registro rápido entrada/salida
│   ├── suppliers/
│   │   ├── supplier_models.dart     # MockSupplier, kMockSuppliers
│   │   ├── suppliers_screen.dart    # Lista con búsqueda
│   │   └── supplier_detail_screen.dart # Crear/editar proveedor
│   ├── profile/
│   │   └── profile_screen.dart      # Datos personales + cambio de contraseña
│   └── settings/settings_screen.dart
└── shared/widgets/
    └── placeholder_screen.dart
```

### Navegación

- **Fuera del shell** (`/splash`, `/login`, `/onboarding`, `/register`, `/profile`): sin barra inferior.
- **Dentro del `StatefulShellRoute`** (`/home`, `/products`, `/chat`, `/suppliers`, `/settings`): envueltas en `MainShell` con `_CustomNavBar` y `PopScope` (atrás → va a `/home`; desde `/home` muestra diálogo de salida con `SystemNavigator.pop()`).
- **`_CustomNavBar`** (en `app_router.dart`): barra personalizada con 4 ítems normales + botón central elevado para Chat. Implementada con `Stack(clipBehavior: Clip.none)` y `Positioned(top: -18)` para el botón flotante amber. NO usar `NavigationBar` estándar de Material 3.
- **Sub-rutas de products:** `/products/new`, `/products/:id`, `/products/:id/move`.
- **Sub-rutas de suppliers:** `/suppliers/new`, `/suppliers/:id`.
- **Perfil:** accesible desde el avatar del AppBar en `HomeScreen` → `context.push('/profile')`.
- **Flujo de primera vez:** `SplashScreen` lee `onboarding_done` de `SharedPreferences`. Si es `false` (o no existe) → `/onboarding`; si es `true` → `/login`. El onboarding guarda el flag al presionar "Empezar" u "Omitir".

### Theming

`buildTheme(seedColor, brightness)` → `ThemeData` con `ColorScheme.fromSeed`. Constantes de marca:
- `kBrandNavy = Color(0xFF0F2044)` — AppBars, botones primarios, burbujas de usuario en chat, botón chat activo en nav bar
- `kBrandAmber = Color(0xFFF59E0B)` — FAB, botón enviar, botón chat en nav bar, avatar de perfil

**Regla importante:** nunca usar `Colors.white`, `Colors.grey.shade*` ni colores hardcodeados en widgets. Siempre usar `Theme.of(context).colorScheme.*` para garantizar compatibilidad con modo oscuro. Las excepciones intencionales son:
- Fondos de `AppBar` → `kBrandNavy`
- Burbujas de usuario en chat → `kBrandNavy`
- Texto/íconos/decoraciones **dentro** de `_HomeAppBar` y `_SummaryBanner` → `Colors.white` con opacidad (siempre sobre fondo navy)
- Ícono del botón chat activo en `_ChatNavButton` → `Colors.white` (sobre fondo navy)

### Theming — colores del sistema a usar

| Necesidad | Token a usar |
|---|---|
| Fondo de superficie/card | `colorScheme.surface` / `colorScheme.surfaceContainerHighest` |
| Texto principal | `colorScheme.onSurface` |
| Texto secundario/hint | `colorScheme.onSurfaceVariant` |
| Bordes/divisores | `colorScheme.outlineVariant` |
| Color primario adaptable | `colorScheme.primary` |
| Iconos secundarios | `colorScheme.onSurfaceVariant` |

### Patrón del AppBar de Home

`HomeScreen` usa `PreferredSize(preferredSize: Size.fromHeight(155))` en lugar del `AppBar` estándar. Contiene `_HomeAppBar` → `_SummaryBanner` embebida. **No agregar** `AppBar` estándar a `HomeScreen`; el patrón `PreferredSize` + `SafeArea(bottom: false)` es intencional para incrustar la tarjeta resumen dentro del header navy.

## Convenciones

- Archivos en `snake_case`, widgets en `PascalCase`, un widget público por archivo.
- Imports con ruta de paquete completa (`package:ecua_inventario/...`), nunca relativos.
- No usar `StatefulWidget` si Riverpod resuelve el estado.
- Strings de UI en español.
- Análisis estático estricto (`strict-casts`, `strict-inference`, `strict-raw-types`). Debe terminar en `No issues found!`.
- Código DRY y KISS: `ListView` sobre `CustomScrollView` cuando no haya slivers reales, `for` en lugar de `.map().toList()`.
- Para dark mode en cards con sombra: usar `boxShadow: isDark ? null : [BoxShadow(...)]` + `border: isDark ? Border.all(color: cs.outlineVariant) : null`.

## Estado actual

### Todas las pantallas del MVP — implementadas (datos mock)

| # | Pantalla | Archivo | Notas |
|---|---|---|---|
| 1 | Splash | `app_router.dart` (`SplashScreen`) | Icono 88×88, glow amber. Lee `onboarding_done`, redirige |
| 2 | Onboarding | `features/onboarding/onboarding_screen.dart` | Guarda `onboarding_done=true` al finalizar u omitir |
| 3 | Login | `features/auth/login_screen.dart` | Logo de marca incluido |
| 4 | Registro de negocio | `features/auth/register_screen.dart` | Tipo de negocio (chips) + selector de color seed |
| 5 | Home / Dashboard | `features/home/home_screen.dart` | AppBar con resumen embebido + acciones rápidas + movimientos mock |
| 6 | Chat IA | `features/chat/chat_screen.dart` | Flujo mock completo (texto → propuesta → confirmar) |
| 7 | Productos / Insumos | `features/products/products_screen.dart` | Búsqueda + filtros Todos/Insumos/Platos; FAB → nuevo |
| 8 | Detalle de producto | `features/products/product_detail_screen.dart` | Crear/editar; cálculo de margen automático; link a movimiento |
| 9 | Registro de movimiento | `features/products/movement_screen.dart` | Entrada/salida con cantidad y nota; snackbar de confirmación |
| 10 | Proveedores | `features/suppliers/suppliers_screen.dart` | Lista con búsqueda; FAB → nuevo |
| 11 | Detalle de proveedor | `features/suppliers/supplier_detail_screen.dart` | Crear/editar: nombre, contacto, teléfono, email, dirección |
| 12 | Configuración | `features/settings/settings_screen.dart` | Theming dinámico + link a perfil |
| 13 | Perfil del usuario | `features/profile/profile_screen.dart` | Datos personales + cambio de contraseña (expandible) |

### Mock data

- **Productos** (`product_models.dart`): 6 insumos + 3 platos típicos ecuatorianos.
- **Proveedores** (`supplier_models.dart`): 3 proveedores de ejemplo (Quito y Guayaquil).
- **Movimientos home** (`home_screen.dart`): 3 movimientos mock (aceite de oliva, harina, leche).

### Deuda técnica conocida

- **No hay integración real con backend.** Al conectar, los cambios van en los archivos de cada feature; el cliente HTTP en `core/api/api_client.dart` ya tiene el interceptor JWT listo.
- **Mock data estática.** Los formularios simulan guardado con un delay; no modifican el estado en memoria. Al integrar el backend se reemplaza con providers Riverpod que llamen a la API.
- **Nombre del negocio hardcodeado** en `_HomeAppBar` como `'Cevichería El Pacífico'`. Al integrar auth, leer del perfil del usuario via Riverpod provider.

### Correcciones y mejoras aplicadas (historial)

- **Modo oscuro resuelto:** se eliminaron todos los `Colors.grey` y `kBrandNavy` hardcodeados en texto/botones. Ahora se usan `colorScheme.primary`, `colorScheme.onPrimary` y `colorScheme.onSurfaceVariant`.
- **Crash al salir:** el `PopScope` de `MainShell` usaba `Navigator.pop()` que crasheaba con GoRouter; corregido a `SystemNavigator.pop()`.
- **`DropdownButtonFormField.value` deprecado:** migrado a `initialValue` en `product_detail_screen.dart`.
- **Rediseño UI (prototipo Claude Design):** barra de navegación custom con botón chat elevado amber; `HomeScreen` con AppBar embebido (resumen Ingresos/Gastos/Utilidad), sección de acciones rápidas (4 ítems) y movimientos mock con datos reales.
