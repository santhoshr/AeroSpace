import AppKit
import Foundation

/// Handles initialization of various subsystems during application startup
class StartupManager {
    static let shared = StartupManager()
    
    private init() {}
    
    /// Initialize border system for window management visualization
    func initBorderSystem() {
        // Initialize the border integration manager
        BorderIntegrationManager.shared.setup()
        
        // Post notification that app startup is complete
        // This will trigger the fullscreen border to be shown
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(
                name: NSNotification.Name("AeroSpaceStartupComplete"),
                object: nil
            )
        }
    }
}