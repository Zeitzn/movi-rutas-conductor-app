# Arquitectura

## Estructura general

```
lib/
├── core/
│   ├── constants/       # Constantes globales (AppConstants)
│   └── errors/          # Jerarquía de Failure
├── features/
│   └── <feature>/
│       ├── bloc/        # Estado y eventos (BLoC)
│       ├── models/      # Modelos de dominio (Equatable)
│       ├── pages/       # Widgets pantalla completa
│       ├── repositories/# Abstracciones e implementaciones de datos
│       └── services/    # Lógica de servicios (ubicación, websocket, etc.)
└── main.dart
```

## Reglas

- **Cada feature es autocontenida.** No comparte BLoCs, modelos o servicios entre features. Lo que se comparte va en `core/`.
- **Prohibido**: carpetas `utils/`, `helpers/`, `common/` genéricas. Si algo se repite en 2+ features, va a `core/` con nombre explícito.
- **Prohibido**: archivos sin usar (como `widgets/gps_dialogs.dart`). Solo crear lo que se necesita.
- **Punto de entrada único**: `main.dart` con el árbol de providers y el `MaterialApp`.

## Flujo de datos

```
UI (Page) ──dispara──> Event (BLoC) ──usa──> Repository / Service
   ^                                                │
   └────── State (BLoC) ─────escucha──<─────────────┘
```

- La UI escucha estados via `BlocBuilder`.
- El BLoC recibe eventos, orquesta servicios/repositorios y emite estados.
- Los servicios acceden a APIs nativas (geolocator, websocket, etc.).
- Los repositorios abstraen el almacenamiento (actualmente en memoria).

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| UI Framework | Flutter + Material 3 |
| Estado | flutter_bloc + equatable |
| Ubicación | geolocator |
| Permisos | permission_handler |
| Background | workmanager |
| WebSocket | web_socket_channel + stomp_dart_client |
| Testing | flutter_test |
| Lints | flutter_lints |
