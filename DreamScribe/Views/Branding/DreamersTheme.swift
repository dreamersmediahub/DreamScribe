import SwiftUI

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
            ColorToken.starWhite.opacity(0.16),
            ColorToken.skyVeil.opacity(0.08),
            ColorToken.deepDreamBlue.opacity(0.20)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let selectedPanelFill = LinearGradient(
        colors: [
            ColorToken.auroraCyan.opacity(0.28),
            ColorToken.violetEdge.opacity(0.18),
            ColorToken.deepDreamBlue.opacity(0.22)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let panelStroke = LinearGradient(
        colors: [
            ColorToken.starWhite.opacity(0.42),
            ColorToken.auroraCyan.opacity(0.20),
            ColorToken.violetEdge.opacity(0.18)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let selectedPanelStroke = LinearGradient(
        colors: [
            ColorToken.starWhite.opacity(0.70),
            ColorToken.auroraCyan.opacity(0.58),
            ColorToken.blushPink.opacity(0.32)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func atmosphereGradient() -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    ColorToken.midnightNavy,
                    ColorToken.deepDreamBlue,
                    ColorToken.dreamBlue,
                    ColorToken.hazeBlue
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [ColorToken.skyVeil.opacity(0.44), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 420
            )

            RadialGradient(
                colors: [ColorToken.violetEdge.opacity(0.20), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 360
            )

            RadialGradient(
                colors: [ColorToken.blushPink.opacity(0.13), .clear],
                center: .bottom,
                startRadius: 0,
                endRadius: 520
            )
        }
    }
}
