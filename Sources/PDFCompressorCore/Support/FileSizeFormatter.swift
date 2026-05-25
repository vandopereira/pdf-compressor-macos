import Foundation

public enum FileSizeFormatter {
    public static func megabytesString(bytes: Int64) -> String {
        let megabytes = Double(bytes) / 1_000_000
        return String(format: "%.1f MB", megabytes)
    }
}
