# Movi Rutas

Aplicación móvil para conductores que permite gestionar rutas con seguimiento de geolocalización en tiempo real, desarrollada con Flutter 3.38.4 y arquitectura BLoC.

El objetivo de la aplicación es enviar la ubicación del conductor en tiempo real a un websocket. La ubicación debe enviarse en segundo plano incluso si la pantalla está apagada.

## 🚀 Características Principales

- **Gestión de Rutas**: Iniciar, pausar, reanudar y finalizar rutas
- **Geolocalización en Tiempo Real**: Seguimiento continuo de la ubicación del conductor
- **Servicio en Segundo Plano**: Geolocalización persistente incluso con la aplicación cerrada
- **Arquitectura Limpia**: Implementación con BLoC para gestión de estados
- **Interfaz Intuitiva**: Diseño Material Design 3 con estados visuales claros

## 📋 Requisitos

- **Flutter**: 3.38.4 (gestionado con FVM)
- **Dart**: 3.10.3
- **Android SDK**: API 29+ (Android 10+)
- **Android NDK**: 27.0.12077973 (descargado automáticamente)
- **Java**: JDK 17+

## 🛠️ Configuración del Entorno

### 1. Instalar FVM (Flutter Version Management)
```bash
dart pub global activate fvm
```

### 2. Instalar Flutter 3.38.4
```bash
fvm install 3.38.4
fvm use 3.38.4
```

### 3. Configurar Android SDK
Asegúrate de tener instalado:
- Android SDK Platform-Tools
- Android SDK Build-Tools
- Android NDK (Side by side) 27.0.12077973
- Android 10 (API level 29) o superior

### 4. Clonar y Configurar el Proyecto
```bash
git clone <repository-url>
cd movi_rutas
fvm flutter pub get
```

## 🏗️ Arquitectura del Proyecto

### Estructura de Carpetas
```
lib/
├── core/                           # Configuración global
│   ├── constants/
│   │   └── app_constants.dart      # Constantes de la aplicación
│   └── errors/
│       └── failures.dart           # Definición de errores personalizados
├── features/
│   └── route_tracking/             # Módulo principal de seguimiento de rutas
│       ├── bloc/                   # Gestión de estados con BLoC
│       │   ├── route_tracking_bloc.dart
│       │   ├── route_tracking_event.dart
│       │   └── route_tracking_state.dart
│       ├── models/                 # Modelos de datos
│       │   ├── route.dart
│       │   └── route_point.dart
│       ├── repositories/           # Capa de datos
│       │   └── route_repository.dart
│       ├── services/              # Servicios externos
│       │   ├── location_service.dart
│       │   └── background_location_service.dart
│       └── pages/                 # Interfaz de usuario
│           └── route_tracking_page.dart
└── main.dart                      # Punto de entrada de la aplicación
```

### Patrones Arquitectónicos

- **BLoC Pattern**: Para gestión de estados reactiva
- **Repository Pattern**: Para abstracción de fuentes de datos
- **Service Layer**: Para lógica de negocio y servicios externos
- **Dependency Injection**: Con `RepositoryProvider` y `BlocProvider`

## 📦 Dependencias Principales

```yaml
dependencies:
  flutter_bloc: ^9.1.1          # Gestión de estados BLoC
  equatable: ^2.0.7             # Comparación de objetos
  geolocator: ^14.0.2           # Geolocalización
  permission_handler: ^12.0.1    # Gestión de permisos
  workmanager: ^0.9.0+3         # Tareas en segundo plano
```

## 🔧 Configuración Android

### Permisos Configurados
Los siguientes permisos están configurados en `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### Servicios en Segundo Plano
- **Foreground Service**: Para geolocalización continua
- **WorkManager**: Para tareas periódicas en segundo plano

## 🚀 Ejecución de la Aplicación

### 1. Verificar Dispositivos Conectados
```bash
fvm flutter devices
```

### 2. Ejecutar en Dispositivo Android
```bash
fvm flutter run
```

### 3. Ejecutar en Linux Desktop (para desarrollo)
```bash
fvm flutter run -d linux
```

### 4. Construir APK
```bash
fvm flutter build apk --debug
```

## 📱 Flujo de la Aplicación

### 1. Pantalla Inicial
- Bienvenida al conductor
- Botón para iniciar nueva ruta

### 2. Ruta Activa
- Visualización en tiempo real de:
  - Tiempo transcurrido
  - Número de puntos registrados
  - Distancia total recorrida
- Lista de últimas ubicaciones
- Controles para pausar/finalizar

### 3. Ruta Pausada
- Estado visual de pausa
- Opciones para reanudar o finalizar

### 4. Ruta Finalizada
- Resumen completo de la ruta
- Estadísticas finales
- Opción para iniciar nueva ruta

## 🔄 Gestión de Estados (BLoC)

### Estados Principales
- `RouteTrackingInitial`: Estado inicial
- `RouteTrackingLoading`: Cargando operaciones
- `RouteTrackingInProgress`: Ruta activa
- `RouteTrackingPaused`: Ruta pausada
- `RouteTrackingCompleted`: Ruta finalizada
- `RouteTrackingError`: Error en la operación

### Eventos Principales
- `StartRoute`: Iniciar nueva ruta
- `PauseRoute`: Pausar ruta activa
- `ResumeRoute`: Reanudar ruta pausada
- `EndRoute`: Finalizar ruta
- `UpdateLocation`: Actualizar ubicación

## 📍 Servicios de Geolocalización

### LocationService
- Gestión de permisos de ubicación
- Obtención de posición actual
- Stream de actualizaciones de ubicación
- Manejo de errores de GPS

### BackgroundLocationService
- Configuración de WorkManager
- Tareas periódicas en segundo plano
- Persistencia de ubicaciones

## 🗄️ Almacenamiento de Datos

### RouteRepository
- **Actual**: Almacenamiento en memoria (para desarrollo)
- **Futuro**: Integración con SQLite/Hive para persistencia local
- **Escalable**: Fácil integración con APIs REST

### Modelos de Datos

#### Route
```dart
class Route {
  final String id;
  final String driverId;
  final DateTime startTime;
  final DateTime? endTime;
  final List<RoutePoint> points;
  final RouteStatus status;
  final double totalDistance;
  final int duration;
}
```

#### RoutePoint
```dart
class RoutePoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? speed;
  final double? accuracy;
}
```

## 🐛 Solución de Problemas Comunes

### Problemas con NDK
Si encuentras errores con el NDK:
```bash
# Eliminar NDK corrupto
rm -rf $ANDROID_HOME/ndk/27.0.12077973

# Limpiar proyecto
fvm flutter clean
fvm flutter pub get

# Reintentar construcción
fvm flutter build apk --debug
```

### Permisos de Ubicación
Asegúrate de que el dispositivo tenga:
- GPS activado
- Permisos de ubicación concedidos
- Configuración de ubicación de fondo permitida

### Problemas de Build
```bash
# Limpiar completamente
fvm flutter clean
cd android && ./gradlew clean && cd ..
fvm flutter pub get
fvm flutter run
```

## 🔮 Mejoras Futuras

### Características Planificadas
- [ ] Integración con base de datos local (SQLite/Hive)
- [ ] Sincronización con servidor remoto
- [ ] Autenticación de conductores
- [ ] Historial de rutas
- [ ] Exportación de datos (GPS, KML)
- [ ] Notificaciones de ruta
- [ ] Optimización de batería
- [ ] Modo offline mejorado

### Mejoras Técnicas
- [ ] Testing unitario y de integración
- [ ] CI/CD con GitHub Actions
- [ ] Análisis estático de código
- [ ] Internacionalización (i18n)
- [ ] Temas personalizados

## 🤝 Contribución

### Flujo de Trabajo
1. Crear rama feature desde `main`
2. Desarrollar siguiendo la arquitectura establecida
3. Escribir pruebas unitarias
4. Ejecutar análisis de código
5. Crear Pull Request

### Estándares de Código
- Seguir convenciones de Dart/Flutter
- Usar dart format para formateo
- Documentar clases y métodos públicos
- Mantener la arquitectura limpia

## 📄 Licencia

Este proyecto está bajo licencia [MIT License](LICENSE).

## 📞 Contacto

Para preguntas o soporte:
- [Issues del proyecto](<repository-url>/issues)
- [Discusiones](<repository-url>/discussions)

---

**Nota**: Esta aplicación fue desarrollada como demostración de arquitectura Flutter con BLoC y geolocalización en tiempo real. Para producción, se recomienda implementar persistencia de datos robusta y autenticación de usuarios.
