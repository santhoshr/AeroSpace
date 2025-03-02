import AppKit
import Common

/// A class to manage border overlays for windows
class BorderManager {
    /// Shared instance for singleton access
    static let shared = BorderManager()
    
    /// Array to keep track of all active border windows
    private var activeBorders: [NSWindow] = []
    
    /// Private initializer for singleton pattern
    private init() {}
    
    /// Creates a border around the specified rectangle
    /// - Parameters:
    ///   - rect: The rectangle to create a border around
    ///   - color: The color of the border
    ///   - thickness: The thickness of the border
    func createBorder(for rect: Rect, color: NSColor, thickness: CGFloat) {
        // Create a window for the border
        let borderWindow = NSWindow(
            contentRect: NSRect(x: rect.topLeftX, y: rect.topLeftY - rect.height, width: rect.width, height: rect.height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure the window
        borderWindow.backgroundColor = NSColor.clear
        borderWindow.isOpaque = false
        borderWindow.hasShadow = false
        borderWindow.level = NSWindow.Level.floating
        borderWindow.ignoresMouseEvents = true
        
        // Create a view for the border
        let borderView = BorderView(frame: NSRect(x: 0, y: 0, width: rect.width, height: rect.height))
        borderView.borderColor = color
        borderView.borderThickness = thickness
        
        // Set the view as the window's content view
        borderWindow.contentView = borderView
        
        // Show the window
        borderWindow.orderFront(nil as Any?)
        
        // Add to active borders
        activeBorders.append(borderWindow)
    }
    
    /// Removes all active borders
    func removeAllBorders() {
        for window in activeBorders {
            window.orderOut(nil as Any?)
        }
        activeBorders.removeAll()
    }
}

/// A custom view that draws a border
class BorderView: NSView {
    /// The color of the border
    var borderColor: NSColor = .orange
    
    /// The thickness of the border
    var borderThickness: CGFloat = 5.0
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Clear the background
        NSColor.clear.set()
        dirtyRect.fill()
        
        // Set the border color
        borderColor.set()
        
        // Draw the border
        let borderPath = NSBezierPath(rect: bounds)
        borderPath.lineWidth = borderThickness
        borderPath.stroke()
    }
}

// Helper function to create a border for a rectangle
func createBorder(for rect: Rect, color: NSColor = .orange, thickness: CGFloat = 5.0) {
    BorderManager.shared.createBorder(for: rect, color: color, thickness: thickness)
}

// Helper function to clear all borders
func clearAllBorders() {
    BorderManager.shared.removeAllBorders()
} 