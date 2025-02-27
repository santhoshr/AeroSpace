import AppKit
import Common

public class TrayMenuModel: ObservableObject {
    public static let shared = TrayMenuModel()

    private init() {}

    @Published var trayText: String = ""
    /// Is "layouting" enabled
    @Published var isEnabled: Bool = true
    /// Is border visualization enabled
    @Published var isBorderEnabled: Bool = true
    @Published var workspaces: [WorkspaceViewModel] = []
    
    /// Toggle border visualization on/off
    func toggleBorderVisibility() {
        isBorderEnabled.toggle()
        BorderIntegrationManager.shared.setEnabled(isBorderEnabled)
        
        // If borders are enabled and there's a focused window, update its border
        if isBorderEnabled {
            // If we have splits, show appropriate borders
            if let focusedWindow = focus.windowOrNil, 
               let topLeft = focusedWindow.getTopLeftCorner(),
               let size = focusedWindow.getSize() {
                // Get all sibling windows/splits
                var inactiveFrames: [NSRect] = []
                if let parent = focusedWindow.parent as? TilingContainer {
                    for child in parent.children {
                        if child != focusedWindow, let childWindow = child as? Window, 
                           let childTopLeft = childWindow.getTopLeftCorner(), 
                           let childSize = childWindow.getSize() {
                            inactiveFrames.append(NSRect(
                                x: childTopLeft.x,
                                y: childTopLeft.y,
                                width: childSize.width,
                                height: childSize.height
                            ))
                        } else if child != focusedWindow, let childSplit = child as? EmptySplit, 
                                  let childFrame = childSplit.getFrameForRendering() {
                            inactiveFrames.append(NSRect(
                                x: childFrame.topLeftX,
                                y: childFrame.topLeftY,
                                width: childFrame.width,
                                height: childFrame.height
                            ))
                        }
                    }
                    
                    if !inactiveFrames.isEmpty {
                        let focusedFrame = NSRect(
                            x: topLeft.x,
                            y: topLeft.y,
                            width: size.width,
                            height: size.height
                        )
                        BorderIntegrationManager.shared.onFocusChanged(Notification(
                            name: NSNotification.Name("AeroSpaceFocusChanged"),
                            object: nil,
                            userInfo: [
                                "focusedWindowFrame": focusedFrame,
                                "inactiveWindowFrames": inactiveFrames
                            ]
                        ))
                    } else {
                        // No splits yet, show fullscreen border
                        BorderIntegrationManager.shared.showFullscreenBorder()
                    }
                } else {
                    // No splits yet, show fullscreen border
                    BorderIntegrationManager.shared.showFullscreenBorder()
                }
            } else if let emptySplit = focus.emptySplitOrNil, 
                      let frame = emptySplit.getFrameForRendering() {
                // Show border for empty split focus
                let focusedFrame = NSRect(
                    x: frame.topLeftX,
                    y: frame.topLeftY,
                    width: frame.width,
                    height: frame.height
                )
                BorderIntegrationManager.shared.onFocusChanged(Notification(
                    name: NSNotification.Name("AeroSpaceFocusChanged"),
                    object: nil,
                    userInfo: [
                        "focusedWindowFrame": focusedFrame,
                        "inactiveWindowFrames": []
                    ]
                ))
            } else {
                // No window or split focus yet, show fullscreen border
                BorderIntegrationManager.shared.showFullscreenBorder()
            }
        }
    }
}

func updateTrayText() {
    let sortedMonitors = sortedMonitors
    let focus = focus
    TrayMenuModel.shared.trayText = (activeMode?.takeIf { $0 != mainModeId }?.first?.lets { "[\($0.uppercased())] " } ?? "") +
        sortedMonitors
        .map {
            ($0.activeWorkspace == focus.workspace && sortedMonitors.count > 1 ? "*" : "") + $0.activeWorkspace.name
        }
        .joined(separator: " │ ")
    TrayMenuModel.shared.workspaces = Workspace.all.map {
        let monitor = $0.isVisible || !$0.isEffectivelyEmpty ? " - \($0.workspaceMonitor.name)" : ""
        return WorkspaceViewModel(name: $0.name, suffix: monitor, isFocused: focus.workspace == $0)
    }
}

struct WorkspaceViewModel {
    let name: String
    let suffix: String
    let isFocused: Bool
}
