import SwiftUI

struct DreamersAtmosphere: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false

    var body: some View {
        DreamersTheme.atmosphereGradient(for: colorScheme)
            .overlay(alignment: .topTrailing) {
                if !reduceMotion {
                    DreamersTheme.prismGradient
                        .frame(width: 240, height: 2)
                        .blur(radius: 1.5)
                        .opacity(0.38)
                        .rotationEffect(.degrees(-12))
                        .offset(x: drift ? 20 : -12, y: drift ? 26 : 6)
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
    @Environment(\.colorScheme) private var colorScheme
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
                    .fill(isSelected ? DreamersTheme.selectedPanelFill(for: colorScheme) : DreamersTheme.panelFill(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(isSelected ? DreamersTheme.selectedPanelStroke(for: colorScheme) : DreamersTheme.panelStroke(for: colorScheme), lineWidth: isSelected ? 1.2 : 0.8)
            )
            .shadow(
                color: DreamersTheme.ColorToken.softInk.opacity(colorScheme == .dark ? 0.10 : (isSelected ? 0.18 : 0.10)),
                radius: isSelected ? 14 : 8,
                x: 0,
                y: isSelected ? 7 : 4
            )
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

        var wordmarkWidth: CGFloat {
            switch self {
            case .compact: return 150
            case .standard: return 300
            case .hero: return 390
            }
        }
    }

    let scale: Scale
    var includeSubline = false

    var body: some View {
        Image("DreamScribeWordmark")
            .resizable()
            .scaledToFit()
            .frame(width: scale.wordmarkWidth)
            .shadow(color: DreamersTheme.ColorToken.starWhite.opacity(scale == .compact ? 0.08 : 0.14), radius: scale == .compact ? 4 : 10)
        .accessibilityLabel("DREAMScribe")
    }
}

struct DreamersFooterMark: View {
    @Environment(\.colorScheme) private var colorScheme

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
        .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
        .accessibilityLabel("Dreamers Media")
    }
}

struct DreamersSectionHeader: View {
    @Environment(\.colorScheme) private var colorScheme
    let label: String
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .tracking(1.8)
                .foregroundStyle(DreamersTheme.labelText(for: colorScheme))

            Text(title)
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(DreamersTheme.primaryText(for: colorScheme))

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct ChromeIconButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    var isSelected = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isSelected ? DreamersTheme.primaryText(for: colorScheme) : DreamersTheme.secondaryText(for: colorScheme))
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: DreamersTheme.Radius.control, style: .continuous)
                    .fill(isSelected ? DreamersTheme.selectedPanelFill(for: colorScheme) : DreamersTheme.panelFill(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DreamersTheme.Radius.control, style: .continuous)
                    .stroke(isSelected ? DreamersTheme.selectedPanelStroke(for: colorScheme) : DreamersTheme.panelStroke(for: colorScheme), lineWidth: 0.8)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(DreamersTheme.Motion.fast, value: configuration.isPressed)
    }
}

struct PrismButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
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
                    .stroke(colorScheme == .dark ? DreamersTheme.ColorToken.starWhite.opacity(0.42) : DreamersTheme.ColorToken.deepDreamBlue.opacity(0.20), lineWidth: 0.8)
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
            .tint(DreamersTheme.ColorToken.auroraCyan)
    }

    func dreamersFormChrome() -> some View {
        modifier(DreamersFormChromeModifier())
    }

    func dreamersInputChrome() -> some View {
        modifier(DreamersInputChromeModifier())
    }
}

private struct DreamersFormChromeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .listRowBackground(DreamersTheme.panelFill(for: colorScheme))
            .listRowSeparatorTint(DreamersTheme.accentText(for: colorScheme).opacity(0.26))
            .background(DreamersAtmosphere().ignoresSafeArea())
            .foregroundStyle(DreamersTheme.primaryText(for: colorScheme))
            .tint(DreamersTheme.accentText(for: colorScheme))
    }
}

private struct DreamersInputChromeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: DreamersTheme.Radius.control, style: .continuous)
                    .fill(DreamersTheme.selectedPanelFill(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DreamersTheme.Radius.control, style: .continuous)
                    .stroke(DreamersTheme.panelStroke(for: colorScheme), lineWidth: 0.8)
            )
            .foregroundStyle(DreamersTheme.primaryText(for: colorScheme))
    }
}
