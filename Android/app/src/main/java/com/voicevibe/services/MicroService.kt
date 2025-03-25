package com.voicevibe.services

/**
 * Interface for all micro-services created through voice commands.
 * All service implementations must adhere to this interface.
 */
interface MicroService {
    /**
     * Unique identifier for the service
     */
    val id: String
    
    /**
     * Human-readable name of the service
     */
    val name: String
    
    /**
     * Description of what the service does
     */
    val description: String
    
    /**
     * Current status of the service
     */
    val status: ServiceStatus
    
    /**
     * Start the micro-service
     * @return true if successfully started, false otherwise
     */
    suspend fun start(): Boolean
    
    /**
     * Stop the micro-service
     * @return true if successfully stopped, false otherwise
     */
    suspend fun stop(): Boolean
    
    /**
     * Execute a specific command on the service
     * @param command The command to execute
     * @param params Optional parameters for the command
     * @return Result of the command execution
     */
    suspend fun executeCommand(command: String, params: Map<String, Any>? = null): CommandResult
    
    /**
     * Get the current configuration of the service
     * @return Configuration as a JSON string
     */
    fun getConfiguration(): String
    
    /**
     * Update the configuration of the service
     * @param config New configuration as a JSON string
     * @return true if configuration was successfully updated, false otherwise
     */
    fun updateConfiguration(config: String): Boolean
}

/**
 * Represents the current status of a micro-service
 */
enum class ServiceStatus {
    CREATED,    // Service has been created but not started
    STARTING,   // Service is in the process of starting
    RUNNING,    // Service is running normally
    PAUSED,     // Service is temporarily paused
    STOPPING,   // Service is in the process of stopping
    STOPPED,    // Service has been stopped
    ERROR       // Service encountered an error
}

/**
 * Result of a command execution
 */
data class CommandResult(
    val success: Boolean,
    val message: String,
    val data: Any? = null
) 