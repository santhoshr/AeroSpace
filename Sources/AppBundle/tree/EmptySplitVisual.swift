import AppKit
import Common

/// A class that handles the visual representation of an empty split
class EmptySplitVisual {
    /// The empty split this visual represents
    private let emptySplit: EmptySplit

    /// The layer used to render the border
    private var borderView: NSView?

    /// Border color for focused empty split
    private let focusedBorderColor = NSColor(red: 0.0, green: 0.6, blue: 1.0, alpha: 0.9)

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
        guard let frame = emptySplit.getFrameForRendering() else {
            return
        }

        // Try multiple approaches to find a window to add our border view to
        var targetWindow: NSWindow?

        // First try: Use the key window
        if let keyWindow = NSApp.keyWindow {
            targetWindow = keyWindow
        }

        // Second try: Find first visible window on the same screen
        if targetWindow == nil {
            let screenFrame = NSScreen.main?.frame ?? NSRect.zero
            for window in NSApp.windows {
                if window.isVisible && !window.isExcludedFromWindowsMenu
                    && NSIntersectsRect(window.frame, screenFrame)
                {
                    targetWindow = window
                    break
                }
            }
        }

        // Third try: Create our own window if nothing else works
        if targetWindow == nil {
            let overlayWindow = NSWindow(
                contentRect: NSRect(
                    x: frame.topLeftX,
                    y: frame.topLeftY,
                    width: frame.width,
                    height: frame.height
                ),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )

            overlayWindow.isReleasedWhenClosed = false
            overlayWindow.level = .floating
            overlayWindow.backgroundColor = .clear
            overlayWindow.isOpaque = false
            overlayWindow.hasShadow = false
            overlayWindow.ignoresMouseEvents = true

            // Create view for the border in our custom window
            let borderLayer = CALayer()
            borderLayer.frame = NSRect(x: 0, y: 0, width: frame.width, height: frame.height)
            borderLayer.borderWidth = borderWidth
            borderLayer.borderColor = focusedBorderColor.cgColor

            let view = NSView(frame: NSRect(x: 0, y: 0, width: frame.width, height: frame.height))
            view.wantsLayer = true
            view.layer?.addSublayer(borderLayer)

            overlayWindow.contentView = view
            overlayWindow.orderFront(nil)

            // Store reference
            self.borderView = view

            return
        }

        // If we found a window to use, add our border view to it
        if let window = targetWindow {
            // Create view for the border
            let view = NSView(
                frame: NSRect(
                    x: frame.topLeftX,
                    y: frame.topLeftY,
                    width: frame.width,
                    height: frame.height
                ))

            // Configure the view
            view.wantsLayer = true
            view.layer?.backgroundColor = NSColor.clear.cgColor

            // Create border layer
            let borderLayer = CALayer()
            borderLayer.frame = view.bounds
            borderLayer.borderWidth = borderWidth
            borderLayer.borderColor = focusedBorderColor.cgColor
            borderLayer.cornerRadius = 0

            // Add border layer to view
            view.layer?.addSublayer(borderLayer)

            // Add view to window
            window.contentView?.addSubview(view)

            // Store reference
            self.borderView = view

        }
    }

    /// Hide the border
    func hideBorder() {
        if let view = borderView {
            view.removeFromSuperview()
            // If we have a parent window that is our custom overlay, close it
            if let parentWindow = view.window,
                parentWindow.styleMask == [.borderless],
                parentWindow.ignoresMouseEvents
            {
                parentWindow.close()
            }
            borderView = nil
        }
    }
}

/// Global storage for empty split visuals
var emptySplitVisuals: [UUID: EmptySplitVisual] = [:]

/// Get or create an EmptySplitVisual for the given EmptySplit
func getOrCreateVisual(for emptySplit: EmptySplit) -> EmptySplitVisual {
    guard let existingVisual = emptySplitVisuals[emptySplit.id] else {
        let newVisual = EmptySplitVisual(emptySplit: emptySplit)
        emptySplitVisuals[emptySplit.id] = newVisual
        return newVisual
    }
    return existingVisual
}

/// Remove visual for an EmptySplit
func removeVisual(for id: UUID) {
    if let visual = emptySplitVisuals[id] {
        visual.hideBorder()
        emptySplitVisuals.removeValue(forKey: id)
    }
}
