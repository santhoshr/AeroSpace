public struct SplitCmdArgs: CmdArgs {
    public let rawArgs: EquatableNoop<[String]>
    fileprivate init(rawArgs: [String]) { self.rawArgs = .init(rawArgs) }
    public static let parser: CmdParser<Self> = cmdParser(
        kind: .split,
        allowInConfig: true,
        help: split_help_generated,
        options: [
            "--window-id": optionalWindowIdFlag(),
            "--empty": trueBoolFlag(\.createEmpty),
        ],
        arguments: [newArgParser(\.arg, parseSplitArg, mandatoryArgPlaceholder: SplitArg.unionLiteral)]
    )

    public var arg: Lateinit<SplitArg> = .uninitialized
    public var windowId: UInt32?
    public var workspaceName: WorkspaceName?
    public var createEmpty: Bool = false

    public init(rawArgs: [String], _ arg: SplitArg, createEmpty: Bool = false) {
        self.rawArgs = .init(rawArgs)
        self.arg = .initialized(arg)
        self.createEmpty = createEmpty
    }

    public enum SplitArg: String, CaseIterable {
        case horizontal, vertical, opposite
    }
}

public func parseSplitCmdArgs(_ args: [String]) -> ParsedCmd<SplitCmdArgs> {
    parseSpecificCmdArgs(SplitCmdArgs(rawArgs: args), args)
}

private func parseSplitArg(arg: String, nextArgs: inout [String]) -> Parsed<SplitCmdArgs.SplitArg> {
    parseEnum(arg, SplitCmdArgs.SplitArg.self)
}
