package com.timbre.services

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Binder
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.timbre.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import java.util.concurrent.ConcurrentHashMap

/**
 * Service responsible for executing and managing micro-services created by voice commands.
 * Runs in the background to ensure services continue operating even when the app is not in focus.
 */
class MicroServiceExecutionService : Service() {

    private val serviceScope = CoroutineScope(Dispatchers.Default)
    private val activeServices = ConcurrentHashMap<String, MicroService>()
    private val binder = LocalBinder()
    private var serviceJob: Job? = null
    
    // Notification IDs and channels
    private val NOTIFICATION_ID = 1001
    private val CHANNEL_ID = "TimbreServiceChannel"
    
    inner class LocalBinder : Binder() {
        fun getService(): MicroServiceExecutionService = this@MicroServiceExecutionService
    }
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = createForegroundNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        // Process the intent if it contains service information
        intent?.let { processIntent(it) }
        
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder {
        return binder
    }
    
    override fun onDestroy() {
        super.onDestroy()
        serviceJob?.cancel()
        stopAllServices()
    }
    
    /**
     * Processes incoming intents to create, start, or stop micro-services
     */
    private fun processIntent(intent: Intent) {
        when (intent.action) {
            ACTION_CREATE_SERVICE -> {
                val serviceConfig = intent.getStringExtra(EXTRA_SERVICE_CONFIG)
                val serviceId = intent.getStringExtra(EXTRA_SERVICE_ID) ?: generateServiceId()
                
                serviceConfig?.let {
                    createService(serviceId, it)
                }
            }
            ACTION_START_SERVICE -> {
                val serviceId = intent.getStringExtra(EXTRA_SERVICE_ID)
                serviceId?.let { startService(it) }
            }
            ACTION_STOP_SERVICE -> {
                val serviceId = intent.getStringExtra(EXTRA_SERVICE_ID)
                serviceId?.let { stopService(it) }
            }
        }
    }
    
    /**
     * Creates a new micro-service from configuration
     */
    fun createService(serviceId: String, serviceConfig: String): Boolean {
        return try {
            // Here we would parse the configuration and instantiate the appropriate service
            // For now, we'll create a dummy service
            val service = DummyMicroService(serviceId, serviceConfig)
            activeServices[serviceId] = service
            
            // Broadcast that a service was created
            broadcastServiceEvent(ACTION_SERVICE_CREATED, serviceId)
            
            true
        } catch (e: Exception) {
            false
        }
    }
    
    /**
     * Starts a micro-service by ID
     */
    fun startService(serviceId: String): Boolean {
        val service = activeServices[serviceId] ?: return false
        
        serviceScope.launch {
            service.start()
            broadcastServiceEvent(ACTION_SERVICE_STARTED, serviceId)
        }
        
        return true
    }
    
    /**
     * Stops a micro-service by ID
     */
    fun stopService(serviceId: String): Boolean {
        val service = activeServices[serviceId] ?: return false
        
        serviceScope.launch {
            service.stop()
            broadcastServiceEvent(ACTION_SERVICE_STOPPED, serviceId)
        }
        
        return true
    }
    
    /**
     * Stops all running micro-services
     */
    private fun stopAllServices() {
        serviceScope.launch {
            activeServices.forEach { (id, service) ->
                service.stop()
                broadcastServiceEvent(ACTION_SERVICE_STOPPED, id)
            }
            activeServices.clear()
        }
    }
    
    /**
     * Gets a list of all active service IDs
     */
    fun getActiveServiceIds(): List<String> {
        return activeServices.keys().toList()
    }
    
    /**
     * Broadcasts service-related events
     */
    private fun broadcastServiceEvent(action: String, serviceId: String) {
        val intent = Intent(action).apply {
            putExtra(EXTRA_SERVICE_ID, serviceId)
        }
        sendBroadcast(intent)
    }
    
    /**
     * Generates a unique service ID
     */
    private fun generateServiceId(): String {
        return "service_${System.currentTimeMillis()}"
    }
    
    /**
     * Creates the notification channel for Android O and above
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Timbre Service Channel"
            val descriptionText = "Channel for Timbre micro-services"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    /**
     * Creates the foreground notification for the service
     */
    private fun createForegroundNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Timbre")
            .setContentText("Running microservices: ${activeServices.size}")
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
    
    companion object {
        // Intent actions
        const val ACTION_CREATE_SERVICE = "com.timbre.action.CREATE_SERVICE"
        const val ACTION_START_SERVICE = "com.timbre.action.START_SERVICE"
        const val ACTION_STOP_SERVICE = "com.timbre.action.STOP_SERVICE"
        
        // Broadcast actions
        const val ACTION_SERVICE_CREATED = "com.timbre.SERVICE_CREATED"
        const val ACTION_SERVICE_STARTED = "com.timbre.SERVICE_STARTED"
        const val ACTION_SERVICE_STOPPED = "com.timbre.SERVICE_STOPPED"
        
        // Intent extras
        const val EXTRA_SERVICE_ID = "service_id"
        const val EXTRA_SERVICE_CONFIG = "service_config"
    }
} 