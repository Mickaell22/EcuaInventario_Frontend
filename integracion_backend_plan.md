# Plan de integración Flutter ↔ Django

Estado al momento de escribir este plan:
- Frontend: todas las pantallas MVP con datos mock
- Backend: auditado y corregido, listo para integrarse
- `api_client.dart`: Dio + interceptor JWT ya implementado

---

## Endpoints del backend (base: `http://<ip>:8000`)

| Feature | Método | URL |
|---|---|---|
| Registro | POST | `/api/auth/registro/` |
| Login | POST | `/api/auth/login/` |
| Refresh token | POST | `/api/auth/token/refresh/` |
| Perfil usuario | GET/PATCH | `/api/auth/perfil/` |
| Mi negocio | GET/PATCH | `/api/negocios/mi-negocio/` |
| Productos (lista/crear) | GET/POST | `/api/inventario/productos/` |
| Producto (detalle/editar/eliminar) | GET/PATCH/DELETE | `/api/inventario/productos/{id}/` |
| Movimientos (lista/crear) | GET/POST | `/api/inventario/movimientos/` |
| Proveedores (lista/crear) | GET/POST | `/api/proveedores/` |
| Proveedor (detalle/editar/eliminar) | GET/PATCH/DELETE | `/api/proveedores/{id}/` |
| Dashboard | GET | `/api/dashboard/` |
| Chat texto | POST | `/api/chat/mensaje/` |
| Chat audio | POST | `/api/chat/audio/` |
| Chat foto | POST | `/api/chat/foto/` |
| Confirmar acción chat | POST | `/api/chat/confirmar/` |
| Ventas (lista/crear) | GET/POST | `/api/ventas/` |

---

## Orden de implementación recomendado

### Fase 1 — Auth (base para todo lo demás)

**Archivos a crear:**
- `features/auth/auth_models.dart` — `AuthTokens`, `UserProfile`, `NegocioInfo`
- `features/auth/auth_service.dart` — login(), registro(), logout(), refreshToken()
- `features/auth/auth_provider.dart` — `authStateProvider` (AsyncNotifier)

**Archivos a modificar:**
- `features/auth/login_screen.dart` — llamar `authService.login()`, navegar a `/home` si ok
- `features/auth/register_screen.dart` — llamar `authService.registro()`, tokens en storage
- `app/router/app_router.dart` — redirigir a `/login` si no hay token válido (guard en `redirect`)
- `core/api/api_client.dart` — agregar auto-refresh (interceptor `onError` 401 → refresh → retry)

**Tokens a guardar en `FlutterSecureStorage`:**
```
access_token   → access (caduca en 8h)
refresh_token  → refresh (caduca en 30d, rotación automática)
```

**Respuesta esperada del backend:**
```json
// POST /api/auth/login/
{ "access": "...", "refresh": "..." }

// POST /api/auth/registro/
{ "access": "...", "refresh": "...", "negocio": { "id": "...", "nombre": "..." } }
```

---

### Fase 2 — Dashboard / Home

**Archivos a crear:**
- `features/home/dashboard_models.dart` — `DashboardData`, `StockCritico`, `MovimientoResumen`
- `features/home/dashboard_provider.dart` — `dashboardProvider` (FutureProvider.autoDispose)

**Archivos a modificar:**
- `features/home/home_screen.dart`:
  - Leer nombre del negocio desde provider (reemplaza hardcode `'Cevichería El Pacífico'`)
  - `_SummaryBanner` consume ingresos/gastos/utilidad reales del dashboard
  - `_kMovements` reemplazado por últimos movimientos del dashboard
  - `_kIndicators` reemplazado por stock_critico, margen promedio, etc.

**Respuesta esperada:**
```json
{
  "ingresos": "1250.00",
  "gastos": "430.00",
  "utilidad": "820.00",
  "stock_critico": { "count": 2, "productos": [...] },
  "ultimos_movimientos": [...]
}
```

---

### Fase 3 — Productos

**Archivos a crear:**
- `features/products/product_api_models.dart` — `ProductoDto`, `MovimientoDto`
- `features/products/product_repository.dart` — CRUD + registrar movimiento
- `features/products/product_providers.dart` — `productosProvider`, `productoProvider(id)`

**Archivos a modificar:**
- `features/products/products_screen.dart` — lista real, búsqueda paginada
- `features/products/product_detail_screen.dart` — crear/editar llaman a API; soft-delete en eliminar
- `features/products/movement_screen.dart` — `POST /api/inventario/movimientos/`

**Notas importantes:**
- Los campos del modelo: `id`, `nombre`, `categoria`, `precio_venta`, `costo`, `stock_actual` (read-only), `unidad`, `stock_minimo`, `proveedor`, `proveedor_nombre`, `stock_bajo`, `activo`
- `stock_actual` es read-only — el backend lo actualiza al confirmar movimientos
- Eliminar = `DELETE` (hace soft-delete en el backend, devuelve 204)

---

### Fase 4 — Proveedores

**Archivos a crear:**
- `features/suppliers/supplier_repository.dart` — CRUD
- `features/suppliers/supplier_providers.dart`

**Archivos a modificar:**
- `features/suppliers/suppliers_screen.dart`
- `features/suppliers/supplier_detail_screen.dart`

**Campos del modelo:** `id`, `nombre`, `contacto`, `telefono`, `email`, `direccion`, `activo`

---

### Fase 5 — Chat IA

**Archivos a crear:**
- `features/chat/chat_service.dart` — enviarMensaje(), enviarAudio(), enviarFoto(), confirmarAccion()
- `features/chat/chat_message_models.dart` — `ChatMessage`, `ChatPropuesta`

**Archivos a modificar:**
- `features/chat/chat_screen.dart`:
  - Reemplazar mock por llamadas reales a `chat_service`
  - Flujo: usuario escribe → `POST /mensaje/` → backend devuelve `{ok, accion, resumen, datos}` → mostrar propuesta → usuario confirma → `POST /confirmar/` → mostrar resultado

**Respuesta del backend tras propuesta:**
```json
{ "ok": true, "accion": "registrar_movimiento", "resumen": "Entrada de 5L de aceite de oliva", "datos": {...} }
```

**Respuesta tras confirmar:**
```json
{ "ok": true, "tipo": "movimiento", "id": "uuid", "detalle": "Entrada de 5 L de aceite de oliva registrada." }
```

---

### Fase 6 — Perfil y Negocio

**Archivos a modificar:**
- `features/profile/profile_screen.dart` — cargar nombre/email real desde `GET /api/auth/perfil/`
- Nombre del negocio en `_HomeAppBar` → leer de un `negocioProvider`

---

## Cambios transversales necesarios

### `api_client.dart` — agregar auto-refresh en 401

```dart
@override
Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
  if (err.response?.statusCode == 401) {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken != null) {
      try {
        final response = await Dio().post(
          '${AppConfig.baseUrl}/api/auth/token/refresh/',
          data: {'refresh': refreshToken},
        );
        final newAccess = response.data['access'] as String;
        final newRefresh = response.data['refresh'] as String?;
        await _storage.write(key: 'access_token', value: newAccess);
        if (newRefresh != null) {
          await _storage.write(key: 'refresh_token', value: newRefresh);
        }
        // Retry original request
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
        final retryResponse = await Dio().fetch(err.requestOptions);
        return handler.resolve(retryResponse);
      } catch (_) {
        await _storage.deleteAll(); // tokens inválidos → forzar logout
      }
    }
  }
  handler.next(err);
}
```

### `app_router.dart` — redirect guard

```dart
redirect: (context, state) async {
  final token = await const FlutterSecureStorage().read(key: 'access_token');
  final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';
  if (token == null && !isAuthRoute) return '/login';
  return null;
},
```

### Provider global para `ApiClient`

```dart
// core/api/api_client_provider.dart
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
```

---

## Orden de pasos al implementar

1. Implementar auto-refresh en `api_client.dart`
2. Crear `apiClientProvider`
3. **Auth** → login/registro real → probar en teléfono
4. Agregar redirect guard al router
5. **Dashboard** → home con datos reales
6. **Productos** → CRUD completo + movimientos
7. **Proveedores** → CRUD completo
8. **Chat** → flujo real con propuesta + confirmación
9. **Perfil/Negocio** → datos del usuario

---

## Después: auditoría del frontend integrado

Una vez completada la integración, auditar:
- Manejo de errores (401, 400, 500, sin conexión)
- Loading states en cada pantalla
- Optimistic updates donde aplique
- Tokens expirados manejados correctamente
- Concurrencia (pull-to-refresh, doble tap en confirmar)
- Comportamiento offline
