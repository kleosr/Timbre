import UIKit
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Initialize the window for iOS < 13
        if #available(iOS 13.0, *) {
            // SceneDelegate will handle setup
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)
            let viewController = MainViewController()
            let navigationController = UINavigationController(rootViewController: viewController)
            window?.rootViewController = navigationController
            window?.makeKeyAndVisible()
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // MARK: - Background task handling
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Ensure that services continue to run in the background if needed
        MicroServiceManager.shared.updateBackgroundTasks()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Refresh UI with any updates that happened while in the background
        NotificationCenter.default.post(name: .servicesStatusUpdated, object: nil)
    }
} 