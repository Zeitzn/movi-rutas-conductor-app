# Estándares del proyecto — Movi Rutas Conductor

> Basado en el análisis estático del código existente.
> Cada estándar está documentado en su propio archivo dentro de [`docs/estandares/`](docs/estandares/).

---

## Índice

| Archivo | Contenido |
|---|---|
| [`arquitectura.md`](docs/estandares/arquitectura.md) | Estructura general del proyecto, flujo de datos, stack tecnológico |
| [`bloc.md`](docs/estandares/bloc.md) | Estado global con flutter_bloc + equatable (eventos, estados, BLoC) |
| [`modelos.md`](docs/estandares/modelos.md) | Modelos de dominio: Equatable, copyWith, toJson/fromJson, props |
| [`repositorios.md`](docs/estandares/repositorios.md) | Patrón repositorio: interfaz abstracta + implementación concreta |
| [`servicios.md`](docs/estandares/servicios.md) | LocationService, BackgroundLocationService, inyección |
| [`websocket.md`](docs/estandares/websocket.md) | WebSocket STOMP y raw: conexión, mensajes, cola offline |
| [`errores.md`](docs/estandares/errores.md) | Jerarquía de Failure, cuándo usar cada uno |
| [`ui.md`](docs/estandares/ui.md) | UI y widgets: tema global, navegación, patrones de widget |
| [`testing.md`](docs/estandares/testing.md) | Convenciones de testing con flutter_test |
| [`estilo.md`](docs/estandares/estilo.md) | Estilo de código, lints, nomenclatura, anti-patrones, dependencias |

---

## Resumen rápido

| Concepto | Estándar |
|---|---|
| **Arquitectura** | Feature-based con `core/` compartido |
| **Estado** | `flutter_bloc` + `equatable` |
| **Modelos** | `Equatable`, `copyWith`, `toJson/fromJson` |
| **Datos** | Repository pattern (interfaz abstracta + impl concreta) |
| **Servicios** | Una clase por responsabilidad |
| **Background** | `workmanager` + `MethodChannel` |
| **WebSocket** | `stomp_dart_client` (tiempo real) + `web_socket_channel` (background) |
| **Errores** | Jerarquía plana de `Failure` |
| **UI** | Material 3, `ColorScheme.fromSeed`, widgets en español |
| **Testing** | `flutter_test`, tests por feature |
| **Lints** | `flutter_lints` (recomendado) |

*Este documento debe actualizarse cuando se incorporen nuevas tecnologías o patrones al proyecto.*
