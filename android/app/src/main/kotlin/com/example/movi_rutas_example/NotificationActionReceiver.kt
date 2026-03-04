package com.example.movi_rutas_example

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class NotificationActionReceiver : BroadcastReceiver() {
    
    override fun onReceive(context: Context?, intent: Intent?) {
        when (intent?.action) {
            "com.example.movi_rutas_example.STOP_TRACKING" -> {
                // Detener el servicio de foreground
                val serviceIntent = Intent(context, LocationForegroundService::class.java)
                context?.stopService(serviceIntent)
            }
        }
    }
}