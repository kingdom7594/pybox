import SwiftUI

struct CodeSharingView: View {
    @StateObject private var viewModel = CodeSharingViewModel()
    @State private var showingShareSheet = false
    @State private var selectedCode: SharedCode?

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            categoryPicker
            codeList
        }
        .background(Theme.Colors.background)
        .sheet(isPresented: $showingShareSheet) {
            ShareCodeSheet(viewModel: viewModel)
        }
        .sheet(item: $selectedCode) { code in
            CodeDetailView(code: code, viewModel: viewModel)
        }
        .overlay(alignment: .bottomTrailing) {
            shareButton
        }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.Colors.textMuted)

            TextField("搜索代码...", text: $viewModel.searchText)
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
                ForEach(CodeSharingViewModel.Category.allCases) { category in
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

    private var codeList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredCodes) { code in
                    CodeCard(code: code) {
                        selectedCode = code
                    } onImport: {
                        importCode(code)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 80)
        }
    }

    private var shareButton: some View {
        Button {
            showingShareSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Theme.Colors.accent)
                .clipShape(Circle())
                .shadow(color: Theme.Colors.accent.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }

    private func importCode(_ code: SharedCode) {
        NotificationCenter.default.post(
            name: .importCodeRequested,
            object: nil,
            userInfo: [
                "title": code.title,
                "code": code.code,
                "language": "python"
            ]
        )
    }
}

struct CodeCard: View {
    let code: SharedCode
    let onTap: () -> Void
    let onImport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(code.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text(code.author)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textMuted)
                }

                Spacer()

                categoryBadge
            }

            Text(code.description)
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.textSecondary)
                .lineLimit(2)

            codePreview

            HStack {
                Button {
                    onImport()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 12))
                        Text("导入")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.Colors.accent)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }

                Spacer()

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 12))
                        Text("\(code.downloads)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Theme.Colors.textMuted)

                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                            .font(.system(size: 12))
                        Text("\(code.likes)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Theme.Colors.textMuted)
                }
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
        Text(code.category)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.Colors.accent.opacity(0.2))
            .foregroundColor(Theme.Colors.accent)
            .cornerRadius(8)
    }

    private var codePreview: some View {
        Text(String(code.code.prefix(150)) + (code.code.count > 150 ? "..." : ""))
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(Theme.Colors.secondary)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.background)
            .cornerRadius(8)
    }
}

struct ShareCodeSheet: View {
    @ObservedObject var viewModel: CodeSharingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var code = ""
    @State private var selectedCategory = "算法"

    private let categories = ["算法", "自动化", "数据处理", "游戏", "工具"]

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("标题", text: $title)
                    TextField("描述", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    Picker("分类", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }

                Section("代码") {
                    TextEditor(text: $code)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("分享代码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("分享") {
                        viewModel.shareCode(
                            title: title,
                            description: description,
                            code: code,
                            category: selectedCategory
                        )
                        dismiss()
                    }
                    .disabled(title.isEmpty || code.isEmpty)
                }
            }
        }
    }
}

struct CodeDetailView: View {
    let code: SharedCode
    @ObservedObject var viewModel: CodeSharingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerSection
                    descriptionSection
                    codeSection
                    actionsSection
                }
                .padding(16)
            }
            .background(Theme.Colors.background)
            .navigationTitle(code.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(code.author)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textMuted)

                Text(code.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.textMuted)
            }

            Spacer()

            Text(code.category)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.Colors.accent.opacity(0.2))
                .foregroundColor(Theme.Colors.accent)
                .cornerRadius(16)
        }
    }

    private var descriptionSection: some View {
        Text(code.description)
            .font(.system(size: 15))
            .foregroundColor(Theme.Colors.textSecondary)
    }

    private var codeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("代码")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                Button {
                    UIPasteboard.general.string = code.code
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                        Text("复制")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Theme.Colors.accent)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code.code)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Theme.Colors.secondary)
                    .padding(12)
            }
            .background(Theme.Colors.background)
            .cornerRadius(8)
        }
    }

    private var actionsSection: some View {
        HStack(spacing: 16) {
            Button {
                importCode()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("导入到编辑器")
                }
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.Colors.accent)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            Button {
                viewModel.likeCode(code)
            } label: {
                HStack {
                    Image(systemName: "heart")
                    Text("\(code.likes)")
                }
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Theme.Colors.surface2)
                .foregroundColor(Theme.Colors.textPrimary)
                .cornerRadius(10)
            }
        }
    }

    private func importCode() {
        NotificationCenter.default.post(
            name: .importCodeRequested,
            object: nil,
            userInfo: [
                "title": code.title,
                "code": code.code,
                "language": "python"
            ]
        )
        dismiss()
    }
}

extension Notification.Name {
    static let importCodeRequested = Notification.Name("importCodeRequested")
}

#Preview {
    CodeSharingView()
        .environmentObject(AppState())
}
