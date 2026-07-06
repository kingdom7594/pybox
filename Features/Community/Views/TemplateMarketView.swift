import SwiftUI

struct TemplateMarketView: View {
    @StateObject private var viewModel = TemplateMarketViewModel()
    @State private var selectedTemplate: Template?

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            categoryPicker
            templateList
        }
        .background(Theme.Colors.background)
        .sheet(item: $selectedTemplate) { template in
            TemplateDetailView(template: template)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.Colors.textMuted)

            TextField("搜索模板...", text: $viewModel.searchText)
                .foregroundColor(Theme.Colors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.Colors.surface2)
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TemplateMarketViewModel.Category.allCases) { category in
                    Button {
                        viewModel.selectedCategory = category
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                                .font(.system(size: 12))
                            Text(category.rawValue)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            viewModel.selectedCategory == category
                                ? Theme.Colors.accent
                                : Theme.Colors.surface2
                        )
                        .foregroundColor(
                            viewModel.selectedCategory == category
                                ? .white
                                : Theme.Colors.textSecondary
                        )
                        .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var templateList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredTemplates) { template in
                    TemplateCard(template: template) {
                        selectedTemplate = template
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }
}

struct TemplateCard: View {
    let template: Template
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text(template.author)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textMuted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    categoryBadge
                    ratingView
                }
            }

            Text(template.description)
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.textSecondary)
                .lineLimit(2)

            HStack {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.textMuted)
                Text("\(template.files.count) 个文件")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.textMuted)

                Spacer()

                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.textMuted)
                Text("\(template.downloads)")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.textMuted)
            }
        }
        .padding(16)
        .background(Theme.Colors.surface2)
        .cornerRadius(12)
        .onTapGesture {
            onTap()
        }
    }

    private var categoryBadge: some View {
        Text(template.category)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.Colors.accent.opacity(0.2))
            .foregroundColor(Theme.Colors.accent)
            .cornerRadius(8)
    }

    private var ratingView: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.system(size: 10))
                .foregroundColor(Theme.Colors.accent)
            Text(String(format: "%.1f", template.rating))
                .font(.system(size: 10))
                .foregroundColor(Theme.Colors.textMuted)
        }
    }
}

struct TemplateDetailView: View {
    let template: Template
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFile: TemplateFile?
    @State private var showingImportSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                fileListSection
                actionButtons
            }
            .background(Theme.Colors.background)
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedFile) { file in
                FilePreviewView(file: file)
            }
            .alert("导入模板", isPresented: $showingImportSheet) {
                Button("导入") {
                    importTemplate()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("将创建「\(template.name)」项目，包含 \(template.files.count) 个文件")
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(template.author)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textMuted)

                Spacer()

                categoryBadge
            }

            Text(template.description)
                .font(.system(size: 15))
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding(16)
        .background(Theme.Colors.surface2)
    }

    private var categoryBadge: some View {
        Text(template.category)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.Colors.accent.opacity(0.2))
            .foregroundColor(Theme.Colors.accent)
            .cornerRadius(16)
    }

    private var fileListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("文件列表")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(template.files) { file in
                        FileRow(file: file) {
                            selectedFile = file
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showingImportSheet = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("导入模板")
                }
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.Colors.accent)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding(16)
    }

    private func importTemplate() {
        NotificationCenter.default.post(
            name: .importTemplateRequested,
            object: nil,
            userInfo: [
                "name": template.name,
                "files": template.files.map { ["name": $0.name, "content": $0.content] }
            ]
        )
        dismiss()
    }
}

struct FileRow: View {
    let file: TemplateFile
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text")
                    .font(.system(size: 16))
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

struct FilePreviewView: View {
    let file: TemplateFile
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(file.content)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Theme.Colors.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Theme.Colors.background)
            .navigationTitle(file.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        UIPasteboard.general.string = file.content
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                }
            }
        }
    }
}

extension Notification.Name {
    static let importTemplateRequested = Notification.Name("importTemplateRequested")
}

#Preview {
    TemplateMarketView()
        .environmentObject(AppState())
}
