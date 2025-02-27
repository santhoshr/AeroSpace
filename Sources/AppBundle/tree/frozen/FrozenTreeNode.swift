import AppKit
import Common

enum FrozenTreeNode {
    case container(FrozenContainer)
    case window(FrozenWindow)
    case emptySplit(FrozenEmptySplit)
}

struct FrozenContainer {
    let children: [FrozenTreeNode]
    let layout: Layout
    let orientation: Orientation
    let weight: CGFloat

    init(_ container: TilingContainer) {
        children = container.children.map {
            switch $0.nodeCases {
                case .window(let w): .window(FrozenWindow(w))
                case .tilingContainer(let c): .container(FrozenContainer(c))
                case .emptySplit(let e): .emptySplit(FrozenEmptySplit(e))
                case .macosMinimizedWindowsContainer, .macosFullscreenWindowsContainer,
                     .macosHiddenAppsWindowsContainer, .macosPopupWindowsContainer,
                     .workspace:
                    error("Unexpected node type")
            }
        }
        layout = container.layout
        orientation = container.orientation
        weight = getWeightOrNil(container) ?? 1
    }
}

struct FrozenWindow {
    let id: UInt32
    let weight: CGFloat

    init(_ window: Window) {
        id = window.windowId
        weight = getWeightOrNil(window) ?? 1
    }
}

struct FrozenEmptySplit {
    let uuid: UUID
    let weight: CGFloat
    
    init(_ emptySplit: EmptySplit) {
        self.uuid = emptySplit.id
        self.weight = getWeightOrNil(emptySplit) ?? 1
    }
}

private func getWeightOrNil(_ node: TreeNode) -> CGFloat? {
    ((node.parent as? TilingContainer)?.orientation).map { node.getWeight($0) }
}
