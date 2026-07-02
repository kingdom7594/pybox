import SwiftUI

struct RunHistoryView: View {
    @StateObject private var viewModel = RunHistoryViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                filterBar
                historyList
            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("运行历史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            viewModel.clearAll()
                        } label: {
                            Label("清空全部", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("搜索文件名、代码或输出", text: $viewModel.searchText)
                .textFieldStyle(.plain)
            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var filterBar: some View {
        HStack {
            Toggle(isOn: $viewModel.filterSuccessOnly) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.caption)
                    Text("仅成功")
                        .font(.caption)
                }
            }
            .toggleStyle(.button)
            .tint(.green)
            Spacer()
            Text("共 \(viewModel.filteredRecords.count) / \(viewModel.totalCount) 条")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var historyList: some View {
        if viewModel.filteredRecords.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)
                Text(viewModel.records.isEmpty ? "暂无运行历史" : "没有匹配的记录")
                    .font(.headline)
                    .foregroundColor(.secondary)
                if viewModel.records.isEmpty {
                    Text("运行 Python 脚本后会显示在这里")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(viewModel.filteredRecords) { record in
                    NavigationLink {
                        RunHistoryDetailView(record: record)
                    } label: {
                        RunHistoryRow(record: record, formattedTime: viewModel.formatTimestamp(record.timestamp))
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.delete(record)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

struct RunHistoryRow: View {
    let record: RunRecord
    let formattedTime: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(record.wasSuccess ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: record.wasSuccess ? "checkmark" : "xmark")
                    .foregroundColor(record.wasSuccess ? .green : .red)
                    .font(.system(size: 16, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.fileName)
                        .font(.body.weight(.medium))
                        .lineLimit(1)
                    Spacer()
                    Text(record.durationFormatted)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(uiColor: .tertiarySystemBackground))
                        .cornerRadius(4)
                }
                Text(formattedTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                if let output = record.output, !output.isEmpty {
                    Text(output.prefix(80) + (output.count > 80 ? "..." : ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                } else if let error = record.error {
                    Text(error.prefix(80))
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct RunHistoryDetailView: View {
    let record: RunRecord
    @State private var selectedTab: Tab = .output

    enum Tab: String, CaseIterable {
        case output = "输出"
        case code = "代码"
        case error = "错误"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection

            Picker("", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            contentSection
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle(record.fileName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: record.wasSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(record.wasSuccess ? .green : .red)
                Text(record.wasSuccess ? "运行成功" : "运行失败")
                    .font(.headline)
                Spacer()
            }
            HStack(spacing: 16) {
                Label(record.durationFormatted, systemImage: "clock")
                Label(formatTime(record.timestamp), systemImage: "calendar")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
    }

    @ViewBuilder
    private var contentSection: some View {
        ScrollView {
            Text(contentForTab)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(selectedTab == .error ? .red : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .textSelection(.enabled)
        }
    }

    private var contentForTab: String {
        switch selectedTab {
        case .output: return record.output ?? "(无输出)"
        case .code: return record.code
        case .error: return record.error ?? "(无错误)"
        }
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f.string(from: date)
    }
}

#Preview {
    RunHistoryView()
}
