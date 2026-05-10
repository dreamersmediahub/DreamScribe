import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct AudioTranscribeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var engine: DreamScribeEngine
    @EnvironmentObject private var enhancementService: AIEnhancementService
    @StateObject private var transcriptionManager = AudioTranscriptionManager.shared
    @State private var isDropTargeted = false
    @State private var isEnhancementEnabled = false
    @State private var selectedPromptId: UUID?
    @State private var expandedItemId: UUID?

    var body: some View {
        Group {
            if transcriptionManager.queue.isEmpty {
                emptyStateView
            } else {
                queueFormView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DreamersAtmosphere().ignoresSafeArea())
        .onDrop(of: [.fileURL, .data, .audio, .movie], isTargeted: $isDropTargeted) { providers in
            handleDroppedFiles(providers)
            return true
        }
        .overlay {
            if isDropTargeted && !transcriptionManager.queue.isEmpty {
                dropOverlay
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFileForTranscription)) { notification in
            if let url = notification.userInfo?["url"] as? URL {
                transcriptionManager.addToQueue(urls: [url])
            }
        }
        .onChange(of: transcriptionManager.lastCompletedItemId) { _, newId in
            if let newId {
                withAnimation(.easeInOut(duration: 0.3)) {
                    expandedItemId = newId
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 0) {
            Spacer()

            ChromePanel(isSelected: isDropTargeted) {
                VStack(spacing: 14) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 32))
                        .foregroundStyle(isDropTargeted ? DreamersTheme.accentText(for: colorScheme) : DreamersTheme.secondaryText(for: colorScheme))

                    Text("Drop audio or video files here")
                        .font(.headline)
                        .foregroundStyle(DreamersTheme.primaryText(for: colorScheme))

                    Text("or")
                        .foregroundStyle(DreamersTheme.tertiaryText(for: colorScheme))

                    Button("Choose Files") {
                        selectFiles()
                    }
                    .buttonStyle(PrismButtonStyle())
                }
                .padding(32)
            }
            .overlay(
                RoundedRectangle(cornerRadius: DreamersTheme.Radius.panel, style: .continuous)
                    .strokeBorder(
                        isDropTargeted ? DreamersTheme.accentText(for: colorScheme).opacity(0.85) : DreamersTheme.secondaryText(for: colorScheme).opacity(0.34),
                        style: StrokeStyle(lineWidth: 1.4, dash: [8])
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: isDropTargeted)
            .frame(maxWidth: 480, maxHeight: 200)

            Text("Supports WAV, MP3, M4A, AIFF, MP4, MOV, AAC, FLAC, CAF, AMR, OGG, OPUS, 3GP")
                .font(.caption)
                .foregroundStyle(DreamersTheme.tertiaryText(for: colorScheme))
                .padding(.top, 12)

            Spacer()
        }
        .padding()
    }

    // MARK: - Queue Form View

    private var queueFormView: some View {
        VStack(spacing: 0) {
            topBar
            Divider()
                .overlay(DreamersTheme.panelStroke(for: colorScheme))

            Form {
                ForEach(transcriptionManager.queue) { item in
                    Section {
                        AudioFileRow(
                            item: item,
                            isExpanded: expandedItemId == item.id,
                            onToggleExpand: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    expandedItemId = expandedItemId == item.id ? nil : item.id
                                }
                            },
                            onRemove: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    transcriptionManager.removeFromQueue(id: item.id)
                                    if expandedItemId == item.id { expandedItemId = nil }
                                }
                            },
                            onRetry: {
                                transcriptionManager.retryItem(id: item.id)
                                if !transcriptionManager.isProcessingQueue {
                                    transcriptionManager.startProcessing(modelContext: modelContext, engine: engine)
                                }
                            }
                        )
                    }
                }
            }
            .formStyle(.grouped)
            .dreamersFormChrome()
            .safeAreaInset(edge: .bottom) {
                Text("Drop files anywhere to add more")
                    .font(.caption)
                    .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 10) {
            Text("\(transcriptionManager.queue.count) file\(transcriptionManager.queue.count == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))

            Button {
                selectFiles()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                    Text("Add")
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .buttonStyle(ChromeIconButtonStyle())
            .help("Add files")

            Spacer()

            enhancementControls

            if transcriptionManager.isProcessingQueue {
                Button {
                    transcriptionManager.cancelProcessing()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 10, weight: .medium))
                        Text("Cancel")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(DreamersTheme.danger(for: colorScheme))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: DreamersTheme.Radius.control, style: .continuous)
                            .fill(DreamersTheme.danger(for: colorScheme).opacity(0.14))
                    )
                }
                .buttonStyle(.plain)
                .help("Cancel transcription")
            } else if transcriptionManager.hasPendingItems {
                Button {
                    transcriptionManager.startProcessing(modelContext: modelContext, engine: engine)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10, weight: .medium))
                        Text("Start")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .buttonStyle(PrismButtonStyle())
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    transcriptionManager.clearAll()
                    expandedItemId = nil
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.bin")
                        .font(.system(size: 12, weight: .medium))
                    Text("Clear")
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .buttonStyle(ChromeIconButtonStyle())
            .help("Clear all items")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(DreamersTheme.panelFill(for: colorScheme))
    }

    private var enhancementControls: some View {
        HStack(spacing: 8) {
            Toggle("AI Enhancement", isOn: $isEnhancementEnabled)
                .toggleStyle(.switch)
                .controlSize(.small)
                .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
                .tint(DreamersTheme.accentText(for: colorScheme))
                .onChange(of: isEnhancementEnabled) { _, newValue in
                    enhancementService.isEnhancementEnabled = newValue
                }

            if isEnhancementEnabled && !enhancementService.allPrompts.isEmpty {
                Divider().frame(height: 16)

                let promptBinding = Binding<UUID>(
                    get: {
                        selectedPromptId ?? enhancementService.allPrompts.first?.id ?? UUID()
                    },
                    set: { newValue in
                        selectedPromptId = newValue
                        enhancementService.selectedPromptId = newValue
                    }
                )

                Picker("Prompt", selection: promptBinding) {
                    ForEach(enhancementService.allPrompts) { prompt in
                        Text(prompt.title).tag(prompt.id)
                    }
                }
                .labelsHidden()
                .fixedSize()
                .tint(DreamersTheme.accentText(for: colorScheme))
            }
        }
        .onAppear {
            isEnhancementEnabled = enhancementService.isEnhancementEnabled
            selectedPromptId = enhancementService.selectedPromptId
        }
    }

    // MARK: - Drop Overlay

    private var dropOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(DreamersTheme.ColorToken.auroraCyan, style: StrokeStyle(lineWidth: 2, dash: [8]))
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(DreamersTheme.ColorToken.auroraCyan.opacity(0.08))
            )
            .overlay {
                Text("Drop to add files")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DreamersTheme.ColorToken.auroraCyan)
            }
            .padding(16)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.15), value: isDropTargeted)
    }

    // MARK: - File Handling

    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.audio, .movie]

        if panel.runModal() == .OK {
            transcriptionManager.addToQueue(urls: panel.urls)
        }
    }

    private func handleDroppedFiles(_ providers: [NSItemProvider]) {
        let typeIdentifiers = [
            UTType.fileURL.identifier,
            UTType.audio.identifier,
            UTType.movie.identifier,
            UTType.data.identifier,
            "public.file-url"
        ]

        for provider in providers {
            for typeIdentifier in typeIdentifiers {
                if provider.hasItemConformingToTypeIdentifier(typeIdentifier) {
                    provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, error in
                        if let error = error {
                            print("Error loading dropped file: \(error)")
                            return
                        }

                        var fileURL: URL?

                        if let url = item as? URL {
                            fileURL = url
                        } else if let data = item as? Data {
                            if let url = URL(dataRepresentation: data, relativeTo: nil) {
                                fileURL = url
                            } else if let urlString = String(data: data, encoding: .utf8),
                                      let url = URL(string: urlString) {
                                fileURL = url
                            }
                        } else if let urlString = item as? String {
                            fileURL = URL(string: urlString)
                        }

                        if let finalURL = fileURL {
                            DispatchQueue.main.async {
                                self.transcriptionManager.addToQueue(urls: [finalURL])
                            }
                        }
                    }
                    break
                }
            }
        }
    }
}
