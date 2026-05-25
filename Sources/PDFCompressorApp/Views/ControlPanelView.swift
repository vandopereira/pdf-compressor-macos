import PDFCompressorCore
import SwiftUI

struct ControlPanelView: View {
    let store: CompressionQueueStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Target")
                    .font(.headline)
                HStack(alignment: .firstTextBaseline) {
                    TextField("MB", value: Bindable(store).targetMegabytes, format: .number.precision(.fractionLength(1)))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 84)
                    Text("MB")
                        .foregroundStyle(.secondary)
                }
                Stepper("Adjust target", value: Bindable(store).targetMegabytes, in: 0.5...500, step: 0.5)
                    .labelsHidden()
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Files")
                    .font(.headline)

                Button {
                    store.chooseFiles()
                } label: {
                    Label("Add PDFs", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)

                Button {
                    store.chooseOutputFolder()
                } label: {
                    Label("Destination", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }

                Text(store.outputFolder?.path(percentEncoded: false) ?? "Saving beside each original")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                SummaryRow(title: "Queued", value: "\(store.items.count)")
                SummaryRow(title: "Done", value: "\(store.completedCount)")
                SummaryRow(title: "Original", value: FileSizeFormatter.megabytesString(bytes: store.totalOriginalBytes))
                SummaryRow(title: "Current", value: FileSizeFormatter.megabytesString(bytes: store.totalFinalBytes))
            }

            Spacer()

            Button {
                store.processQueue()
            } label: {
                Label(store.isProcessing ? "Compressing" : "Compress", systemImage: "arrow.down.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!store.canCompress)

            Button("Clear Finished") {
                store.clearFinished()
            }
            .disabled(store.isProcessing)
        }
        .padding(18)
    }
}

private struct SummaryRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.callout)
    }
}
