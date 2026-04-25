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

El backend devuelve, por negocio:

```json
{
  "seed_color": "#1976D2",
  "theme_mode": "system"
}
```

- `seed_color`: color hex que el dueño del negocio elige en configuración.
- `theme_mode`: `light`, `dark` o `system`.

Flutter usa `ColorScheme.fromSeed(seedColor: ..., brightness: ...)` para generar las paletas clara y oscura automáticamente. La tipografía y los iconos son fijos para todos los negocios.

---

## Arquitectura

Estructura feature-first:

```
lib/
├── main.dart
├── app/
│   ├── app.dart              # MaterialApp, theme, router
│   ├── theme/                # ColorScheme, TextTheme, builders
│   └── router/               # go_router config
├── core/
│   ├── api/                  # cliente HTTP, interceptores, manejo de errores
│   ├── storage/              # SharedPreferences, secure storage
│   └── utils/
├── features/
│   ├── auth/
│   ├── onboarding/
│   ├── home/
│   ├── chat/
│   ├── products/
│   ├── inventory/
│   ├── suppliers/
│   ├── settings/
│   └── profile/
└── shared/
    └── widgets/              # componentes reutilizables
```

Dentro de cada feature, mantener plano en MVP. Subdividir en `data/`, `domain/`, `presentation/` solo cuando la feature crezca.

---

## Pantallas del MVP

### Alcance de esta primera fase (1 a 6)

| # | Pantalla | Descripción |
|---|---|---|
| 1 | Splash | Carga inicial, verifica sesión, trae el theme del negocio del backend |
| 2 | Onboarding | 2-3 pantallas presentando el valor de la app, solo primera vez |
| 3 | Login | Email y contraseña |
| 4 | Registro de negocio | Datos básicos del negocio + selección de color seed |
| 5 | Home / Dashboard | Resumen del día: ventas, costos, alertas de stock, accesos rápidos |
| 6 | Chat IA | Texto, audio y foto. Muestra propuestas del LLM con botones de confirmar/editar antes de guardar |

### Pendiente para fases siguientes (7 a 12)

| # | Pantalla | Descripción |
|---|---|---|
| 7 | Lista de productos/insumos | Listado con búsqueda, filtros, FAB para agregar |
| 8 | Detalle de producto | Ver y editar: nombre, precio, costo, margen, stock, proveedor |
| 9 | Registro rápido de movimiento | Entrada/salida de inventario en pocos taps |
| 10 | Proveedores | Lista y detalle simple |
| 11 | Configuración | Datos del negocio, color seed, modo claro/oscuro, cerrar sesión |
| 12 | Perfil del usuario | Datos personales, cambio de contraseña |

---

## Plan de ejecución (fase 1)

### Paso 1: Scaffold del proyecto

- Crear proyecto Flutter limpio.
- Configurar dependencias en `pubspec.yaml`:
  - `flutter_riverpod`
  - `go_router`
  - `google_fonts`
  - `dio`
  - `shared_preferences`
  - `flutter_secure_storage`
- Configurar análisis estático estricto en `analysis_options.yaml`.
- Estructura de carpetas según la sección Arquitectura.

### Paso 2: Sistema de theming

- `app/theme/app_theme.dart` con función `buildTheme(seedColor, brightness)` que retorna `ThemeData` usando `ColorScheme.fromSeed`.
- Aplicar Inter como `textTheme` global.
- Provider de Riverpod que expone el theme actual (seed color + modo).
- Persistir preferencia local con `shared_preferences`.
- Por defecto: seed color de la marca de la plataforma (a definir cuando exista identidad propia, por ahora un azul neutral) + modo `system`.

### Paso 3: Router

- `app/router/app_router.dart` con go_router.
- Definir todas las rutas (las 12), pero las pantallas pendientes apuntan a un placeholder.
- Lógica de redirección: si no hay sesión, va a login. Si es primer ingreso, va a onboarding.

### Paso 4: Cliente HTTP base

- `core/api/api_client.dart` con dio configurado.
- Interceptor para token JWT.
- Manejo centralizado de errores.
- BaseUrl desde variable de entorno o constante.

### Paso 5: Pantallas 1 a 6

Orden recomendado de implementación:

1. **Splash** — Lo más simple, valida que el theming carga.
2. **Login** — Valida flujo completo: form, llamada al backend, guardado de token, redirección.
3. **Registro de negocio** — Incluye selector de color seed (color picker simple).
4. **Onboarding** — Pantallas estáticas con PageView.
5. **Home / Dashboard** — Por ahora con datos mock, se conecta al backend cuando los endpoints existan.
6. **Chat IA** — La más compleja. Subdividir:
   - UI base del chat (mensajes del usuario y del asistente).
   - Input de texto.
   - Grabación de audio (paquete `record` o similar).
   - Captura/selección de foto.
   - Tarjeta de propuesta del LLM con botones confirmar/editar.

---

## Convenciones de código

- Nombres de archivos en `snake_case`.
- Widgets en `PascalCase`.
- Un widget público por archivo.
- Separar lógica de UI: providers de Riverpod manejan estado, los widgets solo lo consumen.
- No usar `StatefulWidget` si Riverpod resuelve el caso.
- Constantes de diseño (paddings, radios, durations) centralizadas en `app/theme/`.
- Strings de UI en español.

---

## Lo que NO se hace en esta fase

- Pantallas 7 a 12.
- Integración real con backend (se trabaja con mocks o endpoints stub).
- Notificaciones push.
- Modo offline.
- Tests automatizados extensivos (sí pruebas básicas de smoke).
- Deploy a stores.

---

## Criterios de cierre de la fase 1

- App instalable en Android (debug build).
- Theming dinámico funciona: cambiar el seed color desde configuración (aunque sea hardcodeado por ahora) actualiza toda la UI.
- Modo claro y oscuro funcionan y se pueden alternar.
- Las 6 pantallas navegan correctamente entre sí con go_router.
- Chat IA muestra el flujo completo: enviar mensaje, ver propuesta, confirmar, ver mensaje de éxito (aunque la respuesta del LLM sea mock).
- Código pasa el analizador estático sin warnings.
