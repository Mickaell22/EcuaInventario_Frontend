# Frontend Móvil — Plan de Desarrollo

Plataforma SaaS gastronómica para pequeños negocios de comida en Ecuador. Este documento define el alcance, decisiones y plan de ejecución del cliente móvil en Flutter.

---

## Contexto

- SaaS multitenancy: varios negocios usan la misma app, cada uno con su identidad visual.
- Usuarios objetivo: dueños de restaurantes, cevicherías y emprendimientos informales que vienen del papel o Excel.
- El móvil es el canal principal de uso diario (cocina, mostrador, recepción de proveedores).
- El chat IA es la puerta de entrada para usuarios sin experiencia previa con software de gestión.

---

## Stack del frontend móvil

| Área | Decisión |
|---|---|
| Framework | Flutter (una base para iOS y Android) |
| Sistema de UI | Material 3 puro |
| Theming | Seed color dinámico desde backend, claro y oscuro |
| Tipografía | Inter (vía `google_fonts`) |
| Iconografía | Material Icons |
| Estado | Riverpod |
| Navegación | go_router |
| HTTP | dio |
| Almacenamiento local | shared_preferences + flutter_secure_storage |

---

## Principios de diseño

1. **No reinventar la rueda** — Material 3 cubre el 90% de necesidades visuales sin esfuerzo.
2. **Personalización simple** — El negocio elige un color seed, Flutter genera la paleta completa con `ColorScheme.fromSeed()`. Sin permitir combinaciones que se vean mal.
3. **Modo claro y oscuro** — Ambos disponibles desde MVP. El usuario elige claro, oscuro o automático.
4. **Tipografía e iconografía únicas** — Mantienen identidad de plataforma aunque cada negocio personalice colores.
5. **Mobile-first real** — Pensado para uso con una mano, en cocina, con prisas. Botones grandes, flujos cortos.
6. **Interpretar, proponer, confirmar, escribir** — El chat IA nunca guarda sin confirmación humana explícita.

---

## Theming

El backend devolverá, por negocio:

```json
{
  "seed_color": "#1976D2",
  "theme_mode": "system"
}
```

- `seed_color`: color hex que el dueño del negocio elige en configuración.
- `theme_mode`: `light`, `dark` o `system`.

Flutter usa `ColorScheme.fromSeed(seedColor: ..., brightness: ...)` para generar las paletas clara y oscura automáticamente. La tipografía y los iconos son fijos para todos los negocios.

Constantes de marca definidas:
- `kBrandNavy = Color(0xFF0F2044)` — AppBars, burbujas de usuario en chat
- `kBrandAmber = Color(0xFFF59E0B)` — FAB, botón enviar, ícono IA

---

## Arquitectura

Estructura feature-first:

```
lib/
├── main.dart                  # initializeDateFormatting('es') → ProviderScope → EcuaInventarioApp
├── app/
│   ├── app.dart               # MaterialApp.router, consume themeProvider
│   ├── theme/
│   │   ├── app_theme.dart     # buildTheme(seedColor, brightness) + constantes de marca
│   │   └── theme_provider.dart # ThemeNotifier (Riverpod) persiste en SharedPreferences
│   └── router/
│       └── app_router.dart    # GoRouter + StatefulShellRoute + SplashScreen + MainShell
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
│   │   ├── product_models.dart
│   │   ├── products_screen.dart
│   │   ├── product_detail_screen.dart
│   │   └── movement_screen.dart
│   ├── suppliers/
│   │   ├── supplier_models.dart
│   │   ├── suppliers_screen.dart
│   │   └── supplier_detail_screen.dart
│   ├── profile/profile_screen.dart
│   └── settings/settings_screen.dart
└── shared/widgets/
    └── placeholder_screen.dart
```

---

## Navegación

- **Fuera del shell** (`/splash`, `/login`, `/onboarding`, `/register`, `/profile`): sin barra inferior.
- **Dentro del `StatefulShellRoute`** (`/home`, `/products`, `/chat`, `/suppliers`, `/settings`): envueltas en `MainShell` con `NavigationBar` y `PopScope` (atrás → va a `/home`; desde `/home` muestra diálogo de salida con `SystemNavigator.pop()`).
- **Sub-rutas de products:** `/products/new`, `/products/:id`, `/products/:id/move`.
- **Sub-rutas de suppliers:** `/suppliers/new`, `/suppliers/:id`.
- **Perfil:** accesible desde el avatar del AppBar en `HomeScreen` → `context.push('/profile')`.
- **Flujo de primera vez:** `SplashScreen` lee `onboarding_done` de `SharedPreferences`. Si es `false` → `/onboarding`; si es `true` → `/login`.

---

## Estado actual — Fase 1 completada

Todas las pantallas del MVP están implementadas con datos mock. El backend aún no existe; al conectarlo se reemplazan los mocks con llamadas reales sin tocar los widgets.

### Pantallas implementadas

| # | Pantalla | Archivo | Estado |
|---|---|---|---|
| 1 | Splash | `app_router.dart` (`SplashScreen`) | ✓ Lee `onboarding_done`, redirige |
| 2 | Onboarding | `features/onboarding/onboarding_screen.dart` | ✓ Guarda flag al finalizar u omitir |
| 3 | Login | `features/auth/login_screen.dart` | ✓ Logo de marca incluido |
| 4 | Registro de negocio | `features/auth/register_screen.dart` | ✓ Tipo de negocio (chips) + selector de color seed |
| 5 | Home / Dashboard | `features/home/home_screen.dart` | ✓ Mock data; avatar navega a `/profile` |
| 6 | Chat IA | `features/chat/chat_screen.dart` | ✓ Flujo mock completo (texto → propuesta → confirmar) |
| 7 | Productos / Insumos | `features/products/products_screen.dart` | ✓ Búsqueda + filtros Todos/Insumos/Platos; FAB |
| 8 | Detalle de producto | `features/products/product_detail_screen.dart` | ✓ Crear/editar; cálculo de margen automático |
| 9 | Registro de movimiento | `features/products/movement_screen.dart` | ✓ Entrada/salida con cantidad y nota |
| 10 | Proveedores | `features/suppliers/suppliers_screen.dart` | ✓ Lista con búsqueda; FAB |
| 11 | Detalle de proveedor | `features/suppliers/supplier_detail_screen.dart` | ✓ Crear/editar con todos los campos |
| 12 | Configuración | `features/settings/settings_screen.dart` | ✓ Theming dinámico + link a perfil |
| 13 | Perfil del usuario | `features/profile/profile_screen.dart` | ✓ Datos personales + cambio de contraseña |

### Mock data

- **Productos** (`product_models.dart`): 6 insumos + 3 platos típicos ecuatorianos.
- **Proveedores** (`supplier_models.dart`): 3 proveedores de ejemplo (Quito y Guayaquil).

---

## Fase 2 — Conexión con el backend

Cuando el backend Django esté disponible, los cambios se concentran en la capa de datos, no en los widgets.

### Pasos de integración

1. Definir `BASE_URL` en `AppConfig` apuntando al backend Railway.
2. **Auth:** conectar login y registro a los endpoints JWT reales; guardar `access` y `refresh` en `flutter_secure_storage`. El interceptor de Dio ya está listo.
3. **Negocio:** traer `seed_color` y `theme_mode` reales desde `/api/negocio/` en el Splash y aplicarlos al `ThemeNotifier`.
4. **Productos y proveedores:** reemplazar listas mock con providers Riverpod que llamen a la API.
5. **Dashboard:** reemplazar datos mock con la respuesta de `/api/dashboard/`.
6. **Chat IA:** enviar mensajes, audio y fotos a los endpoints reales y mostrar las propuestas del LLM.

---

## Convenciones de código

- Nombres de archivos en `snake_case`, widgets en `PascalCase`, un widget público por archivo.
- Imports con ruta de paquete completa (`package:ecua_inventario/...`), nunca relativos.
- No usar `StatefulWidget` si Riverpod resuelve el estado.
- Strings de UI en español.
- Análisis estático estricto (`strict-casts`, `strict-inference`, `strict-raw-types`). Debe terminar en `No issues found!`.
- **Nunca usar `Colors.white`, `Colors.grey.shade*` ni colores hardcodeados en widgets.** Siempre `Theme.of(context).colorScheme.*`. Excepción: `kBrandNavy` en AppBars y burbujas de usuario en chat.

### Tokens de color a usar

| Necesidad | Token |
|---|---|
| Fondo de superficie/card | `colorScheme.surface` / `colorScheme.surfaceContainerHighest` |
| Texto principal | `colorScheme.onSurface` |
| Texto secundario/hint | `colorScheme.onSurfaceVariant` |
| Bordes/divisores | `colorScheme.outlineVariant` |
| Color primario adaptable | `colorScheme.primary` |
| Iconos secundarios | `colorScheme.onSurfaceVariant` |

---

## Correcciones aplicadas

- **Modo oscuro:** eliminados todos los `Colors.grey` y `kBrandNavy` hardcodeados en texto/botones. Ahora se usan tokens `colorScheme`.
- **Crash al salir:** `PopScope` usaba `Navigator.pop()` que crasheaba con GoRouter; corregido a `SystemNavigator.pop()`.
- **`DropdownButtonFormField.value` deprecado:** migrado a `initialValue` en `product_detail_screen.dart`.

---

## Lo que NO se hace en esta fase

- Notificaciones push.
- Modo offline.
- Tests automatizados extensivos.
- Deploy a stores.
- Roles múltiples (empleados con permisos distintos).
