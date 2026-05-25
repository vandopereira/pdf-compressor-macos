import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var store = CompressionQueueStore()
    @State private var isDropTargeted = false

    var body: some View {
        NavigationSplitView {
            ControlPanelView(store: store)
                .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 340)
        } detail: {
            FileQueueView(store: store)
                .overlay {
                    if store.items.isEmpty {
                        emptyState
                    }
                }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers)
        }
        .overlay(alignment: .center) {
            Group {
                if isDropTargeted {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: 3)
                        .padding(12)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 54, weight: .light))
                .foregroundStyle(.secondary)
            Text("Drop PDFs here")
                .font(.title2.weight(.semibold))
            Text("Choose a target size, add one or many files, then compress.")
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding()
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil)
                else { return }
                Task { @MainActor in
                    store.addFiles([url])
                }
            }
        }
        return true
    }
}
