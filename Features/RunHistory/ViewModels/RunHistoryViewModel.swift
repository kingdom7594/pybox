import Foundation
import Combine

@MainActor
class RunHistoryViewModel: ObservableObject {
    @Published var records: [RunRecord] = []
    @Published var searchText: String = ""
    @Published var filterSuccessOnly: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        loadRecords()
        NotificationCenter.default.publisher(for: .runHistoryUpdated)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadRecords()
            }
            .store(in: &cancellables)
    }

    func loadRecords() {
        records = RunHistoryStore.shared.loadRecent(limit: 200)
    }

    var filteredRecords: [RunRecord] {
        var list = records
        if filterSuccessOnly {
            list = list.filter { $0.wasSuccess }
        }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            list = list.filter {
                $0.fileName.lowercased().contains(q) ||
                $0.code.lowercased().contains(q) ||
                ($0.output?.lowercased().contains(q) ?? false)
            }
        }
        return list
    }

    var totalCount: Int { RunHistoryStore.shared.count() }

    func clearAll() {
        RunHistoryStore.shared.clearAll()
        loadRecords()
    }

    func delete(_ record: RunRecord) {
        RunHistoryStore.shared.delete(record)
        loadRecords()
    }

    /// 格式化时间戳
    func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm:ss"
        } else if calendar.isDateInYesterday(date) {
            return "昨天 " + DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
        } else if calendar.dateComponents([.day], from: date, to: Date()).day ?? 0 < 7 {
            formatter.dateFormat = "MM-dd HH:mm"
        } else {
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
        }
        return formatter.string(from: date)
    }
}
