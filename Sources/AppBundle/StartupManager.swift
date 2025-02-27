import AppKit
import Foundation

/// Handles initialization of various subsystems during application startup
class StartupManager {
    static let shared = StartupManager()

    private init() {
        // No need for delayed initialization since we're not using notifications
    }
}
