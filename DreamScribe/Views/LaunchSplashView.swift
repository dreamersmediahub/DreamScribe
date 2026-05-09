import SwiftUI

/// Brief intro screen shown once per app launch. Iridescent D-submark glows in,
/// dissolves, and the DREAMERS wordmark fades up underneath. ~2.6 seconds total
/// before `onComplete` fires.
struct LaunchSplashView: View {
    var onComplete: () -> Void

    @State private var stage: Stage = .submark
    @State private var rootOpacity: Double = 1.0

    private enum Stage {
        case submark   // D-mark visible
        case wordmark  // wordmark visible
    }

    private static let inkTop    = Color(red: 0x1f / 255.0, green: 0x1c / 255.0, blue: 0x19 / 255.0)
    private static let inkMid    = Color(red: 0x14 / 255.0, green: 0x12 / 255.0, blue: 0x10 / 255.0)
    private static let inkBottom = Color(red: 0x0a / 255.0, green: 0x09 / 255.0, blue: 0x08 / 255.0)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Self.inkTop, Self.inkMid, Self.inkBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            switch stage {
            case .submark:
                Image("DreamersSubmark")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .transition(
                        .scale(scale: 0.86)
                        .combined(with: .opacity)
                    )
            case .wordmark:
                Image("DreamersWordmark")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 520)
                    .transition(
                        .opacity
                        .combined(with: .move(edge: .bottom))
                    )
            }
        }
        .opacity(rootOpacity)
        .task {
            // Hold the submark briefly so the eye can settle on it
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            // Cross-fade to wordmark
            withAnimation(.easeInOut(duration: 0.7)) {
                stage = .wordmark
            }

            // Hold the wordmark, then fade the whole splash out
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            withAnimation(.easeOut(duration: 0.5)) {
                rootOpacity = 0
            }

            try? await Task.sleep(nanoseconds: 500_000_000)
            onComplete()
        }
    }
}

#Preview {
    LaunchSplashView(onComplete: {})
        .frame(width: 950, height: 730)
}
