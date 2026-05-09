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
    var isSelected: Bool
    var cornerRadius: CGFloat = StyleConstants.cornerRadius
    var useAccentGradientWhenSelected: Bool = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                useAccentGradientWhenSelected && isSelected ? 
                    StyleConstants.cardGradientSelected :
                    StyleConstants.cardGradient
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isSelected ? StyleConstants.cardBorderSelected : StyleConstants.cardBorder,
                        lineWidth: 1.5 // Slightly thicker border for a defined glass edge
                    )
            )
            .shadow(
                color: isSelected ? StyleConstants.shadowSelected : StyleConstants.shadowDefault,
                radius: isSelected ? 18 : 12,
                x: 0,
                y: isSelected ? 10 : 6
            )
    }
} 
