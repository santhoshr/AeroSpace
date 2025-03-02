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
        
        // If there are windows, distribute them between the containers
        if !windowsToMove.isEmpty {
            for window in windowsToMove {
                let data = window.unbindFromParent()
                window.bind(to: firstContainer, adaptiveWeight: data.adaptiveWeight, index: 0)
            }
        }
        
        // Refresh the layout
        workspace.layoutWorkspace()
        
        createEmptySplitVisual(workspace: workspace, orientation: orientation)
        
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

    private func createEmptySplitVisual(workspace: Workspace, orientation: Orientation) {
        let monitor = workspace.workspaceMonitor
        let frame = monitor.visibleRectPaddedByOuterGaps
        
        // Calculate the empty split area
        let emptyRect: Rect = frame
        
        // Create a dedicated overlay window for the empty split
        let overlayWindow = NSWindow(
            contentRect: NSRect(
                x: emptyRect.topLeftX,
                y: emptyRect.topLeftY - emptyRect.height,
                width: emptyRect.width,
                height: emptyRect.height
            ),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Configure the window
        overlayWindow.title = "Empty Split"
        overlayWindow.backgroundColor = NSColor.systemOrange.withAlphaComponent(0.2)
        overlayWindow.isOpaque = false
        overlayWindow.hasShadow = false
        overlayWindow.level = NSWindow.Level.floating // Use floating level so AeroSpace can manage it
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .participatesInCycle]
        
        // Create a view for the window content
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: emptyRect.width, height: emptyRect.height))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.clear.cgColor
        
        // Add a label to the center of the view
        let label = NSTextField(labelWithString: "Drag applications here")
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = NSColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .clear
        
        contentView.addSubview(label)
        
        // Center the labels in the view
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
        ])
        
        // Set the view as the window's content view
        overlayWindow.contentView = contentView
        
        // Make the window key and order it front
        overlayWindow.makeKeyAndOrderFront(nil)
    }
}
