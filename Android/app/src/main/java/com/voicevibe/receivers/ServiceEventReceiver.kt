package com.voicevibe.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.voicevibe.services.MicroServiceExecutionService

/**
 * BroadcastReceiver for handling service-related events.
 * This includes service creation, starting, stopping, and system events like boot completed.
 */
class ServiceEventReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "ServiceEventReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Received intent: ${intent.action}")
        
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED -> {
                // Start the service on device boot
                startServiceIfNeeded(context)
            }
            
            MicroServiceExecutionService.ACTION_SERVICE_CREATED -> {
                val serviceId = intent.getStringExtra(MicroServiceExecutionService.EXTRA_SERVICE_ID)
                Log.d(TAG, "Service created: $serviceId")
                
                // Here you could notify the UI or start the service automatically
            }
            
            MicroServiceExecutionService.ACTION_SERVICE_STARTED -> {
                val serviceId = intent.getStringExtra(MicroServiceExecutionService.EXTRA_SERVICE_ID)
                Log.d(TAG, "Service started: $serviceId")
                
                // Here you could update the UI to show the service is running
            }
            
            MicroServiceExecutionService.ACTION_SERVICE_STOPPED -> {
                val serviceId = intent.getStringExtra(MicroServiceExecutionService.EXTRA_SERVICE_ID)
                Log.d(TAG, "Service stopped: $serviceId")
                
                // Here you could update the UI to show the service is stopped
            }
        }
    }
    
    /**
     * Starts the MicroServiceExecutionService if needed
     */
    private fun startServiceIfNeeded(context: Context) {
        val intent = Intent(context, MicroServiceExecutionService::class.java)
        
        // Start the service
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }
} 