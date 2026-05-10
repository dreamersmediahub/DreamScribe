import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum DreamersTheme {
    enum ColorToken {
        static let midnightNavy = Color(red: 0x07 / 255.0, green: 0x16 / 255.0, blue: 0x2E / 255.0)
        static let deepDreamBlue = Color(red: 0x10 / 255.0, green: 0x2B / 255.0, blue: 0x5C / 255.0)
        static let dreamBlue = Color(red: 0x31 / 255.0, green: 0x5F / 255.0, blue: 0xAD / 255.0)
        static let hazeBlue = Color(red: 0x7E / 255.0, green: 0xA0 / 255.0, blue: 0xD6 / 255.0)
        static let skyVeil = Color(red: 0xB6 / 255.0, green: 0xC8 / 255.0, blue: 0xEF / 255.0)
        static let periwinkleMist = Color(red: 0xD8 / 255.0, green: 0xDD / 255.0, blue: 0xF8 / 255.0)

        static let softInk = Color(red: 0x05 / 255.0, green: 0x07 / 255.0, blue: 0x0D / 255.0)
        static let charcoalHoodie = Color(red: 0x10 / 255.0, green: 0x12 / 255.0, blue: 0x17 / 255.0)
        static let starWhite = Color(red: 0xF8 / 255.0, green: 0xFA / 255.0, blue: 0xFF / 255.0)
        static let pearlCream = Color(red: 0xF5 / 255.0, green: 0xEF / 255.0, blue: 0xE7 / 255.0)
        static let chromeSilver = Color(red: 0xD5 / 255.0, green: 0xD9 / 255.0, blue: 0xE0 / 255.0)
        static let coolMetal = Color(red: 0x9E / 255.0, green: 0xA9 / 255.0, blue: 0xB8 / 255.0)

        static let auroraCyan = Color(red: 0x66 / 255.0, green: 0xE6 / 255.0, blue: 0xF4 / 255.0)
        static let prismMint = Color(red: 0x8F / 255.0, green: 0xFF / 255.0, blue: 0xE2 / 255.0)
        static let violetEdge = Color(red: 0x9C / 255.0, green: 0x8C / 255.0, blue: 0xFF / 255.0)
        static let blushPink = Color(red: 0xF2 / 255.0, green: 0xA5 / 255.0, blue: 0xBA / 255.0)
        static let lemonFlare = Color(red: 0xFF / 255.0, green: 0xE8 / 255.0, blue: 0x8A / 255.0)
        static let warmLens = Color(red: 0xFF / 255.0, green: 0xB4 / 255.0, blue: 0x6E / 255.0)
    }

    enum Radius {
        static let panel: CGFloat = 8
        static let control: CGFloat = 6
        static let small: CGFloat = 4
    }

    enum Motion {
        static let fast = Animation.easeOut(duration: 0.18)
        static let medium = Animation.smooth(duration: 0.42)
        static let reveal = Animation.easeOut(duration: 1.1)
    }

    static let chromeGradient = LinearGradient(
        colors: [
            ColorToken.starWhite,
            ColorToken.skyVeil,
            ColorToken.pearlCream,
            ColorToken.auroraCyan,
            ColorToken.blushPink,
            ColorToken.violetEdge,
            ColorToken.starWhite
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let prismGradient = LinearGradient(
        colors: [
            ColorToken.auroraCyan,
            ColorToken.prismMint,
            ColorToken.lemonFlare,
            ColorToken.blushPink,
            ColorToken.violetEdge,
            ColorToken.auroraCyan
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let panelFill = LinearGradient(
        colors: [
            ColorToken.starWhite.opacity(0.23),
            ColorToken.skyVeil.opacity(0.18),
            ColorToken.auroraCyan.opacity(0.10),
            ColorToken.deepDreamBlue.opacity(0.10)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func primaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? ColorToken.starWhite : ColorToken.softInk
    }

    static func secondaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? ColorToken.starWhite.opacity(0.82) : ColorToken.deepDreamBlue.opacity(0.86)
    }

    static func tertiaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? ColorToken.starWhite.opacity(0.68) : ColorToken.deepDreamBlue.opacity(0.70)
    }

    static func labelText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? ColorToken.auroraCyan : ColorToken.deepDreamBlue
    }

    static func accentText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? ColorToken.auroraCyan : Color(red: 0x13 / 255.0, green: 0x62 / 255.0, blue: 0x8E / 255.0)
    }

    static func success(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? ColorToken.prismMint : Color(red: 0x10 / 255.0, green: 0x7A / 255.0, blue: 0x55 / 255.0)
    }

    static func warning(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? ColorToken.lemonFlare : Color(red: 0x8A / 255.0, green: 0x62 / 255.0, blue: 0x00 / 255.0)
    }

    static func danger(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? ColorToken.blushPink : Color(red: 0xB8 / 255.0, green: 0x2D / 255.0, blue: 0x48 / 255.0)
    }

    static func panelFill(for colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    ColorToken.hazeBlue.opacity(0.36),
                    ColorToken.dreamBlue.opacity(0.46),
                    ColorToken.deepDreamBlue.opacity(0.52),
                    ColorToken.violetEdge.opacity(0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                ColorToken.starWhite.opacity(0.92),
                ColorToken.periwinkleMist.opacity(0.86),
                ColorToken.skyVeil.opacity(0.76)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func selectedPanelFill(for colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    ColorToken.auroraCyan.opacity(0.30),
                    ColorToken.dreamBlue.opacity(0.58),
                    ColorToken.violetEdge.opacity(0.26)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                ColorToken.starWhite.opacity(0.98),
                ColorToken.auroraCyan.opacity(0.32),
                ColorToken.blushPink.opacity(0.22)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func panelStroke(for colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    ColorToken.starWhite.opacity(0.32),
                    ColorToken.auroraCyan.opacity(0.38),
                    ColorToken.violetEdge.opacity(0.28)
                ]
                : [
                    ColorToken.deepDreamBlue.opacity(0.22),
                    ColorToken.auroraCyan.opacity(0.42),
                    ColorToken.violetEdge.opacity(0.28)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func selectedPanelStroke(for colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    ColorToken.starWhite.opacity(0.70),
                    ColorToken.auroraCyan.opacity(0.68),
                    ColorToken.blushPink.opacity(0.48)
                ]
                : [
                    ColorToken.deepDreamBlue.opacity(0.34),
                    ColorToken.auroraCyan.opacity(0.76),
                    ColorToken.blushPink.opacity(0.58)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static let selectedPanelFill = LinearGradient(
        colors: [
            ColorToken.starWhite.opacity(0.22),
            ColorToken.auroraCyan.opacity(0.30),
            ColorToken.blushPink.opacity(0.18),
            ColorToken.violetEdge.opacity(0.20)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let panelStroke = LinearGradient(
        colors: [
            ColorToken.starWhite.opacity(0.56),
            ColorToken.auroraCyan.opacity(0.34),
            ColorToken.violetEdge.opacity(0.24)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let selectedPanelStroke = LinearGradient(
        colors: [
            ColorToken.starWhite.opacity(0.82),
            ColorToken.auroraCyan.opacity(0.72),
            ColorToken.blushPink.opacity(0.46)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func atmosphereGradient(for colorScheme: ColorScheme = .dark) -> some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        ColorToken.midnightNavy,
                        ColorToken.deepDreamBlue,
                        ColorToken.dreamBlue
                    ]
                    : [
                        ColorToken.starWhite,
                        ColorToken.periwinkleMist,
                        ColorToken.skyVeil
                    ],
                startPoint: .top,
                endPoint: .bottom
            )

            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        ColorToken.starWhite.opacity(0.10),
                        .clear,
                        ColorToken.violetEdge.opacity(0.20)
                    ]
                    : [
                        ColorToken.starWhite.opacity(0.70),
                        .clear,
                        ColorToken.violetEdge.opacity(0.16)
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    .clear,
                    ColorToken.auroraCyan.opacity(0.16),
                    ColorToken.blushPink.opacity(0.12),
                    .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}
