import SwiftUI

struct AudioVisualizer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let audioMeter: AudioMeter
    let color: Color
    let isActive: Bool

    private let barCount = 15
    private let barWidth: CGFloat = 3
    private let barSpacing: CGFloat = 2
    private let minHeight: CGFloat = 4
    private let maxHeight: CGFloat = 28

    private let phases: [Double]

    init(audioMeter: AudioMeter, color: Color, isActive: Bool) {
        self.audioMeter = audioMeter
        self.color = color
        self.isActive = isActive
        self.phases = (0..<barCount).map { Double($0) * 0.4 }
    }

    var body: some View {
        Group {
            if reduceMotion {
                bars(at: nil)
            } else {
                TimelineView(.animation(minimumInterval: 0.024)) { context in
                    bars(at: context.date)
                }
            }
        }
    }

    private func bars(at date: Date?) -> some View {
        HStack(spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: barWidth / 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(isActive ? 0.95 : 0.50),
                                DreamersTheme.ColorToken.starWhite.opacity(isActive ? 0.72 : 0.34),
                                DreamersTheme.ColorToken.violetEdge.opacity(isActive ? 0.62 : 0.24)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: barWidth, height: barHeight(for: index, at: date))
                    .shadow(color: color.opacity(isActive && !reduceMotion ? 0.28 : 0), radius: 4, x: 0, y: 0)
            }
        }
    }

    private func barHeight(for index: Int, at date: Date?) -> CGFloat {
        guard isActive else { return minHeight }

        let amplitude = max(0, min(1, pow(audioMeter.averagePower, 0.7))) // boosted for visibility
        let centerDistance = abs(Double(index) - Double(barCount) / 2) / Double(barCount / 2)
        let centerBoost = 1.0 - (centerDistance * 0.4)
        let wave: Double

        if let date {
            wave = sin(date.timeIntervalSince1970 * 8 + phases[index]) * 0.5 + 0.5
        } else {
            wave = 0.42 + centerBoost * 0.36
        }

        return max(minHeight, minHeight + CGFloat(amplitude * wave * centerBoost) * (maxHeight - minHeight))
    }
}

// Flat bars shown when the recorder is idle (no audio input)
struct StaticVisualizer: View {
    private let barCount = 15
    private let barWidth: CGFloat = 3
    private let barHeight: CGFloat = 4
    private let barSpacing: CGFloat = 2
    let color: Color

    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { _ in
                RoundedRectangle(cornerRadius: barWidth / 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.46),
                                DreamersTheme.ColorToken.skyVeil.opacity(0.20)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: barWidth, height: barHeight)
            }
        }
    }
}

// MARK: - Processing Status Display

struct ProcessingStatusDisplay: View {
    enum Mode {
        case transcribing
        case enhancing
    }

    let mode: Mode
    let color: Color

    private var label: String {
        switch mode {
        case .transcribing: return "Transcribing"
        case .enhancing:    return "Enhancing"
        }
    }

    private var animationSpeed: Double {
        switch mode {
        case .transcribing: return 0.18
        case .enhancing:    return 0.22
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .foregroundStyle(color)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            ProgressAnimation(color: color, animationSpeed: animationSpeed)
        }
        .frame(height: 28) // matches AudioVisualizer maxHeight to prevent layout shift
    }
}
