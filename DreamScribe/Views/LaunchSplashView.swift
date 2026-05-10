import SwiftUI

/// Brief intro screen shown once per app launch. The Dreamers submark reveals,
/// then settles into the DREAMScribe lockup before `onComplete` fires.
struct LaunchSplashView: View {
    var onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var stage: Stage = .submark
    @State private var rootOpacity: Double = 1.0
    @State private var markScale: CGFloat = 0.92

    private enum Stage {
        case submark
        case lockup
    }

    var body: some View {
        ZStack {
            DreamersAtmosphere()
                .ignoresSafeArea()

            switch stage {
            case .submark:
                submarkReveal
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            case .lockup:
                lockupReveal
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .opacity(rootOpacity)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 0.9)) {
                markScale = 1
            }
        }
        .task {
            // Hold the submark briefly so the eye can settle on it
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            // Cross-fade to product identity
            withAnimation(.easeInOut(duration: 0.7)) {
                stage = .lockup
            }

            // Hold the lockup, then fade the whole splash out
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            withAnimation(.easeOut(duration: 0.5)) {
                rootOpacity = 0
            }

            try? await Task.sleep(nanoseconds: 500_000_000)
            onComplete()
        }
    }

    private var submarkReveal: some View {
        VStack(spacing: 18) {
            Image("DreamersSubmark")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 190, height: 190)
                .shadow(color: DreamersTheme.ColorToken.auroraCyan.opacity(0.38), radius: 34)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(DreamersTheme.ColorToken.starWhite)
                        .shadow(color: DreamersTheme.ColorToken.auroraCyan.opacity(0.8), radius: 12)
                        .offset(x: -10, y: 16)
                }

            Text("DREAMERS MEDIA")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .tracking(3)
                .foregroundStyle(DreamersTheme.ColorToken.starWhite.opacity(0.62))
        }
        .scaleEffect(markScale)
    }

    private var lockupReveal: some View {
        VStack(spacing: 18) {
            DREAMScribeLockup(scale: .hero, includeSubline: true)
                .frame(maxWidth: 560, alignment: .leading)

            Rectangle()
                .fill(DreamersTheme.prismGradient)
                .frame(width: 180, height: 1)
                .opacity(0.86)
        }
        .padding(.horizontal, 44)
    }
}

#Preview {
    LaunchSplashView(onComplete: {})
        .frame(width: 950, height: 730)
}
