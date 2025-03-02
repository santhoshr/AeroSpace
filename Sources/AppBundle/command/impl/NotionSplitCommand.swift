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
        
        // Get the orientation from the arguments
        let orientation: Orientation = switch args.arg.val {
            case .vertical: .v
            case .horizontal: .h
        }
        
        // Get the root tiling container
        let rootContainer = workspace.rootTilingContainer
        
        // Create a new container with the specified orientation
        rootContainer.changeOrientation(orientation)
        
        // Move all existing windows to the first container
        let firstContainer = TilingContainer(
            parent: rootContainer,
            adaptiveWeight: WEIGHT_AUTO,
            orientation.opposite,
            .tiles,
            index: 0
        )
        
        // Move all windows from root to first container
        let windowsToMove = rootContainer.children.filterIsInstance(of: Window.self)
        for window in windowsToMove {
            let data = window.unbindFromParent()
            window.bind(to: firstContainer, adaptiveWeight: data.adaptiveWeight, index: INDEX_BIND_LAST)
        }
        
        // Create a new empty container for the right/bottom half
        let newContainer = TilingContainer(
            parent: rootContainer,
            adaptiveWeight: WEIGHT_AUTO,
            orientation.opposite,
            .tiles,
            index: INDEX_BIND_LAST
        )
        
        // Focus the new container
        newContainer.markAsMostRecentChild()
        
        // Refresh the layout
        workspace.layoutWorkspace()
        
        if let rect = newContainer.lastAppliedLayoutPhysicalRect {
            // Use our custom border implementation instead of JankyBorders
            createBorder(for: rect, color: NSColor.orange, thickness: 5.0)
        }
        
        return true
    }
} 