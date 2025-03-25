package com.voicevibe.services

import kotlinx.coroutines.delay
import org.json.JSONObject

/**
 * A dummy implementation of the MicroService interface for testing purposes.
 * This simulates a basic micro-service that can be created, started, and stopped.
 */
class DummyMicroService(
    override val id: String,
    private var config: String
) : MicroService {
    
    private var _status: ServiceStatus = ServiceStatus.CREATED
    private val configObject: JSONObject = JSONObject(config)
    
    override val name: String = configObject.optString("name", "Unnamed Service")
    override val description: String = configObject.optString("description", "A dummy micro-service for testing")
    
    override val status: ServiceStatus
        get() = _status
    
    /**
     * Start the dummy service with a simulated delay
     */
    override suspend fun start(): Boolean {
        return try {
            _status = ServiceStatus.STARTING
            // Simulate service startup delay
            delay(1000)
            _status = ServiceStatus.RUNNING
            true
        } catch (e: Exception) {
            _status = ServiceStatus.ERROR
            false
        }
    }
    
    /**
     * Stop the dummy service with a simulated delay
     */
    override suspend fun stop(): Boolean {
        return try {
            _status = ServiceStatus.STOPPING
            // Simulate service shutdown delay
            delay(500)
            _status = ServiceStatus.STOPPED
            true
        } catch (e: Exception) {
            _status = ServiceStatus.ERROR
            false
        }
    }
    
    /**
     * Execute a command on the dummy service
     */
    override suspend fun executeCommand(command: String, params: Map<String, Any>?): CommandResult {
        return when (command.lowercase()) {
            "echo" -> {
                val message = params?.get("message") as? String ?: "No message provided"
                CommandResult(true, "Echo service received: $message", message)
            }
            "status" -> {
                CommandResult(true, "Service status: $_status", _status.name)
            }
            "delay" -> {
                val delayTime = params?.get("time") as? Long ?: 1000L
                delay(delayTime)
                CommandResult(true, "Delayed for $delayTime ms", delayTime)
            }
            else -> {
                CommandResult(false, "Unknown command: $command", null)
            }
        }
    }
    
    /**
     * Get the configuration of the dummy service
     */
    override fun getConfiguration(): String {
        return config
    }
    
    /**
     * Update the configuration of the dummy service
     */
    override fun updateConfiguration(config: String): Boolean {
        return try {
            val newConfig = JSONObject(config)
            
            // Only allow configuration updates when the service is not running
            if (_status != ServiceStatus.RUNNING && _status != ServiceStatus.STARTING) {
                this.config = config
                
                // Update name and description if provided
                newConfig.optString("name")?.let { if (it.isNotEmpty()) this.configObject.put("name", it) }
                newConfig.optString("description")?.let { if (it.isNotEmpty()) this.configObject.put("description", it) }
                
                true
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }
} 