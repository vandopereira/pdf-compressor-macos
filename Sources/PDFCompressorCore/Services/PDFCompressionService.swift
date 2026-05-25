import AppKit
import Foundation
import PDFKit

public enum PDFCompressionError: Error, LocalizedError, Sendable {
    case missingFile
    case unreadablePDF
    case cannotCreateOutput
    case outputLargerThanOriginal

    public var errorDescription: String? {
        switch self {
        case .missingFile:
            "The source file could not be found."
        case .unreadablePDF:
            "The PDF could not be opened."
        case .cannotCreateOutput:
            "The compressed PDF could not be written."
        case .outputLargerThanOriginal:
            "Compression did not reduce this PDF."
        }
    }
}

public struct CompressionAttempt: Sendable {
    public let scale: CGFloat
    public let jpegQuality: CGFloat

    public init(scale: CGFloat, jpegQuality: CGFloat) {
        self.scale = scale
        self.jpegQuality = jpegQuality
    }
}

public final class PDFCompressionService: @unchecked Sendable {
    public static let standardAttempts: [CompressionAttempt] = [
        .init(scale: 1.6, jpegQuality: 0.86),
        .init(scale: 1.35, jpegQuality: 0.78),
        .init(scale: 1.1, jpegQuality: 0.68),
        .init(scale: 0.9, jpegQuality: 0.58),
        .init(scale: 0.72, jpegQuality: 0.48),
        .init(scale: 0.58, jpegQuality: 0.40)
    ]

    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func compress(
        sourceURL: URL,
        targetMegabytes: Double,
        destinationFolder: URL? = nil,
        progress: (@Sendable (Double) -> Void)? = nil
    ) async -> CompressionResult {
        do {
            let originalBytes = try sourceSize(sourceURL)
            let plan = CompressionPlanner.plan(sourceBytes: originalBytes, targetMegabytes: targetMegabytes)
            guard plan.action == .compress else {
                progress?(1)
                return CompressionResult(
                    sourceURL: sourceURL,
                    outputURL: nil,
                    originalBytes: originalBytes,
                    finalBytes: originalBytes,
                    status: .skipped
                )
            }

            let outputURL = CompressionPlanner.defaultOutputURL(for: sourceURL, destinationFolder: destinationFolder)
            let compressedBytes = try await renderCompressedPDF(
                sourceURL: sourceURL,
                outputURL: outputURL,
                targetBytes: plan.targetBytes,
                progress: progress
            )

            guard compressedBytes < originalBytes else {
                try? fileManager.removeItem(at: outputURL)
                throw PDFCompressionError.outputLargerThanOriginal
            }

            return CompressionResult(
                sourceURL: sourceURL,
                outputURL: outputURL,
                originalBytes: originalBytes,
                finalBytes: compressedBytes,
                status: .completed
            )
        } catch {
            let bytes = (try? sourceSize(sourceURL)) ?? 0
            return CompressionResult(
                sourceURL: sourceURL,
                outputURL: nil,
                originalBytes: bytes,
                finalBytes: bytes,
                status: .failed(error.localizedDescription)
            )
        }
    }

    private func sourceSize(_ sourceURL: URL) throws -> Int64 {
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw PDFCompressionError.missingFile
        }
        let attributes = try fileManager.attributesOfItem(atPath: sourceURL.path)
        return (attributes[.size] as? NSNumber)?.int64Value ?? 0
    }

    private func renderCompressedPDF(
        sourceURL: URL,
        outputURL: URL,
        targetBytes: Int64,
        progress: (@Sendable (Double) -> Void)?
    ) async throws -> Int64 {
        try await Task.detached(priority: .userInitiated) {
            guard let document = PDFDocument(url: sourceURL), document.pageCount > 0 else {
                throw PDFCompressionError.unreadablePDF
            }

            var bestURL: URL?
            var bestSize = Int64.max
            let tempFolder = outputURL.deletingLastPathComponent()
            try self.fileManager.createDirectory(at: tempFolder, withIntermediateDirectories: true)

            for (index, attempt) in Self.standardAttempts.enumerated() {
                try Task.checkCancellation()
                let candidate = outputURL
                    .deletingLastPathComponent()
                    .appendingPathComponent(".\(outputURL.deletingPathExtension().lastPathComponent)-attempt-\(index).pdf")

                try autoreleasepool {
                    try self.writeRasterPDF(document: document, outputURL: candidate, attempt: attempt)
                }

                let candidateSize = try self.sourceSize(candidate)
                if candidateSize < bestSize {
                    if let bestURL {
                        try? self.fileManager.removeItem(at: bestURL)
                    }
                    bestURL = candidate
                    bestSize = candidateSize
                } else {
                    try? self.fileManager.removeItem(at: candidate)
                }

                progress?(Double(index + 1) / Double(Self.standardAttempts.count))
                if candidateSize <= targetBytes {
                    break
                }
            }

            guard let bestURL else {
                throw PDFCompressionError.cannotCreateOutput
            }
            try? self.fileManager.removeItem(at: outputURL)
            try self.fileManager.moveItem(at: bestURL, to: outputURL)
            return bestSize
        }.value
    }

    private func writeRasterPDF(document: PDFDocument, outputURL: URL, attempt: CompressionAttempt) throws {
        guard let consumer = CGDataConsumer(url: outputURL as CFURL) else {
            throw PDFCompressionError.cannotCreateOutput
        }
        guard let context = CGContext(consumer: consumer, mediaBox: nil, nil) else {
            throw PDFCompressionError.cannotCreateOutput
        }

        for pageIndex in 0..<document.pageCount {
            try Task.checkCancellation()
            autoreleasepool {
                guard let page = document.page(at: pageIndex) else { return }
                let bounds = page.bounds(for: .mediaBox)
                let pixelSize = CGSize(
                    width: max(1, bounds.width * attempt.scale),
                    height: max(1, bounds.height * attempt.scale)
                )
                let image = page.thumbnail(of: pixelSize, for: .mediaBox)
                guard let tiffData = image.tiffRepresentation,
                      let bitmap = NSBitmapImageRep(data: tiffData),
                      let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: attempt.jpegQuality]),
                      let provider = CGDataProvider(data: jpegData as CFData),
                      let cgImage = CGImage(
                          jpegDataProviderSource: provider,
                          decode: nil,
                          shouldInterpolate: true,
                          intent: .defaultIntent
                      )
                else {
                    return
                }

                var mediaBox = bounds
                context.beginPage(mediaBox: &mediaBox)
                context.setFillColor(NSColor.white.cgColor)
                context.fill(bounds)
                context.interpolationQuality = .medium
                let drawRect = AspectRatio.fit(
                    contentSize: CGSize(width: cgImage.width, height: cgImage.height),
                    in: bounds
                )
                context.draw(cgImage, in: drawRect)
                context.endPage()
            }
        }

        context.closePDF()
    }
}
