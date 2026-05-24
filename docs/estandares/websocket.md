# WebSocket

## Stack

| Propósito | Librería |
|---|---|
| Comunicación en tiempo real (STOMP) | `stomp_dart_client: ^2.1.3` |
| Conexión raw (background) | `web_socket_channel: ^3.0.2` |

## WebSocketService (STOMP)

```dart
class WebSocketService {
  StompClient? _stompClient;
  bool _isConnected = false;
  final List<Map<String, dynamic>> _messageQueue = [];

  bool get isConnected => _isConnected;

  Future<void> connect() async { ... }
  Future<void> disconnect() async { ... }
  Future<void> subscribe() async { ... }
  Future<void> sendLocation({ ... }) async { ... }
  void _flushMessageQueue() { ... }
}
```

### Responsabilidades
- Conectar/desconectar al broker STOMP.
- Suscribirse a tópicos para recibir mensajes.
- Enviar ubicaciones al destino configurado.
- **Cola de mensajes offline**: si no hay conexión, los mensajes se encolan y se envían cuando se restablece la conexión.

### Configuración STOMP

```dart
_stompClient = StompClient(
  config: StompConfig(
    url: AppConstants.websocketUrl,
    onConnect: (StompFrame frame) {
      _isConnected = true;
      _flushMessageQueue();
    },
    onDisconnect: (StompFrame frame) {
      _isConnected = false;
    },
    onWebSocketError: (error) { ... },
    onStompError: (StompFrame frame) { ... },
    reconnectDelay: const Duration(seconds: 5),
    heartbeatOutgoing: const Duration(seconds: 10),
    heartbeatIncoming: const Duration(seconds: 10),
  ),
);
```

### Formato de mensaje de ubicación

```dart
final message = {
  'sender': AppConstants.websocketRemitente,  // 'conductor_app'
  'numberPlate': 'ABC-123',                    // TODO: dinámico
  'content': 'Coordenadas GPS: $lat, $lon',
  'latitude': latitude,
  'longitude': longitude,
  'timestamp': DateTime.now().toIso8601String(),
  'speed': speed,
  'accuracy': accuracy,
};
```

## WebSocket raw (background)

Usar `WebSocketChannel.connect()` para enviar ubicaciones desde tareas de background.

```dart
final channel = WebSocketChannel.connect(Uri.parse(AppConstants.websocketUrl));
await channel.ready;
channel.sink.add(jsonEncode(locationData));
await channel.sink.close();
```

## Reglas

- **No exponer** el cliente STOMP (`StompClient`) fuera del servicio.
- Los mensajes se envían con content-type `application/json`.
- El servicio maneja reconexión automática via STOMP config.
- Para background, abrir y cerrar conexión por cada envío (no mantener conexión permanente).
- Ubicación: `features/<feature>/services/websocket_service.dart`.
