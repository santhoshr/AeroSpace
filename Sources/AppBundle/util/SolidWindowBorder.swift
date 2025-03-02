import AppKit
import Common

/// A class to manage solid window borders that can act as real windows in splits
class SolidWindowBorder {
    /// Shared instance for singleton access
    static let shared = SolidWindowBorder()
    
    /// Array to keep track of all active border windows
    private var activeBorders: [NSWindow] = []
    
    /// Private initializer for singleton pattern
    private init() {}
    
    /// Creates a solid window border that can act as a real window
    /// - Parameters:
    ///   - rect: The rectangle for the window
    ///   - color: The color of the window
    ///   - title: The title of the window
    /// - Returns: The created window
    @discardableResult
    func createSolidWindow(for rect: Rect, color: NSColor, title: String = "Empty Split") -> NSWindow {
        // Create a window for the border with standard window style
        let borderWindow = NSWindow(
            contentRect: NSRect(x: rect.topLeftX, y: rect.topLeftY - rect.height, width: rect.width, height: rect.height),
            styleMask: [.titled, .resizable, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        // Configure the window to look like a standard application window
        borderWindow.title = title
        borderWindow.backgroundColor = color.withAlphaComponent(0.3)
        borderWindow.isOpaque = true
        borderWindow.hasShadow = true
        
        // Important: Use normal window level so AeroSpace can manage it
        borderWindow.level = NSWindow.Level.normal
        
        // Allow user interaction
        borderWindow.ignoresMouseEvents = false
        borderWindow.isReleasedWhenClosed = false
        
        // Set window to be visible in all spaces to ensure it stays visible
        borderWindow.collectionBehavior = [.canJoinAllSpaces, .participatesInCycle]
        
        // Create a view for the window content
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: rect.width, height: rect.height))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = color.withAlphaComponent(0.3).cgColor
        
        // Add a label to the center of the view
        let label = NSTextField(labelWithString: "Empty Split")
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = NSColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .clear
        
        // Add a subtitle with instructions
        let subtitle = NSTextField(labelWithString: "Drag applications here")
        subtitle.alignment = .center
        subtitle.font = NSFont.systemFont(ofSize: 16)
        subtitle.textColor = NSColor.white
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.backgroundColor = .clear
        
        contentView.addSubview(label)
        contentView.addSubview(subtitle)
        
        // Center the labels in the view
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -15),
            
            subtitle.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            subtitle.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10)
        ])
        
        // Set the view as the window's content view
        borderWindow.contentView = contentView
        
        // Make the window key and order it front
        borderWindow.makeKeyAndOrderFront(nil)
        
        // Add to active borders
        activeBorders.append(borderWindow)
        
        // Force AeroSpace to detect this window by activating it
        borderWindow.makeKey()
        
        return borderWindow
    }
    
    /// Removes all active borders
    func removeAllBorders() {
        for window in activeBorders {
            window.orderOut(nil as Any?)
        }
        activeBorders.removeAll()
    }
}

// Helper function to create a solid window border
@discardableResult
func createSolidWindow(for rect: Rect, color: NSColor = .orange, title: String = "Empty Split") -> NSWindow {
    return SolidWindowBorder.shared.createSolidWindow(for: rect, color: color, title: title)
}

// Helper function to clear all solid window borders
func clearAllSolidWindows() {
    SolidWindowBorder.shared.removeAllBorders()
} 