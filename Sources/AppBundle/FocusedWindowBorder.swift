import AppKit

enum BorderType {
    case workspace   // For overall workspace border
    case activePane  // For currently focused window/pane
    case inactivePane // For other windows/panes in the workspace
    
    var config: BorderConfig {
        switch self {
        case .workspace:
            return BorderConfig(
                color: NSColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.8), // Red
                width: 6.0,
                level: Int(CGWindowLevelForKey(.mainMenuWindow)) + 2
            )
        case .activePane:
            return BorderConfig(
                color: NSColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 0.8), // Blue
                width: 4.0,
                level: Int(CGWindowLevelForKey(.mainMenuWindow)) + 1
            )
        case .inactivePane:
            return BorderConfig(
                color: NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5), // Grey
                width: 2.0,
                level: Int(CGWindowLevelForKey(.mainMenuWindow))
            )
        }
    }
}

struct BorderConfig {
    let color: NSColor
    let width: CGFloat
    let level: Int
}

class BorderWindow {
    private var window: NSWindow
    private let type: BorderType
    
    init(frame: NSRect, type: BorderType) {
        self.type = type
        let config = type.config
        let borderFrame = frame.insetBy(dx: -config.width, dy: -config.width)
        
        window = NSWindow(
            contentRect: borderFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.level = NSWindow.Level(rawValue: config.level)
        
        let borderView = NSView(frame: NSRect(origin: .zero, size: borderFrame.size))
        borderView.wantsLayer = true
        borderView.layer?.backgroundColor = .clear
        borderView.layer?.borderWidth = config.width
        borderView.layer?.borderColor = config.color.cgColor
        borderView.layer?.cornerRadius = 6.0
        borderView.layer?.masksToBounds = true
        
        window.contentView = borderView
        borderView.autoresizingMask = [.width, .height]
    }
    
    func show() {
        window.orderFront(nil)
        animateBorder()
    }
    
    func hide() {
        window.orderOut(nil)
    }
    
    func updateFrame(_ frame: NSRect) {
        let config = type.config
        let borderFrame = frame.insetBy(dx: -config.width, dy: -config.width)
        window.setFrame(borderFrame, display: true)
    }
    
    private func animateBorder() {
        guard let layer = window.contentView?.layer else { return }
        layer.removeAllAnimations()
        
        let animation = CABasicAnimation(keyPath: "borderColor")
        animation.fromValue = type.config.color.withAlphaComponent(0.3).cgColor
        animation.toValue = type.config.color.cgColor
        animation.duration = 0.2
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(animation, forKey: "borderFade")
    }
}

class FocusedWindowBorder {
    static let shared = FocusedWindowBorder()
    
    private var workspaceBorder: BorderWindow?
    private var activeBorder: BorderWindow?
    private var inactiveBorders: [BorderWindow] = []
    
    func updateBorders(workspace: NSRect?, active: NSRect?, inactive: [NSRect]?) {
        // Update workspace border
        if let frame = workspace {
            if let existing = workspaceBorder {
                existing.updateFrame(frame)
                existing.show()
            } else {
                workspaceBorder = BorderWindow(frame: frame, type: .workspace)
                workspaceBorder?.show()
            }
        } else {
            workspaceBorder?.hide()
        }
        
        // Update active window border
        if let frame = active {
            if let existing = activeBorder {
                existing.updateFrame(frame)
                existing.show()
            } else {
                activeBorder = BorderWindow(frame: frame, type: .activePane)
                activeBorder?.show()
            }
        } else {
            activeBorder?.hide()
        }
        
        // Update inactive borders
        updateInactiveBorders(frames: inactive ?? [])
    }
    
    private func updateInactiveBorders(frames: [NSRect]) {
        // Remove excess borders
        while inactiveBorders.count > frames.count {
            inactiveBorders.removeLast().hide()
        }
        
        // Update or create borders as needed
        for (index, frame) in frames.enumerated() {
            if index < inactiveBorders.count {
                inactiveBorders[index].updateFrame(frame)
                inactiveBorders[index].show()
            } else {
                let border = BorderWindow(frame: frame, type: .inactivePane)
                inactiveBorders.append(border)
                border.show()
            }
        }
    }
    
    func hideAll() {
        workspaceBorder?.hide()
        activeBorder?.hide()
        inactiveBorders.forEach { $0.hide() }
    }
}
