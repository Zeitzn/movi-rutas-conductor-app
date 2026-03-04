package com.example.movi_rutas_example

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class LocationForegroundService : Service(), MethodCallHandler {
    
    companion object {
        private const val NOTIFICATION_CHANNEL_ID = "location_tracking_channel"
        private const val NOTIFICATION_CHANNEL_NAME = "Seguimiento de Ruta"
        private const val NOTIFICATION_ID = 1001
        private const val METHOD_CHANNEL_NAME = "com.example.movi_rutas_example/notifications"
        
        // Actions for notification
        private const val ACTION_STOP_TRACKING = "com.example.movi_rutas_example.STOP_TRACKING"
        private const val ACTION_OPEN_APP = "com.example.movi_rutas_example.OPEN_APP"
    }

    private var notificationManager: NotificationManagerCompat? = null
    private var methodChannel: MethodChannel? = null
    private var currentStatus: String = "IN_PROGRESS"
    private var currentPointsCount: Int = 0

    override fun onCreate() {
        super.onCreate()
        notificationManager = NotificationManagerCompat.from(this)
        createNotificationChannel()
        
        // Setup method channel for Flutter communication
        methodChannel = MethodChannel(FlutterEngine(this).dartExecutor.binaryMessenger, METHOD_CHANNEL_NAME)
        methodChannel?.setMethodCallHandler(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        // Handle notification actions
        when (intent?.action) {
            ACTION_STOP_TRACKING -> {
                stopSelf()
                return START_NOT_STICKY
            }
        }
        
        return START_STICKY // Service will be restarted if killed
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null // We don't provide binding
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                NOTIFICATION_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Seguimiento activo de tu ruta en tiempo real"
                setShowBadge(true)
                enableVibration(true)
                enableLights(true)
                lightColor = android.graphics.Color.BLUE
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        // Intent para abrir la app
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            this, 0, openAppIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Intent para detener el tracking
        val stopTrackingIntent = Intent(ACTION_STOP_TRACKING).apply {
            setPackage(packageName)
        }
        val stopTrackingPendingIntent = PendingIntent.getBroadcast(
            this, 1, stopTrackingIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("🚀 Movi Rutas Activo")
            .setContentText("Seguimiento de ruta en segundo plano")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setContentIntent(openAppPendingIntent)
            .addAction(
                R.mipmap.ic_launcher,
                "Abrir App",
                openAppPendingIntent
            )
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Detener",
                stopTrackingPendingIntent
            )
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText("Movi Rutas está registrando tu ubicación en segundo plano. Toca para abrir la app o desliza para detener el seguimiento.")
            )
            .build()
    }

    fun updateNotification(routeStatus: String, pointsCount: Int = 0) {
        val notification = when (routeStatus) {
            "IN_PROGRESS" -> createInProgressNotification(pointsCount)
            "PAUSED" -> createPausedNotification()
            "COMPLETED" -> createCompletedNotification()
            else -> createNotification()
        }
        
        notificationManager?.notify(NOTIFICATION_ID, notification)
    }

    private fun createInProgressNotification(pointsCount: Int): Notification {
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            this, 0, openAppIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("📍 Ruta en Progreso")
            .setContentText("$pointsCount puntos registrados")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(openAppPendingIntent)
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText("Ruta activa: $pointsCount puntos de ubicación registrados. Seguimiento en tiempo real activo.")
            )
            .build()
    }

    private fun createPausedNotification(): Notification {
        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("⏸️ Ruta Pausada")
            .setContentText("El seguimiento está pausado")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setOngoing(true)
            .setAutoCancel(false)
            .build()
    }

    private fun createCompletedNotification(): Notification {
        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("✅ Ruta Completada")
            .setContentText("El seguimiento ha finalizado")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()
    }

    override fun onDestroy() {
        super.onDestroy()
        // Cancel notification when service is destroyed
        notificationManager?.cancel(NOTIFICATION_ID)
        methodChannel?.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "updateNotification" -> {
                try {
                    val status = call.argument<String>("status") ?: "IN_PROGRESS"
                    val pointsCount = call.argument<Int>("pointsCount") ?: 0
                    currentStatus = status
                    currentPointsCount = pointsCount
                    updateNotificationWithStatus(status, pointsCount)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to update notification", e.message)
                }
            }
            "stopNotification" -> {
                try {
                    notificationManager?.cancel(NOTIFICATION_ID)
                    stopSelf()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to stop notification", e.message)
                }
            }
            "startNotification" -> {
                try {
                    val notification = createNotification()
                    startForeground(NOTIFICATION_ID, notification)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to start notification", e.message)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun updateNotificationWithStatus(status: String, pointsCount: Int) {
        val notification = when (status) {
            "IN_PROGRESS" -> createInProgressNotification(pointsCount)
            "PAUSED" -> createPausedNotification()
            "COMPLETED" -> createCompletedNotification()
            else -> createNotification()
        }
        
        notificationManager?.notify(NOTIFICATION_ID, notification)
    }
}