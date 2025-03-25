import Foundation

/// Protocol defining the interface for micro-services created through voice commands
protocol MicroService {
    /// Unique identifier for the service
    var id: String { get }
    
    /// Human-readable name of the service
    var name: String { get }
    
    /// Description of what the service does
    var description: String { get }
    
    /// Current status of the service
    var status: ServiceStatus { get }
    
    /// Start the micro-service
    /// - Returns: A Boolean indicating success or failure
    func start() async -> Bool
    
    /// Stop the micro-service
    /// - Returns: A Boolean indicating success or failure
    func stop() async -> Bool
    
    /// Execute a specific command on the service
    /// - Parameters:
    ///   - command: The command to execute
    ///   - params: Optional parameters for the command
    /// - Returns: Result of the command execution
    func executeCommand(_ command: String, params: [String: Any]?) async -> CommandResult
    
    /// Get the current configuration of the service
    /// - Returns: Configuration as a JSON string
    func getConfiguration() -> String
    
    /// Update the configuration of the service
    /// - Parameter config: New configuration as a JSON string
    /// - Returns: A Boolean indicating success or failure
    func updateConfiguration(_ config: String) -> Bool
}

/// Represents the current status of a micro-service
enum ServiceStatus: String {
    case created = "CREATED"    // Service has been created but not started
    case starting = "STARTING"  // Service is in the process of starting
    case running = "RUNNING"    // Service is running normally
    case paused = "PAUSED"      // Service is temporarily paused
    case stopping = "STOPPING"  // Service is in the process of stopping
    case stopped = "STOPPED"    // Service has been stopped
    case error = "ERROR"        // Service encountered an error
}

/// Result of a command execution
struct CommandResult {
    let success: Bool
    let message: String
    let data: Any?
    
    init(success: Bool, message: String, data: Any? = nil) {
        self.success = success
        self.message = message
        self.data = data
    }
}

// Extension to add notification names
extension Notification.Name {
    static let servicesStatusUpdated = Notification.Name("servicesStatusUpdated")
    static let serviceCreated = Notification.Name("serviceCreated")
    static let serviceStarted = Notification.Name("serviceStarted")
    static let serviceStopped = Notification.Name("serviceStopped")
} 