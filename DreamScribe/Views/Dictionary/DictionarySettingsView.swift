import SwiftUI
import SwiftData

struct DictionarySettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedSection: DictionarySection = .replacements
    @State private var isShowingSettings = false
    let whisperPrompt: WhisperPrompt
    
    enum DictionarySection: String, CaseIterable {
        case replacements = "Word Replacements"
        case spellings = "Vocabulary"
        
        var description: String {
            switch self {
            case .spellings:
                return "Add words to help DreamScribe recognize them properly"
            case .replacements:
                return "Automatically replace specific words/phrases with custom formatted text "
            }
        }
        
        var icon: String {
            switch self {
            case .spellings:
                return "character.book.closed.fill"
            case .replacements:
                return "arrow.2.squarepath"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                mainContent
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(DreamersAtmosphere().ignoresSafeArea())
        .slidingPanel(isPresented: $isShowingSettings, width: 400) {
            DictionarySettingsPanel {
                withAnimation(.smooth(duration: 0.3)) {
                    isShowingSettings = false
                }
            }
        }
    }
    
    private var heroSection: some View {
        DreamersSectionHeader(
            label: "Dictionary",
            title: "Dictionary Settings",
            subtitle: "Enhance DreamScribe's transcription accuracy by teaching it your vocabulary."
        )
        .padding(.horizontal, 32)
        .padding(.top, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var mainContent: some View {
        VStack(spacing: 40) {
            sectionSelector
            selectedSectionContent
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
    }
    
    private var sectionSelector: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                DreamersSectionHeader(
                    label: "Tools",
                    title: "Select Section"
                )

                Spacer()

                Button {
                    withAnimation(.smooth(duration: 0.3)) {
                        isShowingSettings.toggle()
                    }
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: 18, weight: .medium))
                }
                .buttonStyle(ChromeIconButtonStyle(isSelected: isShowingSettings))
                .help("Dictionary settings")
            }

            HStack(spacing: 20) {
                ForEach(DictionarySection.allCases, id: \.self) { section in
                    SectionCard(
                        section: section,
                        isSelected: selectedSection == section,
                        action: { selectedSection = section }
                    )
                }
            }
        }
    }
    
    private var selectedSectionContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            switch selectedSection {
            case .spellings:
                VocabularyView(whisperPrompt: whisperPrompt)
                    .background(CardBackground(isSelected: false))
            case .replacements:
                WordReplacementView()
                    .background(CardBackground(isSelected: false))
            }
        }
    }
}

struct SectionCard: View {
    let section: DictionarySettingsView.DictionarySection
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: section.icon)
                    .font(.system(size: 28))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isSelected ? DreamersTheme.ColorToken.auroraCyan : DreamersTheme.ColorToken.starWhite.opacity(0.70))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.rawValue)
                        .font(.headline)
                        .foregroundStyle(DreamersTheme.ColorToken.starWhite)
                    
                    Text(section.description)
                        .font(.subheadline)
                        .foregroundStyle(DreamersTheme.ColorToken.starWhite.opacity(0.70))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                ChromePanel(isSelected: isSelected) {
                    Color.clear
                }
            )
        }
        .buttonStyle(.plain)
    }
} 
