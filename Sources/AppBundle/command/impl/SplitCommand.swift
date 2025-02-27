import AppKit
import Foundation
import Common

struct SplitCommand: Command {
    let args: SplitCmdArgs

    func run(_ env: CmdEnv, _ io: CmdIo) -> Bool {
        check(Thread.current.isMainThread)
        if config.enableNormalizationFlattenContainers {
            return io.err("'split' has no effect when 'enable-normalization-flatten-containers' normalization enabled. My recommendation: keep the normalizations enabled, and prefer 'join-with' over 'split'.")
        }
        guard let target = args.resolveTargetOrReportError(env, io) else { return false }
        
        // Handle the empty split creation case
        if args.createEmpty {
            return createEmptySplit(target, io)
        }
        
        guard let window = target.windowOrNil else {
            // If no window is focused, but we have an empty split, treat the empty split 
            // as a window for splitting purposes
            if let emptySplit = target.workspace.firstEmptySplitRecursive {
                return splitEmptySplit(emptySplit, io)
            }
            return io.err(noWindowIsFocused)
        }
        switch window.parent.cases {
            case .workspace:
                // Nothing to do for floating and macOS native fullscreen windows
                return io.err("Can't split floating windows")
            case .tilingContainer(let parent):
                let orientation: Orientation = switch args.arg.val {
                    case .vertical: .v
                    case .horizontal: .h
                    case .opposite: parent.orientation.opposite
                }
                if parent.children.count == 1 {
                    parent.changeOrientation(orientation)
                } else {
                    let data = window.unbindFromParent()
                    let newParent = TilingContainer(
                        parent: parent,
                        adaptiveWeight: data.adaptiveWeight,
                        orientation,
                        .tiles,
                        index: data.index
                    )
                    window.bind(to: newParent, adaptiveWeight: WEIGHT_AUTO, index: 0)
                }
                
                // After successful split, send notification with frame information
                sendSplitNotification(window: window)
                
                return true
            case .macosMinimizedWindowsContainer, .macosFullscreenWindowsContainer, .macosHiddenAppsWindowsContainer:
                return io.err("Can't split macos fullscreen, minimized windows and windows of hidden apps. This behavior may change in the future")
            case .macosPopupWindowsContainer:
                return io.err("Can't split macos popup windows")
        }
    }
    
    /// Create empty split in place of the current focus
    private func createEmptySplit(_ target: LiveFocus, _ io: CmdIo) -> Bool {
        if let window = target.windowOrNil {
            // Create an empty split based on the current window's layout
            switch window.parent.cases {
                case .workspace:
                    return io.err("Can't split floating windows with empty splits")
                case .tilingContainer(let parent):
                    let orientation: Orientation = switch args.arg.val {
                        case .vertical: .v
                        case .horizontal: .h
                        case .opposite: parent.orientation.opposite
                    }
                    if parent.children.count == 1 {
                        parent.changeOrientation(orientation)
                        
                        // Create empty split in the same parent
                        let emptySplit = parent.createEmptySplit()
                        
                        // Send notification about the split
                        sendSplitNotification(window: window, emptySplit: emptySplit)
                    } else {
                        let data = window.unbindFromParent()
                        let newParent = TilingContainer(
                            parent: parent,
                            adaptiveWeight: data.adaptiveWeight,
                            orientation,
                            .tiles,
                            index: data.index
                        )
                        window.bind(to: newParent, adaptiveWeight: WEIGHT_AUTO, index: 0)
                        
                        // Create an empty split alongside the window
                        let emptySplit = newParent.createEmptySplit()
                        
                        // Send notification about the split
                        sendSplitNotification(window: window, emptySplit: emptySplit)
                    }
                    return true
                case .macosMinimizedWindowsContainer:
                    return io.err("Can't split minimized windows")
                case .macosFullscreenWindowsContainer:
                    return io.err("Can't split fullscreen windows")
                case .macosPopupWindowsContainer:
                    return io.err("Can't split popup windows")
                case .macosHiddenAppsWindowsContainer:
                    return io.err("Can't split hidden app windows")
            }
        } else {
            // If workspace is empty, create an empty split in the root container
            let orientation: Orientation = switch args.arg.val {
                case .vertical: .v
                case .horizontal: .h
                case .opposite: .h // Default to horizontal for empty workspace
            }
            
            // Create an empty split in the root container with the specified orientation
            let workspace = target.workspace
            let rootContainer = workspace.rootTilingContainer
            
            // If root container already has an empty split, change its orientation
            if rootContainer.children.count == 1 && rootContainer.children[0].isEmptySplit {
                rootContainer.changeOrientation(orientation)
            } else if rootContainer.children.isEmpty {
                // Create the first empty split
                let emptySplit = workspace.createEmptySplit()
                
                // Send notification for the first empty split
                sendEmptySplitNotification(emptySplit: emptySplit)
            } else {
                // Create additional splits with correct orientation
                if rootContainer.orientation != orientation {
                    // Create a container with correct orientation
                    let emptySplit = rootContainer.createContainerWithEmptySplit(orientation: orientation)
                    
                    // Send notification for the new empty split
                    sendEmptySplitNotification(emptySplit: emptySplit)
                } else {
                    // Just add an empty split
                    let emptySplit = rootContainer.createEmptySplit()
                    
                    // Send notification for the new empty split
                    sendEmptySplitNotification(emptySplit: emptySplit)
                }
            }
            
            return true
        }
    }
    
    /// Split an existing empty split
    private func splitEmptySplit(_ emptySplit: EmptySplit, _ io: CmdIo) -> Bool {
        switch emptySplit.parent.cases {
            case .workspace:
                return io.err("Can't split floating empty splits")
            case .tilingContainer(let parent):
                let orientation: Orientation = switch args.arg.val {
                    case .vertical: .v
                    case .horizontal: .h
                    case .opposite: parent.orientation.opposite
                }
                if parent.children.count == 1 {
                    parent.changeOrientation(orientation)
                } else {
                    let data = emptySplit.unbindFromParent()
                    let newParent = TilingContainer(
                        parent: parent,
                        adaptiveWeight: data.adaptiveWeight,
                        orientation,
                        .tiles,
                        index: data.index
                    )
                    emptySplit.bind(to: newParent, adaptiveWeight: WEIGHT_AUTO, index: 0)
                    
                    // Create another empty split in the same container
                    let newEmptySplit = newParent.createEmptySplit()
                    
                    // Send notification about the split
                    sendSplitNotificationForEmptySplits(emptySplit1: emptySplit, emptySplit2: newEmptySplit)
                }
                return true
            case .macosMinimizedWindowsContainer:
                return io.err("Can't split minimized empty splits")
            case .macosFullscreenWindowsContainer:
                return io.err("Can't split fullscreen empty splits")
            case .macosPopupWindowsContainer:
                return io.err("Can't split popup empty splits")
            case .macosHiddenAppsWindowsContainer:
                return io.err("Can't split hidden app empty splits")
        }
    }
    
    /// Send notification about window split with frames
    private func sendSplitNotification(window: Window, emptySplit: EmptySplit? = nil) {
        // Get window frame using topLeft and size
        guard let topLeft = window.getTopLeftCorner(), 
              let size = window.getSize() else { return }
        
        // Convert to NSRect
        let activeFrame = NSRect(
            x: topLeft.x,
            y: topLeft.y,
            width: size.width,
            height: size.height
        )
        
        var inactiveFrames: [NSRect] = []
        
        // If we have an empty split, add it to inactive frames
        if let emptySplit = emptySplit, let splitFrame = emptySplit.getFrameForRendering() {
            inactiveFrames.append(NSRect(
                x: splitFrame.topLeftX,
                y: splitFrame.topLeftY,
                width: splitFrame.width,
                height: splitFrame.height
            ))
        } else {
            // Otherwise gather all sibling windows
            if let parent = window.parent as? TilingContainer {
                for child in parent.children {
                    if child != window, let childWindow = child as? Window, 
                       let childTopLeft = childWindow.getTopLeftCorner(), 
                       let childSize = childWindow.getSize() {
                        inactiveFrames.append(NSRect(
                            x: childTopLeft.x,
                            y: childTopLeft.y,
                            width: childSize.width,
                            height: childSize.height
                        ))
                    } else if child != window, let childSplit = child as? EmptySplit, let frame = childSplit.getFrameForRendering() {
                        inactiveFrames.append(NSRect(
                            x: frame.topLeftX,
                            y: frame.topLeftY,
                            width: frame.width,
                            height: frame.height
                        ))
                    }
                }
            }
        }
        
        // Post the notification
        NotificationCenter.default.post(
            name: NSNotification.Name("AeroSpaceWindowSplit"),
            object: nil,
            userInfo: [
                "activeFrame": activeFrame,
                "inactiveFrames": inactiveFrames
            ]
        )
    }
    
    /// Send notification for empty split creation
    private func sendEmptySplitNotification(emptySplit: EmptySplit) {
        guard let frame = emptySplit.getFrameForRendering() else { return }
        
        let activeFrame = NSRect(
            x: frame.topLeftX,
            y: frame.topLeftY,
            width: frame.width,
            height: frame.height
        )
        
        // Post the notification
        NotificationCenter.default.post(
            name: NSNotification.Name("AeroSpaceWindowSplit"),
            object: nil,
            userInfo: [
                "activeFrame": activeFrame,
                "inactiveFrames": [] as [NSRect]
            ]
        )
    }
    
    /// Send notification for split between two empty splits
    private func sendSplitNotificationForEmptySplits(emptySplit1: EmptySplit, emptySplit2: EmptySplit) {
        guard let frame1 = emptySplit1.getFrameForRendering() else { return }
        guard let frame2 = emptySplit2.getFrameForRendering() else { return }
        
        let activeFrame = NSRect(
            x: frame1.topLeftX,
            y: frame1.topLeftY,
            width: frame1.width,
            height: frame1.height
        )
        
        let inactiveFrame = NSRect(
            x: frame2.topLeftX,
            y: frame2.topLeftY,
            width: frame2.width,
            height: frame2.height
        )
        
        // Post the notification
        NotificationCenter.default.post(
            name: NSNotification.Name("AeroSpaceWindowSplit"),
            object: nil,
            userInfo: [
                "activeFrame": activeFrame,
                "inactiveFrames": [inactiveFrame]
            ]
        )
    }
}
