# Testing

## Stack

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
```

## Convenciones

- Archivos con sufijo `_test.dart`.
- Tests por feature, no tests monolíticos.
- Smoke test básico debe importar la app real (`MoviRutasApp`), no widgets template.

## Smoke test mínimo

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test placeholder', (WidgetTester tester) async {
    // TODO: Add proper widget tests for MoviRutasApp
    expect(true, isTrue);
  });
}
```

## Reglas

- No testear widgets que son código muerto.
- No referenciar clases eliminadas o renombradas.
- Mantener los tests actualizados con la implementation real.
- Testear comportamiento (lo que el usuario ve/hace), no implementación interna.
