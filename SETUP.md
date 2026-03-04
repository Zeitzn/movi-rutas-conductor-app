# 🚀 Movi Rutas - Guía de Configuración

Esta guía proporciona instrucciones detalladas para configurar y desplegar la aplicación Movi Rutas en diferentes entornos.

## 📋 Tabla de Contenidos

1. [Requisitos Previos](#requisitos-previos)
2. [Configuración de Entorno](#configuración-de-entorno)
3. [Variables de Configuración](#variables-de-configuración)
4. [Configuración de WebSocket](#configuración-de-websocket)
5. [Configuración de Backend](#configuración-de-backend)
6. [Despliegue](#despliegue)
7. [Solución de Problemas](#solución-de-problemas)
8. [Monitoreo y Logs](#monitoreo-y-logs)

---

## 📋 Requisitos Previos

### Software Requerido
- **Flutter**: 3.38.4 (gestionado con FVM)
- **Dart**: 3.10.3+
- **Android Studio**: Latest Stable
- **Git**: Para control de versiones

### Hardware Requerido
- **Android SDK**: API 29+ (Android 10+)
- **Java**: JDK 17+
- **Memoria RAM**: 8GB+ recomendado
- **Almacenamiento**: 2GB+ libres

---

## ⚙️ Configuración de Entorno

### 1. Instalar FVM
```bash
# Instalar FVM (Flutter Version Management)
dart pub global activate fvm

# Verificar instalación
fvm --version
```

### 2. Instalar Flutter 3.38.4
```bash
# Instalar versión específica
fvm install 3.38.4

# Usar versión en el proyecto
fvm use 3.38.4

# Verificar versión activa
fvm flutter --version
```

### 3. Configurar Android SDK
```bash
# Establecer variable de entorno (opcional)
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# Verificar instalación
fvm flutter doctor
```

---

## 🌍 Variables de Configuración

### Archivo: `.env`

Crear archivo `.env` en la raíz del proyecto:

```env
# Configuración de Entorno
# Copiar este archivo a .env.local y ajustar valores locales

# 🌐 WebSocket Configuration
WEBSOCKET_HOST=your-websocket-server.com
WEBSOCKET_PORT=8080
WEBSOCKET_PROTOCOL=wss
WEBSOCKET_PATH=/ws

# 🔗 Backend API Configuration
API_BASE_URL=https://your-api-server.com/api
API_VERSION=v1
API_TIMEOUT=30000

# 🗄️ Database Configuration
DATABASE_URL=postgresql://user:password@localhost:5432/movi_rutas
DATABASE_NAME=movi_rutas_dev

# 🔐 Authentication
JWT_SECRET=your-super-secret-jwt-key-here
JWT_EXPIRY_HOURS=24

# 📱 Push Notifications
FCM_SERVER_KEY=your-fcm-server-key
FCM_SENDER_ID=your-fcm-sender-id

# 📍 Location Services
LOCATION_ACCURACY=high
LOCATION_UPDATE_INTERVAL=5000
LOCATION_MIN_DISTANCE=10.0

# 🐛 Debug/Development
DEBUG_MODE=true
LOG_LEVEL=debug
ENABLE_MOCK_SERVICES=false
```

### Archivo: `.env.local` (No incluir en Git)

```env
# Configuración Local - NO SUBIR A GIT
WEBSOCKET_HOST=localhost
WEBSOCKET_PORT=8080
API_BASE_URL=http://10.0.2.15:3000/api
DATABASE_URL=postgresql://dev:dev@localhost:5432/movi_rutas_dev
```

---

## 🔌 Configuración de WebSocket

### 1. Servidor WebSocket (Node.js)

Crear `websocket_server.js`:

```javascript
const WebSocket = require('ws');
const http = require('http');
const fs = require('fs');

// Configuración
const PORT = process.env.WEBSOCKET_PORT || 8080;
const HOST = process.env.WEBSOCKET_HOST || 'localhost';

// Almacenamiento de conexiones activas
const activeConnections = new Map();

// Crear servidor WebSocket
const wss = new WebSocket.Server({ port: PORT });

console.log(`🚀 Servidor WebSocket iniciado en ${HOST}:${PORT}`);

wss.on('connection', (ws, request) => {
  const clientId = generateClientId();
  const clientInfo = {
    id: clientId,
    ip: request.socket.remoteAddress,
    connectedAt: new Date().toISOString(),
    userAgent: request.headers['user-agent']
  };

  activeConnections.set(clientId, {
    ws: ws,
    info: clientInfo,
    lastLocation: null,
    routeId: null
  });

  console.log(`📱 Cliente conectado: ${clientId} desde ${clientInfo.ip}`);

  // Enviar confirmación de conexión
  ws.send(JSON.stringify({
    type: 'connection',
    action: 'confirmed',
    clientId: clientId,
    timestamp: new Date().toISOString()
  }));

  // Manejar mensajes del cliente
  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      handleClientMessage(clientId, data, activeConnections);
    } catch (error) {
      console.error(`❌ Error procesando mensaje de ${clientId}:`, error);
      ws.send(JSON.stringify({
        type: 'error',
        message: 'Mensaje inválido',
        timestamp: new Date().toISOString()
      }));
    }
  });

  // Manejar desconexión
  ws.on('close', () => {
    const connection = activeConnections.get(clientId);
    if (connection) {
      console.log(`📱 Cliente desconectado: ${clientId}`);
      
      // Notificar a otros clientes si es necesario
      broadcastLocationUpdate(clientId, {
        type: 'client_disconnected',
        clientId: clientId,
        timestamp: new Date().toISOString()
      }, activeConnections);
    }
    
    activeConnections.delete(clientId);
  });

  // Manejar errores
  ws.on('error', (error) => {
    console.error(`❌ Error en conexión ${clientId}:`, error);
  });
});

// Funciones auxiliares
function generateClientId() {
  return 'client_' + Math.random().toString(36).substr(2, 9);
}

function handleClientMessage(clientId, data, connections) {
  const connection = connections.get(clientId);
  
  switch (data.type) {
    case 'location_update':
      handleLocationUpdate(clientId, data, connections);
      break;
      
    case 'route_start':
      handleRouteStart(clientId, data, connections);
      break;
      
    case 'route_end':
      handleRouteEnd(clientId, data, connections);
      break;
      
    default:
      console.log(`📨 Mensaje desconocido de ${clientId}:`, data);
  }
}

function handleLocationUpdate(clientId, data, connections) {
  const connection = connections.get(clientId);
  connection.lastLocation = {
    latitude: data.latitude,
    longitude: data.longitude,
    timestamp: data.timestamp,
    speed: data.speed,
    accuracy: data.accuracy
  };

  // Guardar en base de datos (aquí iría tu lógica)
  saveLocationToDatabase(clientId, data);

  // Broadcast a otros clientes si es necesario
  broadcastLocationUpdate(clientId, {
    type: 'location_broadcast',
    clientId: clientId,
    location: connection.lastLocation,
    timestamp: new Date().toISOString()
  }, connections);
}

function handleRouteStart(clientId, data, connections) {
  const connection = connections.get(clientId);
  connection.routeId = data.routeId;
  
  console.log(`🛣 Ruta iniciada: ${data.routeId} por ${clientId}`);
  
  // Broadcast a todos los clientes
  broadcastToAll({
    type: 'route_started',
    routeId: data.routeId,
    clientId: clientId,
    timestamp: new Date().toISOString()
  }, connections);
}

function handleRouteEnd(clientId, data, connections) {
  const connection = connections.get(clientId);
  connection.routeId = null;
  
  console.log(`🏁 Ruta finalizada: ${data.routeId} por ${clientId}`);
  
  // Broadcast a todos los clientes
  broadcastToAll({
    type: 'route_ended',
    routeId: data.routeId,
    clientId: clientId,
    timestamp: new Date().toISOString()
  }, connections);
}

function broadcastLocationUpdate(senderId, message, connections) {
  connections.forEach((connection, id) => {
    if (id !== senderId && connection.ws.readyState === WebSocket.OPEN) {
      connection.ws.send(JSON.stringify(message));
    }
  });
}

function broadcastToAll(message, connections) {
  connections.forEach((connection) => {
    if (connection.ws.readyState === WebSocket.OPEN) {
      connection.ws.send(JSON.stringify(message));
    }
  });
}

function saveLocationToDatabase(clientId, locationData) {
  // Aquí iría tu lógica de base de datos
  console.log(`💾 Guardando ubicación: ${clientId}`, locationData);
  
  // Ejemplo con PostgreSQL:
  /*
  const query = `
    INSERT INTO location_points (client_id, route_id, latitude, longitude, timestamp, speed, accuracy)
    VALUES ($1, $2, $3, $4, $5, $6)
  `;
  
  pool.query(query, [clientId, locationData.routeId, locationData.latitude, locationData.longitude, locationData.timestamp, locationData.speed, locationData.accuracy])
    .then(() => {
      console.log(`✅ Ubicación guardada para ${clientId}`);
    })
    .catch((error) => {
      console.error(`❌ Error guardando ubicación:`, error);
    });
  */
}

// Manejo de cierre elegante
process.on('SIGINT', () => {
  console.log('🛑 Cerrando servidor WebSocket...');
  wss.close(() => {
    process.exit(0);
  });
});
```

### 2. Paquete WebSocket

```json
{
  "name": "movi_rutas_websocket",
  "version": "1.0.0",
  "description": "Servidor WebSocket para Movi Rutas",
  "main": "websocket_server.js",
  "scripts": {
    "start": "node websocket_server.js",
    "dev": "nodemon websocket_server.js",
    "test": "jest"
  },
  "dependencies": {
    "ws": "^8.14.2",
    "http": "^1.0.0",
    "pg": "^8.11.3",
    "dotenv": "^16.3.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.2",
    "jest": "^29.7.0"
  }
}
```

---

## 🗄️ Configuración de Backend

### 1. API REST (Node.js + Express)

Crear `api_server.js`:

```javascript
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
require('dotenv').config();

const app = express();
const PORT = process.env.API_PORT || 3000;

// Configuración de base de datos
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production'
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Middleware de logging
app.use((req, res, next) => {
  console.log(`${req.method} ${req.path} - ${new Date().toISOString()}`);
  next();
});

// Rutas de autenticación
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    const result = await pool.query(
      'SELECT id, email, password, driver_id FROM drivers WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Credenciales inválidas' });
    }

    const driver = result.rows[0];
    const validPassword = await bcrypt.compare(password, driver.password);
    
    if (!validPassword) {
      return res.status(401).json({ error: 'Credenciales inválidas' });
    }

    const token = jwt.sign(
      { driverId: driver.driver_id, email: driver.email },
      process.env.JWT_SECRET,
      { expiresIn: `${process.env.JWT_EXPIRY_HOURS}h` }
    );

    res.json({
      token,
      driver: {
        id: driver.id,
        email: driver.email,
        driverId: driver.driver_id
      }
    });
  } catch (error) {
    console.error('Error en login:', error);
    res.status(500).json({ error: 'Error del servidor' });
  }
});

// Rutas de rutas
app.get('/api/routes', authenticateToken, async (req, res) => {
  try {
    const driverId = req.driver.driverId;
    const { page = 1, limit = 20 } = req.query;
    
    const offset = (page - 1) * limit;
    
    const result = await pool.query(`
      SELECT id, driver_id, start_time, end_time, status, total_distance, duration, created_at
      FROM routes 
      WHERE driver_id = $1 
      ORDER BY created_at DESC 
      LIMIT $2 OFFSET $3
    `, [driverId, limit, offset]);

    const totalResult = await pool.query(
      'SELECT COUNT(*) FROM routes WHERE driver_id = $1',
      [driverId]
    );

    res.json({
      routes: result.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: parseInt(totalResult.rows[0].count),
        totalPages: Math.ceil(totalResult.rows[0].count / limit)
      }
    });
  } catch (error) {
    console.error('Error obteniendo rutas:', error);
    res.status(500).json({ error: 'Error del servidor' });
  }
});

app.post('/api/routes', authenticateToken, async (req, res) => {
  try {
    const driverId = req.driver.driverId;
    const { startTime } = req.body;
    
    const result = await pool.query(`
      INSERT INTO routes (driver_id, start_time, status, created_at)
      VALUES ($1, $2, 'in_progress', NOW())
      RETURNING id
    `, [driverId, startTime]);

    res.status(201).json({
      route: result.rows[0],
      message: 'Ruta iniciada exitosamente'
    });
  } catch (error) {
    console.error('Error creando ruta:', error);
    res.status(500).json({ error: 'Error del servidor' });
  }
});

// Rutas de puntos de ubicación
app.post('/api/routes/:routeId/points', authenticateToken, async (req, res) => {
  try {
    const { routeId } = req.params;
    const { latitude, longitude, timestamp, speed, accuracy } = req.body;
    
    const result = await pool.query(`
      INSERT INTO location_points (route_id, latitude, longitude, timestamp, speed, accuracy)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING id
    `, [routeId, latitude, longitude, timestamp, speed, accuracy]);

    res.status(201).json({
      point: result.rows[0],
      message: 'Punto de ubicación guardado'
    });
  } catch (error) {
    console.error('Error guardando punto:', error);
    res.status(500).json({ error: 'Error del servidor' });
  }
});

// Middleware de autenticación
function authenticateToken(req, res, next) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  
  if (!token) {
    return res.status(401).json({ error: 'Token requerido' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.driver = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Token inválido' });
  }
}

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`🚀 Servidor API iniciado en puerto ${PORT}`);
});
```

### 2. Esquema de Base de Datos (PostgreSQL)

```sql
-- Crear base de datos
CREATE DATABASE movi_rutas;

-- Usar la base de datos
\c movi_rutas;

-- Tabla de conductores
CREATE TABLE drivers (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    driver_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100),
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de rutas
CREATE TABLE routes (
    id SERIAL PRIMARY KEY,
    driver_id VARCHAR(50) NOT NULL REFERENCES drivers(driver_id),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    status VARCHAR(20) NOT NULL CHECK (status IN ('initial', 'in_progress', 'paused', 'completed', 'cancelled')),
    total_distance DECIMAL(10,2) DEFAULT 0,
    duration INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de puntos de ubicación
CREATE TABLE location_points (
    id SERIAL PRIMARY KEY,
    route_id INTEGER NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    speed DECIMAL(5,2),
    accuracy DECIMAL(8,2),
    altitude DECIMAL(8,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para mejor rendimiento
CREATE INDEX idx_routes_driver_id ON routes(driver_id);
CREATE INDEX idx_routes_created_at ON routes(created_at DESC);
CREATE INDEX idx_location_points_route_id ON location_points(route_id);
CREATE INDEX idx_location_points_timestamp ON location_points(timestamp DESC);

-- Insertar conductor de ejemplo
INSERT INTO drivers (email, password, driver_id, name) 
VALUES ('conductor@movirutas.com', '$2b$12$Example$Password', 'DRV001', 'Conductor Ejemplo');
```

---

## 🚀 Despliegue

### 1. Entorno de Desarrollo

```bash
# Variables de entorno
export FLUTTER_ENV=development
export API_BASE_URL=http://localhost:3000/api
export WEBSOCKET_URL=ws://localhost:8080

# Iniciar servidor WebSocket
cd websocket_server
npm install
npm run dev

# Iniciar servidor API (en otra terminal)
cd api_server
npm install
npm run dev

# Ejecutar aplicación Flutter
fvm flutter run
```

### 2. Entorno de Producción

#### Configuración de Servidor

```bash
# Usar PM2 para gestión de procesos
npm install -g pm2

# Archivo de configuración PM2 (ecosystem.config.js)
module.exports = {
  apps: [
    {
      name: 'movi-rutas-websocket',
      script: 'websocket_server.js',
      instances: 2,
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'production',
        PORT: 8080
      }
    },
    {
      name: 'movi-rutas-api',
      script: 'api_server.js',
      instances: 2,
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      }
    }
  ]
};
```

#### Despliegue con Docker

```dockerfile
# Dockerfile para WebSocket
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 8080
CMD ["npm", "start"]

# Dockerfile para API
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]

# docker-compose.yml
version: '3.8'
services:
  websocket:
    build: ./websocket_server
    ports:
      - "8080:8080"
    environment:
      - NODE_ENV=production
      - WEBSOCKET_PORT=8080
    restart: unless-stopped

  api:
    build: ./api_server
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - API_PORT=3000
      - DATABASE_URL=postgresql://user:password@postgres:5432/movi_rutas
    depends_on:
      - postgres
    restart: unless-stopped

  postgres:
    image: postgres:15
    environment:
      - POSTGRES_DB=movi_rutas
      - POSTGRES_USER=movi_rutas
      - POSTGRES_PASSWORD=secure_password
      - POSTGRES_DB=movi_rutas
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped
```

#### Build y Deploy de APK

```bash
# Build para producción
fvm flutter build apk --release --obfuscate --shrink

# Build para Android App Bundle (recomendado para Play Store)
fvm flutter build appbundle --release --obfuscate --shrink

# Verificar build
ls -la build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔧 Solución de Problemas Comunes

### Problemas de Build

```bash
# Limpiar completamente
fvm flutter clean
cd android && ./gradlew clean
cd .. && fvm flutter pub get

# Problemas de NDK
rm -rf $ANDROID_HOME/ndk/27.0.12077973
fvm flutter clean
fvm flutter pub get

# Problemas de permisos Android
chmod +x android/gradlew
```

### Problemas de Conexión

```bash
# Verificar conectividad
curl -I http://localhost:3000/api/health
wscat -c ws://localhost:8080

# Firewall (ufw)
sudo ufw allow 3000
sudo ufw allow 8080
sudo ufw reload
```

### Debugging

```bash
# Logs de Flutter
fvm flutter logs

# Logs de Android
adb logcat | grep movi_rutas

# Verificar variables de entorno
printenv | grep -E "(API|WEBSOCKET|DATABASE)"
```

---

## 📊 Monitoreo y Logs

### Configuración de Logs

```javascript
// En producción, usar Winston para logging
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' }),
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

// Uso
logger.info('Servidor iniciado');
logger.error('Error procesando solicitud', error);
```

### Métricas y Monitoreo

```bash
# Monitoreo con PM2
pm2 monit

# Estadísticas de conexión
netstat -an | grep :8080
netstat -an | grep :3000

# Uso de recursos
htop
df -h
free -h
```

---

## 📱 Checklist de Producción

### Antes del Despliegue

- [ ] Configurar variables de entorno
- [ ] Probar API localmente
- [ ] Probar WebSocket localmente
- [ ] Ejecutar tests automatizados
- [ ] Verificar build de APK
- [ ] Configurar firewall
- [ ] Preparar base de datos

### Después del Despliegue

- [ ] Verificar servicios corriendo
- [ ] Probar endpoints de API
- [ ] Probar conexión WebSocket
- [ ] Monitorear logs de errores
- [ ] Verificar uso de recursos
- [ ] Testear aplicación móvil

---

## 📞 Soporte

### Contacto de Desarrollo
- **Email**: desarrollo@movirutas.com
- **Slack**: #movi-rutas-dev
- **Documentación**: https://docs.movi-rutas.com

### Recursos Adicionales
- **Flutter Docs**: https://docs.flutter.dev
- **Android Deployment**: https://developer.android.com/studio/publish
- **PostgreSQL Docs**: https://www.postgresql.org/docs/

---

## 🔄 Actualizaciones

Esta guía se actualiza regularmente. Revisar el repositorio para la última versión:

```bash
# Actualizar documentación
git pull origin main
```

---

**Nota**: Esta guía cubre la configuración completa para desarrollo, pruebas y producción de Movi Rutas. Ajustar los valores según tu infraestructura específica.