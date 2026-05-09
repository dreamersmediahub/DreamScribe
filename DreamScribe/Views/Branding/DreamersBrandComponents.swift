import SwiftUI

struct DreamersAtmosphere: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false

    var body: some View {
        DreamersTheme.atmosphereGradient()
            .overlay(alignment: .topTrailing) {
                if !reduceMotion {
                    Circle()
                        .fill(DreamersTheme.ColorToken.auroraCyan.opacity(0.12))
                        .frame(width: 260, height: 260)
                        .blur(radius: 58)
                        .offset(x: drift ? 20 : -12, y: drift ? -20 : 8)
                        .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: drift)
                }
            }
            .overlay {
                LinearGradient(
                    colors: [
                        .clear,
                        DreamersTheme.ColorToken.starWhite.opacity(0.035),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(.screen)
            }
            .onAppear { drift = true }
    }
}

struct ChromePanel<Content: View>: View {
    let isSelected: Bool
    let cornerRadius: CGFloat
    let content: Content

    init(isSelected: Bool = false, cornerRadius: CGFloat = DreamersTheme.Radius.panel, @ViewBuilder content: () -> Content) {
        self.isSelected = isSelected
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isSelected ? DreamersTheme.selectedPanelFill : DreamersTheme.panelFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(isSelected ? DreamersTheme.selectedPanelStroke : DreamersTheme.panelStroke, lineWidth: isSelected ? 1.2 : 0.8)
            )
            .shadow(color: DreamersTheme.ColorToken.softInk.opacity(isSelected ? 0.22 : 0.14), radius: isSelected ? 18 : 12, x: 0, y: isSelected ? 10 : 6)
    }
}

struct DREAMScribeLockup: View {
    enum Scale {
        case compact
        case standard
        case hero

        var dreamSize: CGFloat {
            switch self {
            case .compact: return 18
            case .standard: return 34
            case .hero: return 58
            }
        }

        var scribeSize: CGFloat {
            switch self {
            case .compact: return 17
            case .standard: return 33
            case .hero: return 56
            }
        }
    }

    let scale: Scale
    var includeSubline = false

    var body: some View {
        VStack(alignment: .leading, spacing: scale == .compact ? 2 : 6) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("DREAM")
                    .font(.system(size: scale.dreamSize, weight: .semibold, design: .serif))
                    .tracking(scale == .compact ? 1.0 : 2.4)
                    .foregroundStyle(DreamersTheme.chromeGradient)

                Text("S")
                    .font(.system(size: scale.scribeSize, weight: .semibold, design: .serif))
                    .italic()
                    .foregroundStyle(DreamersTheme.chromeGradient)
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: "sparkle")
                            .font(.system(size: max(7, scale.scribeSize * 0.22), weight: .semibold))
                            .foregroundStyle(DreamersTheme.ColorToken.starWhite)
                            .shadow(color: DreamersTheme.ColorToken.auroraCyan.opacity(0.8), radius: 8)
                            .offset(x: scale == .compact ? 5 : 8, y: scale == .compact ? -3 : -6)
                    }

                Text("cribe")
                    .font(.system(size: scale.scribeSize, weight: .medium, design: .serif))
                    .italic()
                    .foregroundStyle(DreamersTheme.ColorToken.pearlCream)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.72)

            if includeSubline {
                Text("BY DREAMERS MEDIA")
                    .font(.system(size: scale == .hero ? 11 : 9, weight: .medium, design: .monospaced))
                    .tracking(2.6)
                    .foregroundStyle(DreamersTheme.ColorToken.starWhite.opacity(0.70))
            }
        }
        .accessibilityLabel("DREAMScribe")
    }
}

struct DreamersFooterMark: View {
    var body: some View {
        HStack(spacing: 8) {
            Image("DreamersSubmark")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .opacity(0.86)

            Text("DREAMERS MEDIA")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(2.0)
        }
        .foregroundStyle(DreamersTheme.ColorToken.starWhite.opacity(0.72))
        .accessibilityLabel("Dreamers Media")
    }
}

struct DreamersSectionHeader: View {
    let label: String
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .tracking(1.8)
                .foregroundStyle(DreamersTheme.ColorToken.auroraCyan.opacity(0.84))

            Text(title)
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(DreamersTheme.ColorToken.starWhite)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(DreamersTheme.ColorToken.starWhite.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct ChromeIconButtonStyle: ButtonStyle {
    var isSelected = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isSelected ? DreamersTheme.ColorToken.starWhite : DreamersTheme.ColorToken.starWhite.opacity(0.82))
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: DreamersTheme.Radius.control, style: .continuous)
                    .fill(isSelected ? DreamersTheme.selectedPanelFill : DreamersTheme.panelFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DreamersTheme.Radius.control, style: .continuous)
                    .stroke(isSelected ? DreamersTheme.selectedPanelStroke : DreamersTheme.panelStroke, lineWidth: 0.8)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(DreamersTheme.Motion.fast, value: configuration.isPressed)
    }
}

struct PrismButtonStyle: ButtonStyle {
    var role: ButtonRole?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(role == .destructive ? Color.red : DreamersTheme.ColorToken.softInk)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: DreamersTheme.Radius.control, style: .continuous)
                    .fill(role == .destructive ? AnyShapeStyle(Color.red.opacity(0.12)) : AnyShapeStyle(DreamersTheme.prismGradient))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DreamersTheme.Radius.control, style: .continuous)
                    .stroke(DreamersTheme.ColorToken.starWhite.opacity(0.42), lineWidth: 0.8)
            )
            .opacity(configuration.isPressed ? 0.84 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(DreamersTheme.Motion.fast, value: configuration.isPressed)
    }
}

extension View {
    func dreamersPageChrome(horizontalPadding: CGFloat = 32, verticalPadding: CGFloat = 28) -> some View {
        self
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(DreamersAtmosphere().ignoresSafeArea())
    }
}
