# UI / Widgets

## Tema global

```dart
MaterialApp(
  title: AppConstants.appName,
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: AppConstants.cardElevation,   // 4.0
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius), // 12.0
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  ),
  debugShowCheckedModeBanner: false,
  home: const RouteTrackingPage(),
);
```

## Constantes de UI

```dart
class AppConstants {
  static const double defaultPadding = 16.0;
  static const double cardElevation = 4.0;
  static const double borderRadius = 12.0;
}
```

## Patrones de widget

### Página con BlocBuilder

```dart
class RouteTrackingPage extends StatelessWidget {
  const RouteTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocBuilder<RouteTrackingBloc, RouteTrackingState>(
        builder: (context, state) => _buildBody(context, state),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }
}
```

### Dispatch de eventos

```dart
Future<void> _startNewRoute(BuildContext context) async {
  context.read<RouteTrackingBloc>().add(const StartRoute('driver_001'));
}

void _pauseRoute(BuildContext context) {
  context.read<RouteTrackingBloc>().add(const PauseRoute());
}
```

Los métodos que disparan eventos se definen en la Page y reciben `BuildContext`.

### Card con ícono y título

```dart
Widget _buildStatusCard(
  BuildContext context,
  String title,
  Color color,
  IconData icon,
) {
  return Card(
    elevation: AppConstants.cardElevation,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
```

## Navegación

Actualmente se usa `MaterialApp` con `home:` sin `go_router` ni `Navigator 2.0`.

```dart
MaterialApp(
  home: const RouteTrackingPage(),
)
```

- Cada feature expone su página principal como widget público.
- Las transiciones entre features se manejan con `Navigator.push` con el widget destino.

## Reglas

- **Material 3** obligatorio (`useMaterial3: true`).
- **`ColorScheme.fromSeed`** con un color semilla.
- **`const`** widgets siempre que sea posible.
- **`super.key`** en todos los constructores de widget.
- Strings en UI en **español**.
- Botones usan `ElevatedButton.icon`.
- Layouts responsivos con `SingleChildScrollView` + `padding: 16.0`.
- No usar `setState` para estado compartido. Usar BLoC.
- `debugShowCheckedModeBanner: false`.
