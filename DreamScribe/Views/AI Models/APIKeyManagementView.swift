import SwiftUI
import LLMkit

struct APIKeyManagementView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var aiService: AIService
    @State private var apiKey: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isVerifying = false
    @State private var ollamaBaseURL: String = UserDefaults.standard.string(forKey: "ollamaBaseURL") ?? "http://localhost:11434"
    @State private var ollamaModels: [OllamaModel] = []
    @State private var selectedOllamaModel: String = UserDefaults.standard.string(forKey: "ollamaSelectedModel") ?? "mistral"
    @State private var isCheckingOllama = false
    @State private var isEditingURL = false
    @State private var localCLICommandTemplate: String = ""
    @State private var localCLITimeoutSeconds: Double = LocalCLIService.defaultTimeoutSeconds
    @State private var isSyncingLocalCLIState = false
    @State private var isTestingLocalCLI = false
    @State private var localCLITestMessage: String?
    @State private var localCLITestSucceeded: Bool?
    
    var body: some View {
        Section("AI Provider Integration") {
            HStack {
                Picker("Provider", selection: $aiService.selectedProvider) {
                    ForEach(AIProvider.allCases.filter { $0 != .elevenLabs && $0 != .deepgram && $0 != .soniox && $0 != .speechmatics && $0 != .assemblyAI }, id: \.self) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .pickerStyle(.automatic)
                .tint(DreamersTheme.accentText(for: colorScheme))
                
                if aiService.selectedProvider == .localCLI {
                    Spacer()
                    Circle()
                        .fill(aiService.isAPIKeyValid ? DreamersTheme.success(for: colorScheme) : DreamersTheme.warning(for: colorScheme))
                        .frame(width: 8, height: 8)
                    Text(aiService.isAPIKeyValid ? "Configured" : "Not configured")
                        .font(.subheadline)
                        .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
                } else if aiService.isAPIKeyValid && aiService.selectedProvider != .ollama {
                    Spacer()
                    Circle()
                        .fill(DreamersTheme.success(for: colorScheme))
                        .frame(width: 8, height: 8)
                    Text("Connected")
                        .font(.subheadline)
                        .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
                } else if aiService.selectedProvider == .ollama {
                    Spacer()
                    if isCheckingOllama {
                        ProgressView()
                            .controlSize(.small)
                    } else if !ollamaModels.isEmpty {
                        Circle()
                            .fill(DreamersTheme.success(for: colorScheme))
                            .frame(width: 8, height: 8)
                        Text("Connected")
                            .font(.subheadline)
                            .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
                    } else {
                        Circle()
                            .fill(DreamersTheme.danger(for: colorScheme))
                            .frame(width: 8, height: 8)
                        Text("Disconnected")
                            .font(.subheadline)
                            .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
                    }
                }
            }
            .onChange(of: aiService.selectedProvider) { oldValue, newValue in
                if aiService.selectedProvider == .ollama {
                    checkOllamaConnection()
                }
                if aiService.selectedProvider == .localCLI {
                    syncLocalCLIStateFromService()
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                // Model Selection
                if aiService.selectedProvider == .openRouter {
                    if aiService.availableModels.isEmpty {
                        HStack {
                            Text("No models loaded")
                                .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
                            Spacer()
                            Button(action: {
                                Task {
                                    await aiService.fetchOpenRouterModels()
                                }
                            }) {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                        }
                    } else {
                        HStack {
                            Picker("Model", selection: Binding(
                                get: { aiService.currentModel },
                                set: { aiService.selectModel($0) }
                            )) {
                                ForEach(aiService.availableModels, id: \.self) { model in
                                    Text(model).tag(model)
                                }
                            }

                            Spacer()

                            Button(action: {
                                Task {
                                    await aiService.fetchOpenRouterModels()
                                }
                            }) {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                        }
                    }
                    
                } else if !aiService.availableModels.isEmpty &&
                            aiService.selectedProvider != .ollama &&
                            aiService.selectedProvider != .custom {
                    Picker("Model", selection: Binding(
                        get: { aiService.currentModel },
                        set: { aiService.selectModel($0) }
                    )) {
                        ForEach(aiService.availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                }

                if aiService.selectedProvider == .ollama {
                    if isEditingURL {
                        HStack {
                            TextField("Base URL", text: $ollamaBaseURL)
                                .dreamersInputChrome()
                            
                            Button("Save") {
                                aiService.updateOllamaBaseURL(ollamaBaseURL)
                                checkOllamaConnection()
                                isEditingURL = false
                            }
                        }
                    } else {
                        HStack {
                            Text("Server: \(ollamaBaseURL)")
                            Spacer()
                            Button("Edit") { isEditingURL = true }
                            Button(action: {
                                ollamaBaseURL = "http://localhost:11434"
                                aiService.updateOllamaBaseURL(ollamaBaseURL)
                                checkOllamaConnection()
                            }) {
                                Image(systemName: "arrow.counterclockwise")
                            }
                            .help("Reset to default")
                        }
                    }

                    if !ollamaModels.isEmpty {
                        Divider()

                        Picker("Model", selection: $selectedOllamaModel) {
                            ForEach(ollamaModels) { model in
                                Text(model.name).tag(model.name)
                            }
                        }
                        .onChange(of: selectedOllamaModel) { oldValue, newValue in
                            aiService.updateSelectedOllamaModel(newValue)
                        }
                    }

                } else if aiService.selectedProvider == .localCLI {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Label(aiService.localCLIDisplayName, systemImage: "terminal.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(DreamersTheme.primaryText(for: colorScheme))

                            Spacer()

                            Button {
                                runLocalCLITest()
                            } label: {
                                HStack(spacing: 6) {
                                    if isTestingLocalCLI {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Image(systemName: "checkmark.seal.fill")
                                    }
                                    Text(isTestingLocalCLI ? "Testing" : "Test CLI")
                                }
                            }
                            .disabled(isTestingLocalCLI || localCLICommandTemplate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                            Menu("Load Template") {
                                ForEach(LocalCLITemplate.allCases) { template in
                                    Button(template.displayName) {
                                        aiService.loadLocalCLITemplate(template)
                                        syncLocalCLIStateFromService()
                                        localCLITestMessage = nil
                                        localCLITestSucceeded = nil
                                    }
                                }
                            }
                        }

                        HStack {
                            Text("Command")
                                .font(.subheadline)
                                .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
                            Spacer()
                        }

                        TextEditor(text: $localCLICommandTemplate)
                            .font(.system(.body, design: .monospaced))
                            .multilineTextAlignment(.leading)
                            .frame(minHeight: 100)
                            .padding(4)
                            .scrollContentBackground(.hidden)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(DreamersTheme.panelFill(for: colorScheme))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(DreamersTheme.panelStroke(for: colorScheme), lineWidth: 1)
                            )
                            .foregroundStyle(DreamersTheme.primaryText(for: colorScheme))
                            .onChange(of: localCLICommandTemplate) { _, newValue in
                                guard !isSyncingLocalCLIState else { return }
                                if newValue != aiService.localCLICommandTemplate {
                                    aiService.updateLocalCLICommandTemplate(newValue)
                                    localCLITestMessage = nil
                                    localCLITestSucceeded = nil
                                }
                            }
                    }

                    Picker("Timeout", selection: $localCLITimeoutSeconds) {
                        Text("15s").tag(15.0)
                        Text("30s").tag(30.0)
                        Text("45s").tag(45.0)
                        Text("60s").tag(60.0)
                        Text("90s").tag(90.0)
                        Text("120s").tag(120.0)
                        Text("180s").tag(180.0)
                        Text("300s").tag(300.0)
                    }
                    .onChange(of: localCLITimeoutSeconds) { _, newValue in
                        aiService.updateLocalCLITimeoutSeconds(newValue)
                    }

                    Text("Environment variables available: DREAMSCRIBE_SYSTEM_PROMPT, DREAMSCRIBE_USER_PROMPT, DREAMSCRIBE_FULL_PROMPT. DreamScribe also writes DREAMSCRIBE_FULL_PROMPT to stdin. Legacy VOICEINK_* names still work for saved commands.")
                        .font(.caption)
                        .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))

                    if let localCLITestMessage {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: localCLITestSucceeded == true ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(localCLITestSucceeded == true ? DreamersTheme.success(for: colorScheme) : DreamersTheme.warning(for: colorScheme))
                            Text(localCLITestMessage)
                                .font(.caption)
                                .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
                        }
                    }

                    if !aiService.isAPIKeyValid {
                        Text("Load a template or enter a command to enable Local CLI enhancement.")
                            .font(.caption)
                            .foregroundStyle(DreamersTheme.warning(for: colorScheme))
                    }

                } else if aiService.selectedProvider == .custom {
                    TextField("API Endpoint URL", text: $aiService.customBaseURL, prompt: Text("e.g. https://api.openai.com/v1/chat/completions"))
                        .dreamersInputChrome()

                    Divider()

                    TextField("Model Name", text: $aiService.customModel, prompt: Text("e.g. gemini-3.1-pro-preview, gpt-5.5"))
                        .dreamersInputChrome()

                    Divider()

                    if aiService.isAPIKeyValid {
                        HStack {
                            Text("API Key Set")
                            Spacer()
                            Button("Remove Key", role: .destructive) {
                                aiService.clearAPIKey()
                            }
                        }
                    } else {
                        SecureField("API Key", text: $apiKey)
                            .dreamersInputChrome()

                        Button("Verify and Save") {
                            isVerifying = true
                            aiService.saveAPIKey(apiKey) { success, errorMessage in
                                isVerifying = false
                                if !success {
                                    alertMessage = errorMessage ?? "Verification failed"
                                    showAlert = true
                                }
                                apiKey = ""
                            }
                        }
                        .disabled(aiService.customBaseURL.isEmpty || aiService.customModel.isEmpty || apiKey.isEmpty)
                    }
                    
                } else {
                    if aiService.isAPIKeyValid {
                        HStack {
                            Text("API Key")
                            Spacer()
                            Text("••••••••")
                                .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
                            Button("Remove", role: .destructive) {
                                aiService.clearAPIKey()
                            }
                        }
                    } else {
                        SecureField("API Key", text: $apiKey)
                            .dreamersInputChrome()

                        HStack {
                            if let url = getAPIKeyURL() {
                                Link(destination: url) {
                                    HStack {
                                        Image(systemName: "key.fill")
                                        Text("Get API Key")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(DreamersTheme.accentText(for: colorScheme))
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(DreamersTheme.accentText(for: colorScheme).opacity(0.12))
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }

                            Spacer()

                            Button(action: {
                                isVerifying = true
                                aiService.saveAPIKey(apiKey) { success, errorMessage in
                                    isVerifying = false
                                    if !success {
                                        alertMessage = errorMessage ?? "Verification failed"
                                        showAlert = true
                                    }
                                    apiKey = ""
                                }
                            }) {
                                HStack {
                                    if isVerifying {
                                        ProgressView().controlSize(.small)
                                    }
                                    Text("Verify and Save")
                                }
                            }
                            .disabled(apiKey.isEmpty)
                        }
                    }
                }
            }
        }
        .listRowBackground(DreamersTheme.panelFill(for: colorScheme))
        .listRowSeparatorTint(DreamersTheme.accentText(for: colorScheme).opacity(0.26))
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            if aiService.selectedProvider == .ollama {
                checkOllamaConnection()
            }
            if aiService.selectedProvider == .localCLI {
                syncLocalCLIStateFromService()
            }
        }
    }

    private func syncLocalCLIStateFromService() {
        isSyncingLocalCLIState = true
        localCLICommandTemplate = aiService.localCLICommandTemplate
        localCLITimeoutSeconds = aiService.localCLITimeoutSeconds
        DispatchQueue.main.async {
            isSyncingLocalCLIState = false
        }
    }

    private func runLocalCLITest() {
        isTestingLocalCLI = true
        localCLITestMessage = nil
        localCLITestSucceeded = nil

        Task {
            let result = await aiService.testLocalCLIConfiguration()
            await MainActor.run {
                switch result {
                case .success(let output):
                    localCLITestSucceeded = true
                    localCLITestMessage = "Local CLI responded: \(output)"
                case .failure(let error):
                    localCLITestSucceeded = false
                    localCLITestMessage = error
                }
                isTestingLocalCLI = false
            }
        }
    }
    
    private func checkOllamaConnection() {
        isCheckingOllama = true
        aiService.checkOllamaConnection { connected in
            if connected {
                Task {
                    ollamaModels = await aiService.fetchOllamaModels()
                    isCheckingOllama = false
                }
            } else {
                ollamaModels = []
                isCheckingOllama = false
                alertMessage = "Could not connect to Ollama. Please check if Ollama is running and the base URL is correct."
                showAlert = true
            }
        }
    }
    
    private func getAPIKeyURL() -> URL? {
        switch aiService.selectedProvider {
        case .groq: return URL(string: "https://console.groq.com/keys")
        case .openAI: return URL(string: "https://platform.openai.com/api-keys")
        case .gemini: return URL(string: "https://makersuite.google.com/app/apikey")
        case .anthropic: return URL(string: "https://console.anthropic.com/settings/keys")
        case .mistral: return URL(string: "https://console.mistral.ai/api-keys")
        case .elevenLabs: return URL(string: "https://elevenlabs.io/speech-synthesis")
        case .deepgram: return URL(string: "https://console.deepgram.com/api-keys")
        case .soniox: return URL(string: "https://console.soniox.com/")
        case .speechmatics: return URL(string: "https://portal.speechmatics.com/manage-access/")
        case .assemblyAI: return URL(string: "https://www.assemblyai.com/dashboard/api-keys")
        case .openRouter: return URL(string: "https://openrouter.ai/keys")
        case .cerebras: return URL(string: "https://cloud.cerebras.ai/")
        default: return nil
        }
    }
}
