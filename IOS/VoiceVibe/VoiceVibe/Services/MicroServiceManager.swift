import Foundation
import BackgroundTasks

/// Manager class responsible for creating, tracking, and controlling micro-services
class MicroServiceManager {
    
    // MARK: - Singleton
    
    static let shared = MicroServiceManager()
    
    // MARK: - Properties
    
    private var activeServices = [String: MicroService]()
    private let servicesQueue = DispatchQueue(label: "com.voicevibe.services", attributes: .concurrent)
    
    // Background tasks
    private var backgroundTasks = Set<UIBackgroundTaskIdentifier>()
    
    // MARK: - Initialization
    
    private init() {
        // Register background task identifiers if iOS 13+
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.voicevibe.servicerefresh", using: nil) { task in
                self.handleAppRefresh(task: task as! BGAppRefreshTask)
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Creates a new micro-service from configuration
    /// - Parameters:
    ///   - serviceId: Unique identifier for the service
    ///   - serviceConfig: JSON configuration string
    /// - Returns: Boolean indicating success or failure
    func createService(serviceId: String? = nil, serviceConfig: String) -> Bool {
        let actualServiceId = serviceId ?? generateServiceId()
        
        do {
            guard let configData = serviceConfig.data(using: .utf8),
                  let configDict = try JSONSerialization.jsonObject(with: configData) as? [String: Any] else {
                return false
            }
            
            // Create the appropriate service based on config
            let service: MicroService
            
            if let serviceType = configDict["type"] as? String {
                switch serviceType {
                // In a real app, we would create different service types here
                // For now, we'll just create a dummy service
                default:
                    service = DummyMicroService(id: actualServiceId, config: serviceConfig)
                }
            } else {
                service = DummyMicroService(id: actualServiceId, config: serviceConfig)
            }
            
            // Add to active services
            servicesQueue.async(flags: .barrier) {
                self.activeServices[actualServiceId] = service
            }
            
            // Notify observers
            NotificationCenter.default.post(name: .serviceCreated, object: nil, userInfo: ["serviceId": actualServiceId])
            
            return true
        } catch {
            print("Failed to create service: \(error)")
            return false
        }
    }
    
    /// Starts a micro-service by ID
    /// - Parameter serviceId: The ID of the service to start
    /// - Returns: Boolean indicating success or failure
    func startService(serviceId: String) async -> Bool {
        guard let service = getService(serviceId: serviceId) else {
            return false
        }
        
        let result = await service.start()
        
        if result {
            // Notify observers
            NotificationCenter.default.post(name: .serviceStarted, object: nil, userInfo: ["serviceId": serviceId])
            
            // Register background task if needed
            registerBackgroundTask(for: serviceId)
        }
        
        return result
    }
    
    /// Stops a micro-service by ID
    /// - Parameter serviceId: The ID of the service to stop
    /// - Returns: Boolean indicating success or failure
    func stopService(serviceId: String) async -> Bool {
        guard let service = getService(serviceId: serviceId) else {
            return false
        }
        
        let result = await service.stop()
        
        if result {
            // Notify observers
            NotificationCenter.default.post(name: .serviceStopped, object: nil, userInfo: ["serviceId": serviceId])
            
            // End background task if registered
            endBackgroundTask(for: serviceId)
        }
        
        return result
    }
    
    /// Gets a service by ID
    /// - Parameter serviceId: The ID of the service to get
    /// - Returns: The service if found, nil otherwise
    func getService(serviceId: String) -> MicroService? {
        var service: MicroService?
        
        servicesQueue.sync {
            service = activeServices[serviceId]
        }
        
        return service
    }
    
    /// Gets all active services
    /// - Returns: Array of active services
    func getAllServices() -> [MicroService] {
        var services = [MicroService]()
        
        servicesQueue.sync {
            services = Array(activeServices.values)
        }
        
        return services
    }
    
    /// Updates background tasks for all running services
    func updateBackgroundTasks() {
        // Get currently running services
        let runningServices = getAllServices().filter { $0.status == .running }
        
        // Register background tasks for each running service
        for service in runningServices {
            registerBackgroundTask(for: service.id)
        }
        
        // Schedule background refresh
        scheduleBackgroundRefresh()
    }
    
    // MARK: - Private Methods
    
    /// Generates a unique service ID
    /// - Returns: A unique string ID
    private func generateServiceId() -> String {
        return "service_\(UUID().uuidString)"
    }
    
    /// Registers a background task for a service
    /// - Parameter serviceId: The ID of the service
    private func registerBackgroundTask(for serviceId: String) {
        let taskId = UIApplication.shared.beginBackgroundTask(withName: "Service_\(serviceId)") {
            // Expiration handler
            self.endBackgroundTask(for: serviceId)
        }
        
        if taskId != .invalid {
            servicesQueue.async(flags: .barrier) {
                self.backgroundTasks.insert(taskId)
            }
        }
    }
    
    /// Ends a background task for a service
    /// - Parameter serviceId: The ID of the service
    private func endBackgroundTask(for serviceId: String) {
        servicesQueue.async(flags: .barrier) {
            for taskId in self.backgroundTasks {
                UIApplication.shared.endBackgroundTask(taskId)
            }
            self.backgroundTasks.removeAll()
        }
    }
    
    /// Schedules background refresh for services
    private func scheduleBackgroundRefresh() {
        if #available(iOS 13.0, *) {
            let request = BGAppRefreshTaskRequest(identifier: "com.voicevibe.servicerefresh")
            request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now
            
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                print("Could not schedule app refresh: \(error)")
            }
        }
    }
    
    /// Handles background refresh tasks
    /// - Parameter task: The BGAppRefreshTask
    @available(iOS 13.0, *)
    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule a new refresh task
        scheduleBackgroundRefresh()
        
        // Create a task to refresh services
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        let refreshOperation = BlockOperation {
            // Refresh active services here
            for serviceId in self.activeServices.keys {
                Task {
                    if let service = self.getService(serviceId: serviceId),
                       service.status == .running {
                        _ = await service.executeCommand("refresh", params: nil)
                    }
                }
            }
        }
        
        // Set up task expiration handler
        task.expirationHandler = {
            queue.cancelAllOperations()
        }
        
        // Notify completion when operation is done
        refreshOperation.completionBlock = {
            task.setTaskCompleted(success: !refreshOperation.isCancelled)
        }
        
        queue.addOperation(refreshOperation)
    }
} 