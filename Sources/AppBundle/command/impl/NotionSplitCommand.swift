import AppKit
import Common

struct NotionSplitCommand: Command {
    let args: NotionSplitCmdArgs

    func run(_ env: CmdEnv, _ io: CmdIo) -> Bool {
        check(Thread.current.isMainThread)
        
        // Get the current workspace
        guard let workspace = args.resolveTargetOrReportError(env, io)?.workspace else {
            return io.err("No workspace is focused")
        }
        
        // Clear any existing borders
        clearAllBorders()
        
        // Determine the orientation based on the arguments or screen dimensions
        var orientation: Orientation
        if args.arg.isInitialized {
            // Use the orientation from the arguments if provided
            orientation = switch args.arg.val {
                case .vertical: .v
                case .horizontal: .h
            }
        } else {
            // Auto-determine orientation based on screen dimensions
            let monitor = workspace.workspaceMonitor
            let frame = monitor.rect
            orientation = frame.width > frame.height ? .h : .v
        }
        
        // Get the root tiling container
        let rootContainer = workspace.rootTilingContainer
        
        // Create a new container with the specified orientation
        rootContainer.changeOrientation(orientation)
        
        // Get all existing windows
        let windowsToMove = rootContainer.children.filterIsInstance(of: Window.self)
        
        // Create the first container with accordion layout
        let firstContainer = TilingContainer(
            parent: rootContainer,
            adaptiveWeight: WEIGHT_AUTO,
            orientation.opposite, // Use opposite orientation for nested containers
            .accordion, // Use accordion layout for the container
            index: 0
        )
        
        // Create the second container with accordion layout
        let secondContainer = TilingContainer(
            parent: rootContainer,
            adaptiveWeight: WEIGHT_AUTO,
            orientation.opposite, // Use opposite orientation for nested containers
            .accordion, // Use accordion layout for the container
            index: INDEX_BIND_LAST
        )
        
        // If there are windows, distribute them between the containers
        if !windowsToMove.isEmpty {
            // Move approximately half of the windows to the first container
            let halfIndex = max(1, windowsToMove.count / 2)
            
            for (index, window) in windowsToMove.enumerated() {
                let data = window.unbindFromParent()
                if index < halfIndex {
                    // First half goes to the first container
                    window.bind(to: firstContainer, adaptiveWeight: data.adaptiveWeight, index: INDEX_BIND_LAST)
                } else {
                    // Second half goes to the second container
                    window.bind(to: secondContainer, adaptiveWeight: data.adaptiveWeight, index: INDEX_BIND_LAST)
                }
            }
        }
        
        // Focus the second container
        secondContainer.markAsMostRecentChild()
        
        // Refresh the layout
        workspace.layoutWorkspace()
        
        // Add borders to empty containers
        if windowsToMove.isEmpty || windowsToMove.count <= 1 {
            if let rect = firstContainer.lastAppliedLayoutPhysicalRect, firstContainer.children.isEmpty {
                createBorder(for: rect, color: NSColor.blue, thickness: 5.0)
            }
            
            if let rect = secondContainer.lastAppliedLayoutPhysicalRect, secondContainer.children.isEmpty {
                createBorder(for: rect, color: NSColor.orange, thickness: 5.0)
            }
        }
        
        return true
    }
    
    // Helper function to clear all borders
    private func clearAllBorders() {
        // Clear any existing borders
        BorderManager.shared.removeAllBorders()
    }
    
    // Helper function to create a border
    private func createBorder(for rect: Rect, color: NSColor, thickness: CGFloat) {
        BorderManager.shared.createBorder(for: rect, color: color, thickness: thickness)
    }
} 