import SwiftUI
import SwiftData
import os

struct MetricsContent: View {
    @Environment(\.colorScheme) private var colorScheme
    private let logger = Logger(subsystem: "co.dreamersmedia.dreamscribe", category: "MetricsContent")
    let modelContext: ModelContext
    let licenseState: LicenseViewModel.LicenseState

    @State private var totalCount: Int = 0
    @State private var totalWords: Int = 0
    @State private var totalDuration: TimeInterval = 0
    @State private var isLoadingMetrics: Bool = true
    @State private var metricsTask: Task<Void, Never>?
    @State private var isModelStatsPanelPresented = false

    var body: some View {
        ZStack {
            DreamersAtmosphere()
                .ignoresSafeArea()

            Group {
                if totalCount == 0 && !isLoadingMetrics {
                    emptyStateView
                } else if isLoadingMetrics {
                    loadingStateView
                } else {
                    GeometryReader { geometry in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                heroSection
                                metricsSection
                                studioNoteSection

                                #if !LOCAL_BUILD
                                HStack(alignment: .top, spacing: 18) {
                                    HelpAndResourcesSection()
                                    DashboardPromotionsSection(licenseState: licenseState)
                                }
                                #endif

                                Spacer(minLength: 16)

                                HStack(alignment: .center) {
                                    DreamersFooterMark()
                                    Spacer()
                                    footerActionsView
                                }
                            }
                            .frame(minHeight: geometry.size.height - 56, alignment: .top)
                            .padding(.vertical, 28)
                            .padding(.horizontal, 32)
                        }
                    }
                }
            }
        }
        .task {
            await loadMetricsEfficiently()
        }
        .onReceive(NotificationCenter.default.publisher(for: .sessionMetricsDidChange)) { _ in
            metricsTask?.cancel()
            metricsTask = Task {
                await loadMetricsEfficiently()
            }
        }
        .onDisappear {
            metricsTask?.cancel()
        }
        .overlay {
            Color.black.opacity(isModelStatsPanelPresented ? 0.1 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(isModelStatsPanelPresented)
                .onTapGesture {
                    withAnimation(.smooth(duration: 0.3)) { isModelStatsPanelPresented = false }
                }
                .animation(.smooth(duration: 0.3), value: isModelStatsPanelPresented)
        }
        .overlay(alignment: .trailing) {
            if isModelStatsPanelPresented {
                ModelPerformancePanel {
                    withAnimation(.smooth(duration: 0.3)) { isModelStatsPanelPresented = false }
                }
                .frame(width: 400)
                .frame(maxHeight: .infinity)
                .background(DreamersTheme.ColorToken.midnightNavy)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(DreamersTheme.prismGradient)
                        .frame(width: 1)
                }
                .shadow(color: DreamersTheme.ColorToken.softInk.opacity(0.32), radius: 18, x: -4, y: 0)
                .ignoresSafeArea()
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.smooth(duration: 0.3), value: isModelStatsPanelPresented)
    }
    
    private func loadMetricsEfficiently() async {
        await MainActor.run {
            self.isLoadingMetrics = true
        }

        let modelContainer = modelContext.container

        let backgroundContext = ModelContext(modelContainer)

        do {
            guard !Task.isCancelled else {
                await MainActor.run {
                    self.isLoadingMetrics = false
                }
                return
            }

            let count = try backgroundContext.fetchCount(FetchDescriptor<SessionMetric>())

            guard !Task.isCancelled else {
                await MainActor.run {
                    self.isLoadingMetrics = false
                }
                return
            }

            var descriptor = FetchDescriptor<SessionMetric>()
            descriptor.propertiesToFetch = [\.wordCount, \.audioDuration]

            var words = 0
            var duration: TimeInterval = 0

            try backgroundContext.enumerate(descriptor) { metric in
                words += metric.wordCount
                duration += metric.audioDuration
            }

            guard !Task.isCancelled else {
                await MainActor.run { self.isLoadingMetrics = false }
                return
            }

            await MainActor.run {
                self.totalCount = count
                self.totalWords = words
                self.totalDuration = duration
                // Stay in loading state if migration is still running and no data yet —
                // sessionMetricsDidChange will trigger a reload when it finishes.
                if count > 0 || !SessionMetricMigrationService.shared.isRunning {
                    self.isLoadingMetrics = false
                }
            }
        } catch {
            logger.error("Error loading metrics: \(error.localizedDescription, privacy: .public)")
            await MainActor.run { self.isLoadingMetrics = false }
        }
    }

    private var emptyStateView: some View {
        ChromePanel {
            VStack(spacing: 18) {
                Image(systemName: "waveform")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(DreamersTheme.ColorToken.auroraCyan)

                DreamersSectionHeader(
                    label: "Studio Metrics",
                    title: "No Recorder Sessions Yet",
                    subtitle: "Start your first recording to unlock DREAMScribe value insights."
                )
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }

    private var loadingStateView: some View {
        ChromePanel {
            HStack(spacing: 12) {
                ProgressView()
                    .controlSize(.small)
                    .tint(DreamersTheme.accentText(for: colorScheme))
                Text("Loading metrics...")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Sections
    
    private var heroSection: some View {
        ChromePanel {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 18) {
                    DREAMScribeLockup(scale: .hero, includeSubline: true)
                        .frame(maxWidth: 400, alignment: .leading)

                    Spacer(minLength: 20)

                    VStack(alignment: .trailing, spacing: 3) {
                        Text("CREATOR STUDIO")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .tracking(1.8)
                            .foregroundStyle(DreamersTheme.labelText(for: colorScheme))
                            .lineLimit(1)
                        Text("\(totalCount) \(totalCount == 1 ? "session" : "sessions")")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
                            .lineLimit(1)
                    }
                }

                Rectangle()
                    .fill(DreamersTheme.prismGradient)
                    .frame(height: 1)
                    .opacity(0.72)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Time saved")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .tracking(1.5)
                        .foregroundStyle(DreamersTheme.tertiaryText(for: colorScheme))

                    Text(formattedTimeSaved)
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(DreamersTheme.primaryText(for: colorScheme))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text(heroSubtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(22)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DreamersSectionHeader(
                label: "Session Intelligence",
                title: "Dashboard",
                subtitle: "Compact studio metrics calculated from local recorder sessions."
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 14)], spacing: 14) {
                MetricCard(
                    icon: "mic.fill",
                    title: "Sessions Recorded",
                    value: "\(totalCount)",
                    detail: "DREAMScribe sessions completed",
                    color: DreamersTheme.ColorToken.violetEdge
                )

                MetricCard(
                    icon: "text.alignleft",
                    title: "Words Dictated",
                    value: Formatters.formattedNumber(totalWords),
                    detail: "words generated",
                    color: DreamersTheme.ColorToken.auroraCyan
                )

                MetricCard(
                    icon: "speedometer",
                    title: "Words Per Minute",
                    value: averageWordsPerMinute > 0
                        ? String(format: "%.1f", averageWordsPerMinute)
                        : "–",
                    detail: "DREAMScribe vs. typing by hand",
                    color: DreamersTheme.ColorToken.lemonFlare
                )

                MetricCard(
                    icon: "keyboard.fill",
                    title: "Keystrokes Saved",
                    value: Formatters.formattedNumber(totalKeystrokesSaved),
                    detail: "fewer keystrokes",
                    color: DreamersTheme.ColorToken.blushPink
                )
            }
        }
    }

    private var studioNoteSection: some View {
        ChromePanel {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(DreamersTheme.prismGradient)
                    .frame(width: 34, height: 34)

                DreamersSectionHeader(
                    label: "Studio Note",
                    title: "Ready for the next take",
                    subtitle: "Your dashboard is tuned for recording velocity today, with room for future Dreamers audio workflows."
                )

                Spacer(minLength: 12)
            }
            .padding(18)
        }
    }

    private var footerActionsView: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation(.smooth(duration: 0.3)) { isModelStatsPanelPresented = true }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "gauge")
                    Text("Model Performance")
                }
            }
            .buttonStyle(PrismButtonStyle())
            .help("View transcription and enhancement model performance")
            CopySystemInfoButton()
        }
    }
    
    private var formattedTimeSaved: String {
        let formatted = Formatters.formattedDuration(timeSaved, style: .full, fallback: "Time savings coming soon")
        return formatted
    }
    
    private var heroSubtitle: String {
        guard totalCount > 0 else {
            return "Your DREAMScribe journey starts with your first recording."
        }

        let wordsText = Formatters.formattedNumber(totalWords)
        let sessionText = totalCount == 1 ? "session" : "sessions"

        return "Dictated \(wordsText) words across \(totalCount) \(sessionText)."
    }
    
    // MARK: - Computed Metrics

    private var estimatedTypingTime: TimeInterval {
        let averageTypingSpeed: Double = 35 // words per minute
        let estimatedTypingTimeInMinutes = Double(totalWords) / averageTypingSpeed
        return estimatedTypingTimeInMinutes * 60
    }

    private var timeSaved: TimeInterval {
        max(estimatedTypingTime - totalDuration, 0)
    }

    private var averageWordsPerMinute: Double {
        guard totalDuration > 0 else { return 0 }
        return Double(totalWords) / (totalDuration / 60.0)
    }

    private var totalKeystrokesSaved: Int {
        Int(Double(totalWords) * 5.0)
    }
    
}

private enum Formatters {
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.maximumUnitCount = 2
        return formatter
    }()
    
    static func formattedNumber(_ value: Int) -> String {
        return numberFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    static func formattedDuration(_ interval: TimeInterval, style: DateComponentsFormatter.UnitsStyle, fallback: String = "–") -> String {
        guard interval > 0 else { return fallback }
        durationFormatter.unitsStyle = style
        durationFormatter.allowedUnits = interval >= 3600 ? [.hour, .minute] : [.minute, .second]
        return durationFormatter.string(from: interval) ?? fallback
    }
}

private struct CopySystemInfoButton: View {
    @State private var isCopied: Bool = false

    var body: some View {
        Button(action: {
            copySystemInfo()
        }) {
            HStack(spacing: 8) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .rotationEffect(.degrees(isCopied ? 360 : 0))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCopied)

                Text(isCopied ? "Copied!" : "Copy System Info")
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCopied)
            }
            .font(.system(size: 13, weight: .medium))
        }
        .buttonStyle(ChromeIconButtonStyle(isSelected: isCopied))
        .scaleEffect(isCopied ? 1.04 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCopied)
    }

    private func copySystemInfo() {
        SystemInfoService.shared.copySystemInfoToClipboard()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isCopied = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isCopied = false
            }
        }
    }
}
