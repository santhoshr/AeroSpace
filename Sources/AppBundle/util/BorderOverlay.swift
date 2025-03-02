import AppKit
import Common

// A singleton class to manage border overlays
class BorderManager {
    static let shared = BorderManager()
    
    private var borderWindows: [NSWindow] = []
    
    private init() {}
    
    func clearAllBorders() {
        for window in borderWindows {
            window.orderOut(nil)
        }
        borderWindows.removeAll()
    }
    
    func createBorderForRect(_ rect: Rect, color: NSColor = .orange, thickness: CGFloat = 5.0) {
        // Create four windows for each side of the rectangle
        createBorderSide(rect, .top, color, thickness)
        createBorderSide(rect, .right, color, thickness)
        createBorderSide(rect, .bottom, color, thickness)
        createBorderSide(rect, .left, color, thickness)
    }
    
    private enum BorderSide {
        case top, right, bottom, left
    }
    
    private func createBorderSide(_ rect: Rect, _ side: BorderSide, _ color: NSColor, _ thickness: CGFloat) {
        var borderRect = NSRect.zero
        
        switch side {
        case .top:
            borderRect = NSRect(x: rect.topLeftX, y: rect.topLeftY - thickness, width: rect.width, height: thickness)
        case .right:
            borderRect = NSRect(x: rect.topLeftX + rect.width, y: rect.topLeftY - rect.height, width: thickness, height: rect.height)
        case .bottom:
            borderRect = NSRect(x: rect.topLeftX, y: rect.topLeftY - rect.height, width: rect.width, height: thickness)
        case .left:
            borderRect = NSRect(x: rect.topLeftX - thickness, y: rect.topLeftY - rect.height, width: thickness, height: rect.height)
        }
        
        let window = NSWindow(
            contentRect: borderRect,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        window.backgroundColor = color
        window.isOpaque = false
        window.hasShadow = false
        window.level = .floating
        window.ignoresMouseEvents = true
        
        // Make the window visible
        window.orderFront(nil)
        
        // Store the window
        borderWindows.append(window)
    }
}

// Helper function to create a border for a rectangle
func createBorder(for rect: Rect, color: NSColor = .orange, thickness: CGFloat = 5.0) {
    BorderManager.shared.createBorderForRect(rect, color: color, thickness: thickness)
}

// Helper function to clear all borders
func clearAllBorders() {
    BorderManager.shared.clearAllBorders()
} 