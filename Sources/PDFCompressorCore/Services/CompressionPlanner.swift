import Foundation

public enum CompressionPlanner {
    public static func plan(sourceBytes: Int64, targetMegabytes: Double) -> CompressionPlan {
        let targetBytes = max(1, Int64((targetMegabytes * 1_000_000).rounded()))
        let action: CompressionAction = sourceBytes > targetBytes ? .compress : .skip
        return CompressionPlan(action: action, targetBytes: targetBytes)
    }

    public static func workerLimit(activeProcessorCount: Int = ProcessInfo.processInfo.activeProcessorCount) -> Int {
        max(1, min(4, activeProcessorCount - 1))
    }

    public static func defaultOutputURL(for sourceURL: URL, destinationFolder: URL? = nil) -> URL {
        let folder = destinationFolder ?? sourceURL.deletingLastPathComponent()
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        return folder
            .appendingPathComponent("\(baseName)-compressed")
            .appendingPathExtension("pdf")
    }
}
