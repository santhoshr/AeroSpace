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
        
        // If there are windows, distribute them between the containers
        if !windowsToMove.isEmpty {
            for window in windowsToMove {
                let data = window.unbindFromParent()
                window.bind(to: firstContainer, adaptiveWeight: data.adaptiveWeight, index: 0)
            }
        }
        
        // Refresh the layout
        workspace.layoutWorkspace()
        
        return true
    }
}
