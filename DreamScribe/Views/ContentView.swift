import SwiftUI
import SwiftData
import KeyboardShortcuts
import OSLog

// ViewType enum with all cases
enum ViewType: String, CaseIterable, Identifiable {
    case metrics = "Dashboard"
    case transcribeAudio = "Transcribe Audio"
    case history = "History"
    case models = "AI Models"
    case enhancement = "Enhancement"
    case powerMode = "Power Mode"
    case permissions = "Permissions"
    case audioInput = "Audio Input"
    case dictionary = "Dictionary"
    case settings = "Settings"
    #if !LOCAL_BUILD
    case license = "VoiceInk Pro"
    #endif

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .metrics: return "gauge.medium"
        case .transcribeAudio: return "waveform.circle.fill"
        case .history: return "doc.text.fill"
        case .models: return "brain.head.profile"
        case .enhancement: return "wand.and.stars"
        case .powerMode: return "sparkles.square.fill.on.square"
        case .permissions: return "shield.fill"
        case .audioInput: return "mic.fill"
        case .dictionary: return "character.book.closed.fill"
        case .settings: return "gearshape.fill"
        #if !LOCAL_BUILD
        case .license: return "checkmark.seal.fill"
        #endif
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }

    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

struct ContentView: View {
    private let logger = Logger(subsystem: "co.dreamersmedia.dreamscribe", category: "ContentView")
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var engine: DreamScribeEngine
    @EnvironmentObject private var whisperModelManager: WhisperModelManager
    @EnvironmentObject private var transcriptionModelManager: TranscriptionModelManager
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @AppStorage("powerModeUIFlag") private var powerModeUIFlag = false
    @State private var selectedView: ViewType? = .metrics
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    @StateObject private var licenseViewModel = LicenseViewModel()

    private var visibleViewTypes: [ViewType] {
        ViewType.allCases.filter { viewType in
            if viewType == .powerMode {
                return powerModeUIFlag
            }
            return true
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationTitle("DREAMScribe")
                .navigationSplitViewColumnWidth(230)
        } detail: {
            if let selectedView = selectedView {
                detailView(for: selectedView)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DreamersAtmosphere().ignoresSafeArea())
                    .navigationTitle(selectedView.rawValue)
            } else {
                ChromePanel {
                    VStack(spacing: 10) {
                        Image(systemName: "sidebar.leading")
                            .font(.system(size: 28, weight: .light))
                        Text("Select a view")
                            .font(.headline)
                    }
                    .foregroundStyle(DreamersTheme.ColorToken.starWhite.opacity(0.78))
                    .padding(28)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DreamersAtmosphere().ignoresSafeArea())
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(width: 950)
        .frame(minHeight: 730)
        .tint(DreamersTheme.ColorToken.auroraCyan)
        .onAppear {
            logger.notice("ContentView appeared")
        }
        .onDisappear {
            logger.notice("ContentView disappeared")
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToDestination)) { notification in
            if let destination = notification.userInfo?["destination"] as? String {
                logger.notice("navigateToDestination received: \(destination, privacy: .public)")
                switch destination {
                case "Settings":
                    selectedView = .settings
                case "AI Models":
                    selectedView = .models
                #if !LOCAL_BUILD
                case "VoiceInk Pro":
                    selectedView = .license
                #endif
                case "History":
                    selectedView = .history
                case "Permissions":
                    selectedView = .permissions
                case "Enhancement":
                    selectedView = .enhancement
                case "Transcribe Audio":
                    selectedView = .transcribeAudio
                case "Power Mode":
                    selectedView = .powerMode
                default:
                    break
                }
            }
        }
    }

    private var sidebar: some View {
        ZStack {
            DreamersAtmosphere()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                sidebarHeader
                    .padding(.horizontal, 14)
                    .padding(.top, 16)
                    .padding(.bottom, 14)

                Rectangle()
                    .fill(DreamersTheme.ColorToken.starWhite.opacity(0.14))
                    .frame(height: 1)
                    .padding(.horizontal, 14)

                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(visibleViewTypes) { viewType in
                            Button {
                                selectedView = viewType
                            } label: {
                            SidebarItemView(
                                viewType: viewType,
                                isSelected: selectedView == viewType
                            )
                        }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                }
                .background(Color.clear)

                Rectangle()
                    .fill(DreamersTheme.ColorToken.starWhite.opacity(0.12))
                    .frame(height: 1)
                    .padding(.horizontal, 14)

                DreamersFooterMark()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
        }
    }

    private var sidebarHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            DREAMScribeLockup(scale: .compact, includeSubline: true)

            Spacer(minLength: 8)

            #if !LOCAL_BUILD
            if case .licensed = licenseViewModel.licenseState {
                Text("PRO")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .tracking(0.8)
                    .foregroundStyle(DreamersTheme.ColorToken.softInk)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: DreamersTheme.Radius.small, style: .continuous)
                            .fill(DreamersTheme.prismGradient)
                    )
            }
            #endif
        }
    }
    
    @ViewBuilder
    private func detailView(for viewType: ViewType) -> some View {
        switch viewType {
        case .metrics:
            MetricsView()
        case .models:
            ModelManagementView()
        case .enhancement:
            EnhancementSettingsView()
        case .transcribeAudio:
            AudioTranscribeView()
        case .history:
            InlineHistoryView()
        case .audioInput:
            AudioInputSettingsView()
        case .dictionary:
            DictionarySettingsView(whisperPrompt: whisperModelManager.whisperPrompt)
        case .powerMode:
            PowerModeView()
        case .settings:
            SettingsView()
        #if !LOCAL_BUILD
        case .license:
            LicenseManagementView()
        #endif
        case .permissions:
            PermissionsView()
        }
    }
}

private struct SidebarItemView: View {
    let viewType: ViewType
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: viewType.icon)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 20, height: 20)
                .foregroundStyle(isSelected ? DreamersTheme.ColorToken.auroraCyan : DreamersTheme.ColorToken.starWhite.opacity(0.72))

            Text(viewType.rawValue)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? DreamersTheme.ColorToken.starWhite : DreamersTheme.ColorToken.starWhite.opacity(0.82))
                .lineLimit(1)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .padding(.vertical, 7)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: DreamersTheme.Radius.control, style: .continuous)
                .fill(isSelected ? AnyShapeStyle(DreamersTheme.selectedPanelFill) : AnyShapeStyle(Color.clear))
        )
        .overlay(alignment: .leading) {
            if isSelected {
                Capsule()
                    .fill(DreamersTheme.prismGradient)
                    .frame(width: 3, height: 20)
            }
        }
    }
}
