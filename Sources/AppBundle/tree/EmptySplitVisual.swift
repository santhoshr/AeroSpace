import AppKit
import Common

/// A class that handles the visual representation of an empty split
class EmptySplitVisual {
    /// The empty split this visual represents
    private let emptySplit: EmptySplit
    
    /// The window used to render the border
    private var borderWindow: NSWindow?
    
    /// Border color for focused empty split
    private let focusedBorderColor = NSColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 0.8)
    
    /// Border width
    private let borderWidth: CGFloat = 2.0
    
    /// Initialize with an empty split
    init(emptySplit: EmptySplit) {
        self.emptySplit = emptySplit
    }
    
    /// Show the border around the empty split
    func showBorder() {
        // Remove existing border if any
        hideBorder()
        
        // Get the frame for rendering
        guard let frame = emptySplit.getFrameForRendering() else { return }
        
        // Convert to CGRect
        let rect = CGRect(
            x: frame.topLeftX,
            y: frame.topLeftY,
            width: frame.width,
            height: frame.height
        )
        
        // Create a borderless window to show the border
        let borderWindow = NSWindow(
            contentRect: rect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure the window
        borderWindow.level = NSWindow.Level.floating
        borderWindow.backgroundColor = NSColor.clear
        borderWindow.isOpaque = false
        borderWindow.hasShadow = false
        borderWindow.ignoresMouseEvents = true
        
        // Create a view for the border
        let borderView = BorderView(frame: NSRect(x: 0, y: 0, width: rect.width, height: rect.height))
        borderView.borderColor = focusedBorderColor
        borderView.borderWidth = borderWidth
        
        // Set the view
        borderWindow.contentView = borderView
        
        // Store the window and show it
        self.borderWindow = borderWindow
        borderWindow.orderFront(nil as Any?)
    }
    
    /// Hide the border
    func hideBorder() {
        borderWindow?.close()
        borderWindow = nil
    }
}

/// A view that draws a border
class BorderView: NSView {
    /// The color of the border
    var borderColor: NSColor = .blue
    
    /// The width of the border
    var borderWidth: CGFloat = 2.0
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Clear the background
        NSColor.clear.set()
        dirtyRect.fill()
        
        // Draw the border
        borderColor.set()
        
        let borderPath = NSBezierPath(rect: NSRect(
            x: borderWidth / 2,
            y: borderWidth / 2,
            width: bounds.width - borderWidth,
            height: bounds.height - borderWidth
        ))
        borderPath.lineWidth = borderWidth
        borderPath.stroke()
    }
}

/// Global storage for empty split visuals
var emptySplitVisuals: [UUID: EmptySplitVisual] = [:]
