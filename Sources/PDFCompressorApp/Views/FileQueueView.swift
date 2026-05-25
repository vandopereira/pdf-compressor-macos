import PDFCompressorCore
import SwiftUI

struct FileQueueView: View {
    let store: CompressionQueueStore

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("PDF Queue")
                    .font(.title2.weight(.semibold))
                Spacer()
                Text("\(CompressionPlanner.workerLimit()) workers")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding([.horizontal, .top], 20)
            .padding(.bottom, 12)

            Table(store.items) {
                TableColumn("File") { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.sourceURL.lastPathComponent)
                            .lineLimit(1)
                        Text(item.sourceURL.deletingLastPathComponent().path(percentEncoded: false))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                TableColumn("Original") { item in
                    Text(FileSizeFormatter.megabytesString(bytes: item.originalBytes))
                }
                .width(90)

                TableColumn("Result") { item in
                    Text(resultText(for: item))
                }
                .width(90)

                TableColumn("Status") { item in
                    StatusView(item: item)
                }
                .width(170)

                TableColumn("") { item in
                    Button {
                        store.remove(item)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .disabled(store.isProcessing)
                    .help("Remove")
                }
                .width(42)
            }
        }
    }

    private func resultText(for item: QueuedPDF) -> String {
        guard let finalBytes = item.finalBytes else {
            return "-"
        }
        return FileSizeFormatter.megabytesString(bytes: finalBytes)
    }
}

private struct StatusView: View {
    let item: QueuedPDF

    var body: some View {
        switch item.status {
        case .pending:
            Label("Pending", systemImage: "clock")
                .foregroundStyle(.secondary)
        case .skipped:
            Label("Skipped", systemImage: "checkmark.circle")
                .foregroundStyle(.green)
        case .compressing:
            HStack {
                ProgressView(value: item.progress)
                    .frame(width: 72)
                Text("\(Int(item.progress * 100))%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        case .completed:
            Label("Compressed", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
                .lineLimit(1)
        }
    }
}
