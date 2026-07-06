import SwiftUI

struct CommunityView: View {
    @State private var selectedSection: Section = .sharing

    enum Section: String, CaseIterable, Identifiable {
        case sharing = "代码分享"
        case templates = "模板市场"
        case learning = "学习中心"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .sharing: return "square.and.arrow.up"
            case .templates: return "doc.on.doc"
            case .learning: return "book"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sectionPicker

                TabView(selection: $selectedSection) {
                    CodeSharingView()
                        .tag(Section.sharing)

                    TemplateMarketView()
                        .tag(Section.templates)

                    LearningCenterView()
                        .tag(Section.learning)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(Theme.Colors.background)
            .navigationTitle("社区")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var sectionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Section.allCases) { section in
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
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
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
        .background(Theme.Colors.background)
    }
}

#Preview {
    CommunityView()
        .environmentObject(AppState())
}
