import SwiftUI

// Style constants for components that still use the legacy CardBackground API.
struct StyleConstants {
    static let cardGradient = DreamersTheme.panelFill
    static let cardGradientSelected = DreamersTheme.selectedPanelFill
    static let cardBorder = DreamersTheme.panelStroke
    static let cardBorderSelected = DreamersTheme.selectedPanelStroke
    static let shadowDefault = DreamersTheme.ColorToken.softInk.opacity(0.14)
    static let shadowSelected = DreamersTheme.ColorToken.softInk.opacity(0.22)
    static let cornerRadius: CGFloat = DreamersTheme.Radius.panel
    static let buttonGradient = DreamersTheme.prismGradient
}

struct CardBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    var isSelected: Bool
    var cornerRadius: CGFloat = StyleConstants.cornerRadius
    var useAccentGradientWhenSelected: Bool = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                useAccentGradientWhenSelected && isSelected ?
                    DreamersTheme.selectedPanelFill(for: colorScheme) :
                    DreamersTheme.panelFill(for: colorScheme)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isSelected ? DreamersTheme.selectedPanelStroke(for: colorScheme) : DreamersTheme.panelStroke(for: colorScheme),
                        lineWidth: 1.5 // Slightly thicker border for a defined glass edge
                    )
            )
            .shadow(
                color: DreamersTheme.ColorToken.softInk.opacity(colorScheme == .dark ? 0.10 : (isSelected ? 0.18 : 0.10)),
                radius: isSelected ? 14 : 8,
                x: 0,
                y: isSelected ? 7 : 4
            )
    }
}
