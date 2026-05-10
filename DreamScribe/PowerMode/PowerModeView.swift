import SwiftUI
import SwiftData

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .center,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

enum ConfigurationMode: Hashable {
    case add
    case edit(PowerModeConfig)
    
    var isAdding: Bool {
        if case .add = self { return true }
        return false
    }
    
    var title: String {
        switch self {
        case .add: return "Add Power Mode"
        case .edit: return "Edit Power Mode"
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .add:
            hasher.combine(0)
        case .edit(let config):
            hasher.combine(1)
            hasher.combine(config.id)
        }
    }
    
    static func == (lhs: ConfigurationMode, rhs: ConfigurationMode) -> Bool {
        switch (lhs, rhs) {
        case (.add, .add):
            return true
        case (.edit(let lhsConfig), .edit(let rhsConfig)):
            return lhsConfig.id == rhsConfig.id
        default:
            return false
        }
    }
}

enum ConfigurationType {
    case application
    case website
}

let commonEmojis = ["🏢", "🏠", "💼", "🎮", "📱", "📺", "🎵", "📚", "✏️", "🎨", "🧠", "⚙️", "💻", "🌐", "📝", "📊", "🔍", "💬", "📈", "🔧"]

struct PowerModeView: View {
    @StateObject private var powerModeManager = PowerModeManager.shared
    @EnvironmentObject private var enhancementService: AIEnhancementService
    @EnvironmentObject private var aiService: AIService
    @State private var configurationMode: ConfigurationMode?
    @State private var isPanelOpen = false
    @State private var panelID = UUID()
    @State private var isReorderPanelOpen = false
    
    var body: some View {
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 8) {
                                DreamersSectionHeader(
                                    label: "Automation",
                                    title: "Power Modes",
                                    subtitle: "Automate your workflows with context-aware configurations."
                                )

                                InfoTip(
                                    "Automatically apply custom configurations based on the app/website you are using.",
                                    learnMoreURL: "https://tryvoiceink.com/docs/power-mode"
                                )
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Button(action: {
                                openPanel(mode: .add)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .medium))
                                    Text("Add Power Mode")
                                        .font(.system(size: 13, weight: .medium))
                                }
                            }
                            .buttonStyle(PrismButtonStyle())

                            Button(action: { openReorderPanel() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.up.arrow.down")
                                        .font(.system(size: 12, weight: .medium))
                                    Text("Reorder")
                                        .font(.system(size: 13, weight: .medium))
                                }
                            }
                            .buttonStyle(ChromeIconButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity)
                .background(DreamersTheme.ColorToken.softInk.opacity(0.16))
                
                // Content Section
                Group {
                        GeometryReader { geometry in
                            ScrollView {
                                VStack(spacing: 0) {
                                    if powerModeManager.configurations.isEmpty {
                                        VStack(spacing: 24) {
                                            Spacer()
                                                .frame(height: geometry.size.height * 0.2)
                                            
                                            ChromePanel {
                                                VStack(spacing: 16) {
                                                    Image(systemName: "square.grid.2x2.fill")
                                                        .font(.system(size: 48, weight: .regular))
                                                        .foregroundStyle(DreamersTheme.ColorToken.starWhite.opacity(0.66))

                                                    VStack(spacing: 8) {
                                                        Text("No Power Modes Yet")
                                                            .font(.system(size: 20, weight: .medium))
                                                            .foregroundStyle(DreamersTheme.ColorToken.starWhite)

                                                        Text("Create first power mode to automate your DreamScribe workflow based on apps/website you are using")
                                                            .font(.system(size: 14))
                                                            .foregroundStyle(DreamersTheme.ColorToken.starWhite.opacity(0.70))
                                                            .multilineTextAlignment(.center)
                                                            .lineSpacing(2)
                                                    }
                                                }
                                                .padding(28)
                                            }
                                            .frame(maxWidth: 440)
                                            
                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(minHeight: geometry.size.height)
                                    } else {
                                        VStack(spacing: 0) {
                                            PowerModeConfigurationsGrid(
                                                powerModeManager: powerModeManager,
                                                onEditConfig: { config in
                                                    openPanel(mode: .edit(config))
                                                }
                                            )
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 20)
                                            
                                            Spacer()
                                                .frame(height: 40)
                                        }
                                    }
                                }
                            }
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)
            }
            .background(DreamersAtmosphere().ignoresSafeArea())
            .slidingPanel(isPresented: .init(
                get: { isPanelOpen },
                set: { if !$0 { closePanel() } }
            ), width: 400) {
                if let mode = configurationMode {
                    ConfigurationView(mode: mode, powerModeManager: powerModeManager, onDismiss: closePanel)
                        .id(panelID)
                }
            }
            .slidingPanel(isPresented: .init(
                get: { isReorderPanelOpen },
                set: { if !$0 { closeReorderPanel() } }
            ), width: 400) {
                ReorderPanelView(powerModeManager: powerModeManager, onDismiss: closeReorderPanel)
            }
    }

    private func openPanel(mode: ConfigurationMode) {
        configurationMode = mode
        panelID = UUID()
        withAnimation(.smooth(duration: 0.3)) {
            isPanelOpen = true
        }
    }

    private func closePanel() {
        withAnimation(.smooth(duration: 0.3)) {
            isPanelOpen = false
            configurationMode = nil
        }
    }

    private func openReorderPanel() {
        withAnimation(.smooth(duration: 0.3)) {
            isReorderPanelOpen = true
        }
    }

    private func closeReorderPanel() {
        withAnimation(.smooth(duration: 0.3)) {
            isReorderPanelOpen = false
        }
    }
}

struct ReorderPanelView: View {
    @ObservedObject var powerModeManager: PowerModeManager
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Text("Reorder Power Modes")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(DreamersTheme.ColorToken.starWhite)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(ChromeIconButtonStyle())
                .help("Close")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(DreamersTheme.ColorToken.softInk.opacity(0.22))
            .overlay(Divider().overlay(DreamersTheme.ColorToken.starWhite.opacity(0.18)), alignment: .bottom)

            // Reorder list
            List {
                ForEach(powerModeManager.configurations) { config in
                    HStack(spacing: 12) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        ZStack {
                            Circle()
                                .fill(Color(NSColor.controlBackgroundColor))
                                .frame(width: 36, height: 36)
                            Text(config.emoji)
                                .font(.system(size: 18))
                        }

                        Text(config.name)
                            .font(.system(size: 14, weight: .medium))

                        Spacer()

                        HStack(spacing: 6) {
                            if config.isDefault {
                                Text("Default")
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.accentColor))
                                    .foregroundColor(.white)
                            }
                            if !config.isEnabled {
                                Text("Disabled")
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color(NSColor.controlBackgroundColor)))
                                    .overlay(
                                        Capsule().stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                                    )
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .onMove(perform: powerModeManager.moveConfigurations)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .padding(.top, 8)
        }
        .background(DreamersTheme.ColorToken.softInk.opacity(0.92))
    }
}


struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .bold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8)
    }
}
