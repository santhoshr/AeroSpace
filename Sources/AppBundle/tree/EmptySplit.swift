import AppKit
import Common

/// EmptySplit represents an empty tiling area that can be later filled with content.
/// This enables manual tiling similar to notion/ion window managers.
class EmptySplit: TreeNode {
    /// Unique identifier for this empty split
    let id: UUID
    
    /// Visual placeholder size to use when floating
    var lastFloatingSize: CGSize?
    
    override var parent: NonLeafTreeNodeObject { super.parent ?? errorT("EmptySplit always has parent") }
    
    init(parent: NonLeafTreeNodeObject, adaptiveWeight: CGFloat, index: Int, lastFloatingSize: CGSize? = nil) {
        self.id = UUID()
        self.lastFloatingSize = lastFloatingSize
        super.init(parent: parent, adaptiveWeight: adaptiveWeight, index: index)
    }
    
    /// Replace this empty split with a window
    func replaceWithWindow(_ window: Window) -> Bool {
        let parentNode = parent
        let data = unbindFromParent()
        window.bind(to: parentNode, adaptiveWeight: data.adaptiveWeight, index: data.index)
        window.markAsMostRecentChild()
        
        // Clean up visual resources
        cleanup()
        
        return true
    }
    
    /// Get frame for rendering placeholder or drop target visuals
    func getFrameForRendering() -> Rect? {
        return lastAppliedLayoutPhysicalRect
    }
    
    /// Focus this empty split
    @discardableResult
    func focusEmptySplit() -> Bool {
        markAsMostRecentChild()
        let result = setFocus(to: LiveFocus(windowOrNil: nil, emptySplitOrNil: self, workspace: mostRecentWorkspaceParent))
        updateVisual()
        return result
    }
    
    /// Convert to LiveFocus
    func toLiveFocusOrNil() -> LiveFocus? {
        return LiveFocus(windowOrNil: nil, emptySplitOrNil: self, workspace: mostRecentWorkspaceParent)
    }
    
    /// Update the visual representation of this empty split
    func updateVisual() {
        let frame = getFrameForRendering()
        let visual = getOrCreateVisual(for: self)
        visual.showBorder()
    }
    
    /// Clean up when this empty split is removed
    func cleanup() {
        removeVisual(for: id)
    }
    
    /// Deinitializer to ensure cleanup
    deinit {
        cleanup()
    }
    
    /// Get the containing workspace
    var mostRecentWorkspaceParent: Workspace {
        let fullParentChain = parentsWithSelf
        return (fullParentChain.first { $0 is Workspace } as? Workspace) ?? errorT("EmptySplit must have a Workspace ancestor")
    }
}

/// Extension to TreeNode to handle empty splits
extension TreeNode {
    /// Check if this node is an empty split
    var isEmptySplit: Bool {
        return self is EmptySplit
    }
    
    /// Find the first empty split in this subtree
    var firstEmptySplitRecursive: EmptySplit? {
        if let split = self as? EmptySplit {
            return split
        }
        
        for child in children {
            if let emptySplit = child.firstEmptySplitRecursive {
                return emptySplit
            }
        }
        
        return nil
    }
    
    /// Get all empty splits in this subtree
    var allEmptySplitsRecursive: [EmptySplit] {
        var result: [EmptySplit] = []
        
        if let split = self as? EmptySplit {
            result.append(split)
        }
        
        for child in children {
            result.append(contentsOf: child.allEmptySplitsRecursive)
        }
        
        return result
    }
}

/// Extension to TilingContainer to support empty splits
extension TilingContainer {
    /// Create a new empty split
    @discardableResult
    func createEmptySplit(atIndex index: Int = INDEX_BIND_LAST) -> EmptySplit {
        let split = EmptySplit(parent: self, adaptiveWeight: WEIGHT_AUTO, index: index)
        split.markAsMostRecentChild()
        return split
    }
    
    /// Create a split with a new container having an empty split
    @discardableResult
    func createContainerWithEmptySplit(orientation: Orientation, index: Int = INDEX_BIND_LAST) -> EmptySplit {
        let container = TilingContainer(
            parent: self,
            adaptiveWeight: WEIGHT_AUTO,
            orientation,
            .tiles,
            index: index
        )
        return container.createEmptySplit()
    }
}

/// Extension to Workspace for empty split support
extension Workspace {
    /// Convenience method to create an empty split in workspace's root container
    @discardableResult
    func createEmptySplit() -> EmptySplit {
        return rootTilingContainer.createEmptySplit()
    }
    
    /// Check if this workspace has only empty splits (no actual windows)
    var hasOnlyEmptySplits: Bool {
        let windows = allLeafWindowsRecursive
        return windows.isEmpty && !allEmptySplitsRecursive.isEmpty
    }
}
