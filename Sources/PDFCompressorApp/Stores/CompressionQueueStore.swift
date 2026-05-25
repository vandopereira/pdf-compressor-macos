import AppKit
import Foundation
import Observation
import PDFCompressorCore

@MainActor
@Observable
final class CompressionQueueStore {
    var items: [QueuedPDF] = []
    var targetMegabytes: Double = 5
    var outputFolder: URL?
    var isProcessing = false

    private let service = PDFCompressionService()

    var canCompress: Bool {
        !isProcessing && items.contains { $0.status == .pending || isRetryable($0.status) }
    }

    var completedCount: Int {
        items.filter { $0.status == .completed || $0.status == .skipped }.count
    }

    var totalOriginalBytes: Int64 {
        items.reduce(0) { $0 + $1.originalBytes }
    }

    var totalFinalBytes: Int64 {
        items.reduce(0) { $0 + ($1.finalBytes ?? $1.originalBytes) }
    }

    func addFiles(_ urls: [URL]) {
        let pdfs = urls.filter { $0.pathExtension.lowercased() == "pdf" }
        for url in pdfs where !items.contains(where: { $0.sourceURL == url }) {
            let bytes = fileSize(url)
            items.append(QueuedPDF(sourceURL: url, originalBytes: bytes))
        }
    }

    func remove(_ item: QueuedPDF) {
        items.removeAll { $0.id == item.id }
    }

    func clearFinished() {
        items.removeAll { $0.status == .completed || $0.status == .skipped }
    }

    func chooseFiles() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK {
            addFiles(panel.urls)
        }
    }

    func chooseOutputFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        if panel.runModal() == .OK {
            outputFolder = panel.url
        }
    }

    func processQueue() {
        guard !isProcessing else { return }
        isProcessing = true

        Task {
            let target = targetMegabytes
            let destination = outputFolder
            let ids = items
                .filter { $0.status == .pending || isRetryable($0.status) }
                .map(\.id)
            let workerLimit = CompressionPlanner.workerLimit()

            for batch in ids.chunked(into: workerLimit) {
                await withTaskGroup(of: (UUID, CompressionResult).self) { group in
                    for id in batch {
                        guard let item = self.items.first(where: { $0.id == id }) else { continue }
                        self.update(id: id, status: .compressing, progress: 0)
                        let sourceURL = item.sourceURL

                        group.addTask {
                            let result = await self.service.compress(
                                sourceURL: sourceURL,
                                targetMegabytes: target,
                                destinationFolder: destination
                            ) { progress in
                                Task { @MainActor in
                                    self.update(id: id, progress: progress)
                                }
                            }
                            return (id, result)
                        }
                    }

                    for await (id, result) in group {
                        self.apply(result, to: id)
                    }
                }
            }

            isProcessing = false
        }
    }

    private func apply(_ result: CompressionResult, to id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].status = result.status
        items[index].outputURL = result.outputURL
        items[index].finalBytes = result.finalBytes
        items[index].progress = 1
    }

    private func update(id: UUID, status: CompressionStatus? = nil, progress: Double? = nil) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        if let status {
            items[index].status = status
        }
        if let progress {
            items[index].progress = progress
        }
    }

    private func isRetryable(_ status: CompressionStatus) -> Bool {
        if case .failed = status {
            return true
        }
        return false
    }

    private func fileSize(_ url: URL) -> Int64 {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return (attributes?[.size] as? NSNumber)?.int64Value ?? 0
    }
}

struct QueuedPDF: Identifiable, Equatable {
    let id = UUID()
    let sourceURL: URL
    let originalBytes: Int64
    var finalBytes: Int64?
    var outputURL: URL?
    var status: CompressionStatus = .pending
    var progress: Double = 0
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
