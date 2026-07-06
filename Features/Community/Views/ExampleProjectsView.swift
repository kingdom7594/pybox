import SwiftUI

struct ExampleProjectsView: View {
    @StateObject private var viewModel = ExampleProjectsViewModel()
    @State private var selectedProject: ExampleProject?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.projects) { project in
                    ProjectCard(project: project) {
                        selectedProject = project
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .sheet(item: $selectedProject) { project in
            ProjectDetailView(project: project)
        }
    }
}

struct ProjectCard: View {
    let project: ExampleProject
    let onTap: () -> Void

    var body: some View {
        Button { onTap() } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: project.icon)
                        .font(.system(size: 24))
                        .foregroundColor(Theme.Colors.accent)
                        .frame(width: 44, height: 44)
                        .background(Theme.Colors.accent.opacity(0.15))
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.textPrimary)

                        HStack(spacing: 8) {
                            difficultyBadge
                            Text(project.duration)
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.textMuted)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(Theme.Colors.textMuted)
                }

                Text(project.description)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(project.concepts, id: \.self) { concept in
                            Text(concept)
                                .font(.system(size: 11))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.Colors.surface2)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .cornerRadius(6)
                        }
                    }
                }
            }
            .padding(16)
            .background(Theme.Colors.surface2)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var difficultyBadge: some View {
        Text(project.difficulty.rawValue)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(project.difficulty.color.opacity(0.2))
            .foregroundColor(project.difficulty.color)
            .cornerRadius(4)
    }
}

struct ProjectDetailView: View {
    let project: ExampleProject
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFile: TemplateFile?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerSection
                    conceptsSection
                    filesSection
                }
                .padding(16)
            }
            .background(Theme.Colors.background)
            .navigationTitle(project.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        importProject()
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
            }
            .sheet(item: $selectedFile) { file in
                FilePreviewView(file: file)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                difficultyBadge
                Text(project.duration)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.textMuted)
            }

            Text(project.description)
                .font(.system(size: 15))
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface2)
        .cornerRadius(12)
    }

    private var difficultyBadge: some View {
        Text(project.difficulty.rawValue)
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(project.difficulty.color.opacity(0.2))
            .foregroundColor(project.difficulty.color)
            .cornerRadius(6)
    }

    private var conceptsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("学习要点")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)

            FlowLayout(spacing: 8) {
                ForEach(project.concepts, id: \.self) { concept in
                    Text(concept)
                        .font(.system(size: 13))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.Colors.accent.opacity(0.15))
                        .foregroundColor(Theme.Colors.accent)
                        .cornerRadius(16)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface2)
        .cornerRadius(12)
    }

    private var filesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("项目文件")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)

            ForEach(project.files) { file in
                Button {
                    selectedFile = file
                } label: {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(Theme.Colors.secondary)
                        Text(file.name)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.textMuted)
                    }
                    .padding(12)
                    .background(Theme.Colors.surface2)
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface2)
        .cornerRadius(12)
    }

    private func importProject() {
        NotificationCenter.default.post(
            name: .importTemplateRequested,
            object: nil,
            userInfo: [
                "name": project.name,
                "files": project.files.map { ["name": $0.name, "content": $0.content] }
            ]
        )
        dismiss()
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: width, height: y + rowHeight)
        }
    }
}

#Preview {
    ExampleProjectsView()
        .environmentObject(AppState())
}
