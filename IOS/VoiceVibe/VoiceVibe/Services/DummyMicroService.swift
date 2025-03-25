import Foundation

/// A dummy implementation of the MicroService protocol for testing purposes.
/// This simulates a basic micro-service that can be created, started, and stopped.
class DummyMicroService: MicroService {
    
    // MARK: - Properties
    
    let id: String
    let name: String
    let description: String
    
    private var _status: ServiceStatus = .created
    var status: ServiceStatus {
        return _status
    }
    
    private var config: String
    private var configDict: [String: Any]
    
    // MARK: - Initialization
    
    init(id: String, config: String) {
        self.id = id
        self.config = config
        
        // Parse config JSON
        if let data = config.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            self.configDict = dict
            self.name = dict["name"] as? String ?? "Unnamed Service"
            self.description = dict["description"] as? String ?? "A dummy micro-service for testing"
        } else {
            self.configDict = [:]
            self.name = "Unnamed Service"
            self.description = "A dummy micro-service for testing"
        }
    }
    
    // MARK: - MicroService Protocol Methods
    
    /// Start the dummy service with a simulated delay
    func start() async -> Bool {
        do {
            _status = .starting
            
            // Simulate service startup delay
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            _status = .running
            return true
        } catch {
            _status = .error
            return false
        }
    }
    
    /// Stop the dummy service with a simulated delay
    func stop() async -> Bool {
        do {
            _status = .stopping
            
            // Simulate service shutdown delay
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            _status = .stopped
            return true
        } catch {
            _status = .error
            return false
        }
    }
    
    /// Execute a command on the dummy service
    func executeCommand(_ command: String, params: [String: Any]?) async -> CommandResult {
        switch command.lowercased() {
        case "echo":
            let message = params?["message"] as? String ?? "No message provided"
            return CommandResult(success: true, message: "Echo service received: \(message)", data: message)
            
        case "status":
            return CommandResult(success: true, message: "Service status: \(_status)", data: _status.rawValue)
            
        case "delay":
            do {
                let delayTime = params?["time"] as? UInt64 ?? 1_000_000_000
                try await Task.sleep(nanoseconds: delayTime)
                return CommandResult(success: true, message: "Delayed for \(delayTime/1_000_000) ms", data: delayTime)
            } catch {
                return CommandResult(success: false, message: "Delay operation was cancelled", data: nil)
            }
            
        case "refresh":
            // Simulate a refresh operation
            return CommandResult(success: true, message: "Service refreshed", data: nil)
            
        default:
            return CommandResult(success: false, message: "Unknown command: \(command)", data: nil)
        }
    }
    
    /// Get the configuration of the dummy service
    func getConfiguration() -> String {
        return config
    }
    
    /// Update the configuration of the dummy service
    func updateConfiguration(_ config: String) -> Bool {
        // Only allow configuration updates when the service is not running
        guard _status != .running && _status != .starting else {
            return false
        }
        
        do {
            guard let configData = config.data(using: .utf8),
                  let newConfigDict = try JSONSerialization.jsonObject(with: configData) as? [String: Any] else {
                return false
            }
            
            self.config = config
            
            // Merge the new config with the existing one
            for (key, value) in newConfigDict {
                configDict[key] = value
            }
            
            return true
        } catch {
            return false
        }
    }
} 