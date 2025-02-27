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
        print("DEBUG: EmptySplitVisual initialized for split \(emptySplit.id)")
    }
    
    /// Show the border around the empty split
    func showBorder() {
        // Remove existing border if any
        hideBorder()
        
        // Get the frame for rendering
        guard let frame = emptySplit.getFrameForRendering() else {
            print("DEBUG: No frame available for rendering, cannot show border")
            return
        }
        
        print("DEBUG: Showing border for split \(emptySplit.id) at \(frame.topLeftX), \(frame.topLeftY), \(frame.width)x\(frame.height)")
        
        // Add simple highlight in parent view
        if let window = NSApp.keyWindow {
            // Create view for the border
            let view = NSView(frame: NSRect(
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
            
            print("DEBUG: Border view added to window")
        } else {
            print("DEBUG: No key window available to add border")
        }
    }
    
    /// Hide the border
    func hideBorder() {
        if let view = borderView {
            print("DEBUG: Hiding border for split \(emptySplit.id)")
            view.removeFromSuperview()
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
