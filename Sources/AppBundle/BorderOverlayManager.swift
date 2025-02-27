import AppKit
import Foundation
import Common

class BorderOverlayManager {
    static let shared = BorderOverlayManager()

    private init() {}

    func setup() {
        // Implementation for setup
    }

    func showEntireScreenBorder() {
        // Implementation for showing entire screen border
    }

    func hideEntireScreenBorder() {
        // Implementation for hiding entire screen border
    }

    func hideActiveSplitBorder() {
        // Implementation for hiding active split border
    }

    func hideInactiveSplitBorders() {
        // Implementation for hiding inactive split borders
    }

    func showActiveSplitBorder(frame: NSRect) {
        // Implementation for showing active split border
    }

    func showInactiveSplitBorders(frames: [NSRect]) {
        // Implementation for showing inactive split borders
    }
}

/// A manager class that integrates border visualization with AeroSpace's window management system
class BorderIntegrationManager {
    static let shared = BorderIntegrationManager()
    
    private var isEnabled = true
    private var fullscreenBorderVisible = false
    
    private init() {}
    
    /// Setup the border manager and integrate with AeroSpace
    func setup() {
        // Setup the BorderOverlayManager
        BorderOverlayManager.shared.setup()
        
        // Register for focus change notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onFocusChanged),
            name: NSNotification.Name("AeroSpaceFocusChanged"),
            object: nil
        )
        
        // Register for window split notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onWindowSplit),
            name: NSNotification.Name("AeroSpaceWindowSplit"),
            object: nil
        )
        
        // Register for application startup completion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onAppStartupComplete),
            name: NSNotification.Name("AeroSpaceStartupComplete"),
            object: nil
        )
    }
    
    /// Called when the app startup is complete
    @objc private func onAppStartupComplete() {
        showFullscreenBorder()
    }
    
    /// Called when focus changes between windows
    @objc func onFocusChanged(_ notification: Notification) {
        guard isEnabled else { return }
        
        // If we have active and inactive windows in a split, update their borders
        if let userInfo = notification.userInfo,
           let focusedWindowFrame = userInfo["focusedWindowFrame"] as? NSRect,
           let inactiveWindowFrames = userInfo["inactiveWindowFrames"] as? [NSRect] {
            updateBordersForSplit(focusedFrame: focusedWindowFrame, inactiveFrames: inactiveWindowFrames)
        }
    }
    
    /// Called when a window is split
    @objc func onWindowSplit(_ notification: Notification) {
        guard isEnabled else { return }
        
        if fullscreenBorderVisible {
            hideFullscreenBorder()
        }
        
        // If we have information about the split windows, show their borders
        if let userInfo = notification.userInfo,
           let activeFrame = userInfo["activeFrame"] as? NSRect,
           let inactiveFrames = userInfo["inactiveFrames"] as? [NSRect] {
            updateBordersForSplit(focusedFrame: activeFrame, inactiveFrames: inactiveFrames)
        }
    }
    
    /// Show fullscreen border around the entire screen
    func showFullscreenBorder() {
        guard isEnabled else { return }
        
        BorderOverlayManager.shared.showEntireScreenBorder()
        fullscreenBorderVisible = true
    }
    
    /// Hide fullscreen border
    func hideFullscreenBorder() {
        BorderOverlayManager.shared.hideEntireScreenBorder()
        fullscreenBorderVisible = false
    }
    
    /// Update borders for split windows
    private func updateBordersForSplit(focusedFrame: NSRect, inactiveFrames: [NSRect]) {
        // Hide any existing borders first
        BorderOverlayManager.shared.hideActiveSplitBorder()
        BorderOverlayManager.shared.hideInactiveSplitBorders()
        
        // Show new borders
        BorderOverlayManager.shared.showActiveSplitBorder(frame: focusedFrame)
        if !inactiveFrames.isEmpty {
            BorderOverlayManager.shared.showInactiveSplitBorders(frames: inactiveFrames)
        }
    }
    
    /// Enable or disable border visualization
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        
        if !isEnabled {
            // Hide all borders when disabled
            BorderOverlayManager.shared.hideEntireScreenBorder()
            BorderOverlayManager.shared.hideActiveSplitBorder()
            BorderOverlayManager.shared.hideInactiveSplitBorders()
        }
    }
    
    /// Helper method to get frame for a window
    func getFrameForWindow(_ window: Window) -> NSRect? {
        guard let topLeft = window.getTopLeftCorner(),
              let size = window.getSize() else {
            return nil
        }
        
        return NSRect(
            x: topLeft.x,
            y: topLeft.y,
            width: size.width,
            height: size.height
        )
    }
}