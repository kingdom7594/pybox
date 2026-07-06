import SwiftUI

struct LearningCenterView: View {
    @State private var selectedSection: LearningSection = .examples

    enum LearningSection: String, CaseIterable, Identifiable {
        case examples = "示例项目"
        case tutorials = "教程"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .examples: return "folder.fill"
            case .tutorials: return "book.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            sectionPicker
            tabContent
        }
        .background(Theme.Colors.background)
    }

    private var sectionPicker: some View {
        HStack(spacing: 12) {
            ForEach(LearningSection.allCases) { section in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSection = section
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: section.icon)
                            .font(.system(size: 14, weight: .medium))
                        Text(section.rawValue)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        selectedSection == section
                            ? Theme.Colors.accent
                            : Theme.Colors.surface2
                    )
                    .foregroundColor(
                        selectedSection == section
                            ? .white
                            : Theme.Colors.textSecondary
                    )
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedSection {
        case .examples:
            ExampleProjectsView()
        case .tutorials:
            TutorialsView()
        }
    }
}

#Preview {
    LearningCenterView()
        .environmentObject(AppState())
}
