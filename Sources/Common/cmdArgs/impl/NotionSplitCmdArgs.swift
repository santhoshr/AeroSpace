import Foundation

public struct NotionSplitCmdArgs: CmdArgs {
    public let rawArgs: EquatableNoop<[String]>
    fileprivate init(rawArgs: [String]) { self.rawArgs = .init(rawArgs) }
    public static let parser: CmdParser<Self> = cmdParser(
        kind: .notionSplit,
        allowInConfig: true,
        help: "Split the screen in Notion WM style",
        options: [
            "--window-id": optionalWindowIdFlag(),
        ],
        arguments: [newArgParser(\.arg, parseNotionSplitOrientation, mandatoryArgPlaceholder: NotionSplitOrientation.unionLiteral)]
    )

    public var arg: Lateinit<NotionSplitOrientation> = .uninitialized
    public var windowId: UInt32?
    public var workspaceName: WorkspaceName?

    public init(rawArgs: [String], _ arg: NotionSplitOrientation) {
        self.rawArgs = .init(rawArgs)
        self.arg = .initialized(arg)
    }

    public enum NotionSplitOrientation: String, CaseIterable {
        case horizontal, vertical
    }
}

public func parseNotionSplitCmdArgs(_ args: [String]) -> ParsedCmd<NotionSplitCmdArgs> {
    parseSpecificCmdArgs(NotionSplitCmdArgs(rawArgs: args), args)
}

private func parseNotionSplitOrientation(arg: String, nextArgs: inout [String]) -> Parsed<NotionSplitCmdArgs.NotionSplitOrientation> {
    parseEnum(arg, NotionSplitCmdArgs.NotionSplitOrientation.self)
} 