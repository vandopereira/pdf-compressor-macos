import Foundation

public enum CompressionAction: Equatable, Sendable {
    case skip
    case compress
}

public struct CompressionPlan: Equatable, Sendable {
    public let action: CompressionAction
    public let targetBytes: Int64

    public init(action: CompressionAction, targetBytes: Int64) {
        self.action = action
        self.targetBytes = targetBytes
    }
}

public enum CompressionStatus: Equatable, Sendable {
    case pending
    case skipped
    case compressing
    case completed
    case failed(String)
}

public struct CompressionResult: Equatable, Sendable {
    public let sourceURL: URL
    public let outputURL: URL?
    public let originalBytes: Int64
    public let finalBytes: Int64
    public let status: CompressionStatus

    public init(
        sourceURL: URL,
        outputURL: URL?,
        originalBytes: Int64,
        finalBytes: Int64,
        status: CompressionStatus
    ) {
        self.sourceURL = sourceURL
        self.outputURL = outputURL
        self.originalBytes = originalBytes
        self.finalBytes = finalBytes
        self.status = status
    }
}
