package com.movi.rutas.conductor

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class NotificationActionReceiver : BroadcastReceiver() {
    
    override fun onReceive(context: Context?, intent: Intent?) {
        when (intent?.action) {
            "com.movi.rutas.conductor.STOP_TRACKING" -> {
                // Detener el servicio de foreground
                val serviceIntent = Intent(context, LocationForegroundService::class.java)
                context?.stopService(serviceIntent)
            }
        }
    }
}
