import SwiftUI

struct MetricCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let title: String
    let value: String
    let detail: String?
    let color: Color
    
    var body: some View {
        ChromePanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DreamersTheme.Radius.control, style: .continuous)
                            .fill(color.opacity(0.18))
                        RoundedRectangle(cornerRadius: DreamersTheme.Radius.control, style: .continuous)
                            .stroke(color.opacity(0.34), lineWidth: 0.8)
                        Image(systemName: icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 17, height: 17)
                            .foregroundStyle(color)
                    }
                    .frame(width: 34, height: 34)

                    Text(title)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .tracking(0.6)
                        .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Text(value)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(DreamersTheme.primaryText(for: colorScheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(DreamersTheme.tertiaryText(for: colorScheme))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(16)
        }
    }
}
