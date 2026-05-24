# Estilo de código y convenciones

## Lints

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml
```

Usar el set de lints recomendado por Flutter. No desactivar reglas sin una razón documentada.

## Convenciones generales

| Aspecto | Estándar |
|---|---|
| `const` | Usar siempre que sea posible (widgets, constructores, constantes) |
| `super.key` | En todos los constructores de widget |
| Inmutabilidad | Preferir `final` sobre `var`. Clases de datos con propiedades `final` |
| null safety | Obligatorio. `?` para nullable, `!` solo cuando es seguro |
| `print()` | Temporal. Migrar a un logging framework (`package:logging`) |

## Idioma

| Contexto | Idioma |
|---|---|
| Código (identificadores, clases, métodos, variables) | Inglés |
| Comentarios técnicos | Inglés |
| Strings de UI (textos visibles al usuario) | Español |
| Nombres de archivos | snake_case en inglés |

## Nombres

| Elemento | Convención | Ejemplo |
|---|---|---|
| Clases | PascalCase | `RouteTrackingBloc`, `LocationService` |
| Métodos | camelCase | `_onStartRoute()`, `getLocationStream()` |
| Variables | camelCase | `_currentRoute`, `locationSubscription` |
| Archivos | snake_case | `route_tracking_bloc.dart` |
| Constantes | camelCase (prefijo semántico) | `backgroundTaskName`, `websocketUrl` |
| Enums | camelCase | `RouteStatus.inProgress` |

## imports

- Preferir imports relativos dentro del mismo feature.
- Preferir imports de package para referencias externas o entre features lejanas.
- Agrupar: (1) dart:* , (2) package: externos, (3) imports del proyecto. Separar con líneas en blanco.

```dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../models/route.dart';
import '../repositories/route_repository.dart';
```

## Anti-patrones (prohibido)

| Práctica | Alternativa |
|---|---|
| Carpetas `utils/`, `helpers/`, `common/` | Mover a `core/` con nombre semántico |
| Clases con 300+ líneas | Dividir en servicios, BLoCs, widgets |
| `dynamic` en modelos | Tipar con `num` + `.toDouble()` |
| `setState` para estado compartido | Usar BLoC |
| Inicializar servicios con `new` dentro del BLoC | Inyectar por constructor |
| `print()` en producción (meta) | Migrar a `package:logging` |
| Crear archivos que no se usan | Solo crear lo que se necesita |
| `MaterialApp` sin `debugShowCheckedModeBanner: false` | Siempre desactivar el banner |

## Dependencias

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_bloc: ^9.1.1
  equatable: ^2.0.7
  geolocator: ^14.0.2
  permission_handler: ^12.0.1
  workmanager: ^0.9.0+3
  web_socket_channel: ^3.0.2
  stomp_dart_client: ^2.1.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```
