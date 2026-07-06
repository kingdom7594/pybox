import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Tab = .editor
    @State private var bottomInset: CGFloat = 0

    enum Tab: String, CaseIterable {
        case files, editor, terminal, ai, more

        var title: String {
            switch self {
            case .files: return "文件"
            case .editor: return "编辑"
            case .terminal: return "终端"
            case .ai: return "AI"
            case .more: return "更多"
            }
        }

        var icon: String {
            switch self {
            case .files: return "folder.fill"
            case .editor: return "chevron.left.forwardslash.chevron.right"
            case .terminal: return "terminal.fill"
            case .ai: return "lightbulb.fill"
            case .more: return "ellipsis"
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                content
                CustomTabBar(selectedTab: $selectedTab, bottomInset: geo.safeAreaInsets.bottom)
            }
            .background(Theme.Colors.background.ignoresSafeArea())
            .ignoresSafeArea(edges: .bottom)
            .onAppear { bottomInset = geo.safeAreaInsets.bottom }
        }
        .themed()
        .toastOverlay()
        .onReceive(NotificationCenter.default.publisher(for: .openFile)) { _ in
            selectedTab = .editor
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToTab)) { note in
            if let tab = note.object as? Tab {
                selectedTab = tab
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .files:
            FileBrowserView()
        case .editor:
            EditorView()
        case .terminal:
            TerminalView()
        case .ai:
            AIAssistantView()
        case .more:
            MoreView()
        }
    }
}

extension Notification.Name {
    static let switchToTab = Notification.Name("switchToTab")
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
