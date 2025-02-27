import AppKit

class FocusedWindowBorder {
    static let shared = FocusedWindowBorder()
    private var borderWindow: NSWindow?
    private let borderWidth: CGFloat = 4.0
    private let borderColor: NSColor = NSColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 0.8)
    
    func showBorder(frame: NSRect) {
        let borderFrame = frame.insetBy(dx: -borderWidth, dy: -borderWidth)
        
        if let existingWindow = borderWindow {
            existingWindow.setFrame(borderFrame, display: true)
        } else {
            let window = NSWindow(
                contentRect: borderFrame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false)
            
            // Make window completely transparent
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.isReleasedWhenClosed = false
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 1)
            
            // Use simple NSView instead of NSVisualEffectView for pure transparency
            let borderView = NSView(frame: NSRect(origin: .zero, size: borderFrame.size))
            borderView.wantsLayer = true
            
            // Configure border
            borderView.layer?.backgroundColor = .clear
            borderView.layer?.borderWidth = borderWidth
            borderView.layer?.borderColor = borderColor.cgColor
            borderView.layer?.cornerRadius = 6.0
            borderView.layer?.masksToBounds = true
            
            window.contentView = borderView
            borderView.autoresizingMask = [.width, .height]
            
            self.borderWindow = window
        }
        
        borderWindow?.orderFront(nil)
        
        // Gentle fade-in animation
        if let layer = borderWindow?.contentView?.layer {
            layer.removeAllAnimations()
            
            let animation = CABasicAnimation(keyPath: "borderColor")
            animation.fromValue = borderColor.withAlphaComponent(0.3).cgColor
            animation.toValue = borderColor.cgColor
            animation.duration = 0.2
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            layer.add(animation, forKey: "borderFade")
        }
    }
    
    func hideBorder() {
        borderWindow?.orderOut(nil)
    }
}
