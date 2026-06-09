# Facilito — App Móvil

App móvil Flutter para la plataforma SaaS gastronómica EcuaInventario. Gestión de inventario, proveedores, ventas y chat IA para pequeños negocios de comida en Ecuador.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-00B0D8?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=apple&logoColor=white)

---

## Funcionalidades

- **Auth** — login / registro con JWT y auto-refresh en 401
- **Dashboard** — ingresos del día, gastos, stock crítico
- **Inventario** — CRUD de productos con movimientos (entrada / salida / merma)
- **Proveedores** — CRUD completo
- **Perfil y configuración** — color seed del negocio, modo claro/oscuro
- **Chat IA** — flujo interpretar → proponer → confirmar → guardar

---

## Chat IA

El usuario escribe en lenguaje natural y el backend devuelve una propuesta estructurada. **Nunca se guarda sin confirmación explícita del usuario.**

```
"Compré 5 kg de arroz"
        ↓
Backend interpreta y propone movimiento
        ↓
Usuario confirma ✓  →  se registra
Usuario descarta ✗  →  no se guarda nada
```

---

## Stack

| Capa | Tecnología |
|------|-----------|
| Framework | Flutter |
| Estado | Riverpod (`riverpod_annotation`) |
| Navegación | `go_router` con `StatefulShellRoute` |
| HTTP | `dio` con interceptor JWT |
| Storage seguro | `flutter_secure_storage` |
| UI | Material 3 + `google_fonts` (Inter) |

---

## Backend

Consume la API REST de [EcuaInventario_Backend](https://github.com/Mickaell22/EcuaInventario_Backend).

---

## Correr localmente

```bash
git clone https://github.com/Mickaell22/EcuaInventario_Frontend.git
cd EcuaInventario_Frontend
flutter pub get
flutter run
```
