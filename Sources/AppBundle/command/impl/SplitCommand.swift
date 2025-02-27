import AppKit
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
                    
                    // If --empty flag is set, create an empty split alongside the window
                    if args.createEmpty {
                        newParent.createEmptySplit()
                    }
                }
                return true
            case .macosMinimizedWindowsContainer, .macosFullscreenWindowsContainer, .macosHiddenAppsWindowsContainer:
                return io.err("Can't split macos fullscreen, minimized windows and windows of hidden apps. This behavior may change in the future")
            case .macosPopupWindowsContainer:
                return false // Impossible
        }
    }
    
    /// Create an empty split in the workspace or within an existing split
    private func createEmptySplit(_ target: LiveFocus, _ io: CmdIo) -> Bool {
        // If there's already a window focused, split it
        if target.windowOrNil != nil {
            // The window case is handled in the main run method
            return false
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
                workspace.createEmptySplit()
            } else {
                // Create additional splits with correct orientation
                if rootContainer.orientation != orientation {
                    // Create a container with correct orientation
                    rootContainer.createContainerWithEmptySplit(orientation: orientation)
                } else {
                    // Just add an empty split
                    rootContainer.createEmptySplit()
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
                    newParent.createEmptySplit()
                }
                return true
            case .macosMinimizedWindowsContainer, .macosFullscreenWindowsContainer, .macosHiddenAppsWindowsContainer:
                return io.err("Can't split macOS fullscreen, minimized empty splits. This behavior may change in the future")
            case .macosPopupWindowsContainer:
                return false // Impossible
        }
    }
}
