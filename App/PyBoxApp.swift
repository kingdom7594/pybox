import SwiftUI

@main
struct PyBoxApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var errorHandler = ErrorHandler.shared
    @StateObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(errorHandler)
                .preferredColorScheme(themeManager.mode.swiftUIScheme)
                .onOpenURL { url in
                    appState.handleIncomingURL(url)
                }
                .onAppear {
                    appState.checkPendingScript()
                    appState.checkSharedInbox()
                    // 后台预热 Python 运行时，避免首次 Run 卡顿
                    PythonRuntimeService.shared.warmup()
                    // 后台预热 black formatter
                    BlackFormatterService.shared.warmup()
                }
                .alert(item: $errorHandler.currentAlert) { error in
                    Alert(
                        title: Text(error.title),
                        message: Text(error.message),
                        dismissButton: .default(Text("好的"))
                    )
                }
        }
    }
}