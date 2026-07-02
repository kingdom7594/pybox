import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Tab = .files
    
    enum Tab: String, CaseIterable {
        case files = "文件"
        case editor = "编辑"
        case terminal = "终端"
        case ai = "AI"
        case settings = "设置"
        
        var icon: String {
            switch self {
            case .files: return "folder.fill"
            case .editor: return "chevron.left.forwardslash.chevron.right"
            case .terminal: return "terminal.fill"
            case .ai: return "sparkles"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                FileBrowserView()
                    .tag(Tab.files)
                    .tabItem {
                        Label(Tab.files.rawValue, systemImage: Tab.files.icon)
                    }
                
                EditorView()
                    .tag(Tab.editor)
                    .tabItem {
                        Label(Tab.editor.rawValue, systemImage: Tab.editor.icon)
                    }
                
                TerminalView()
                    .tag(Tab.terminal)
                    .tabItem {
                        Label(Tab.terminal.rawValue, systemImage: Tab.terminal.icon)
                    }
                
                AIAssistantView()
                    .tag(Tab.ai)
                    .tabItem {
                        Label(Tab.ai.rawValue, systemImage: Tab.ai.icon)
                    }
                
                NavigationStack {
                    SettingsView()
                }
                .tag(Tab.settings)
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
                }
            }
            .tint(Theme.Colors.primary)
        }
        .background(Theme.Colors.background)
        .onReceive(NotificationCenter.default.publisher(for: .openFile)) { _ in
            selectedTab = .editor
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}