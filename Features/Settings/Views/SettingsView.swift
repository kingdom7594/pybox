import SwiftUI

struct SettingsView: View {
    @AppStorage("editorFontSize") private var editorFontSize: Double = 14
    @AppStorage("autoSave") private var autoSave: Bool = true
    @AppStorage("aiModel") private var aiModel: String = "deepseek-v4-flash"
    @AppStorage("deepseekApiKey") private var deepseekApiKey: String = ""
    @AppStorage("terminalFontSize") private var terminalFontSize: Double = 12
    @AppStorage("showLineNumbers") private var showLineNumbers: Bool = true
    @AppStorage("autoComplete") private var autoComplete: Bool = true
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("hapticEnabled") private var hapticEnabled: Bool = true
    @AppStorage("aiPrivacyMode") private var aiPrivacyMode: Bool = false
    
    @State private var showingApiKeyAlert = false
    @State private var apiKeyForDisplay: String = ""
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        Form {
            Section("外观") {
                Picker("主题", selection: $themeManager.mode) {
                    ForEach(Theme.AppearanceMode.allCases) { mode in
                        HStack {
                            Image(systemName: mode.icon)
                            Text(mode.displayName)
                        }
                        .tag(mode)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Editor") {
                HStack {
                    Text("Font Size")
                    Spacer()
                    Stepper("\(Int(editorFontSize))", value: $editorFontSize, in: 10...24)
                }
                Toggle("Show Line Numbers", isOn: $showLineNumbers)
                Toggle("Auto Complete", isOn: $autoComplete)
                Toggle("Auto Save", isOn: $autoSave)
            }

            Section("Terminal") {
                HStack {
                    Text("Font Size")
                    Spacer()
                    Stepper("\(Int(terminalFontSize))", value: $terminalFontSize, in: 10...20)
                }
                NavigationLink {
                    KeyboardShortcutsView()
                } label: {
                    HStack {
                        Image(systemName: "keyboard")
                        Text("快捷键参考")
                    }
                }
            }
            
            Section("AI Assistant") {
                Picker("Model", selection: $aiModel) {
                    Text("DeepSeek V4 Flash (快速)").tag("deepseek-v4-flash")
                    Text("DeepSeek V4 Pro (高质量)").tag("deepseek-v4-pro")
                    Text("DeepSeek Reasoner (CoT 推理)").tag("deepseek-reasoner")
                }

                HStack {
                    Text("API Key")
                    Spacer()
                    if deepseekApiKey.isEmpty {
                        Text("未配置")
                            .foregroundColor(.red)
                    } else {
                        Button("查看/修改") {
                            apiKeyForDisplay = deepseekApiKey
                            showingApiKeyAlert = true
                        }
                        .foregroundColor(.blue)
                    }
                }

                Toggle(isOn: $aiPrivacyMode) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("隐私模式")
                        Text("开启后 AI 不会读取你的代码")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Preferences") {
                Toggle("Sound Effects", isOn: $soundEnabled)
                Toggle("Haptic Feedback", isOn: $hapticEnabled)
            }
            
            Section("Storage") {
                HStack {
                    Text("Projects")
                    Spacer()
                    Text("\(projectCount())")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Total Files")
                    Spacer()
                    Text("\(fileCount())")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text("MVP")
                        .foregroundColor(.secondary)
                }
                if let docsURL = URL(string: "https://pybox.app/docs") {
                    Link("Documentation", destination: docsURL)
                }
                if let issuesURL = URL(string: "https://github.com/pybox/app/issues") {
                    Link("Report Issue", destination: issuesURL)
                }
                if let privacyURL = URL(string: "https://pybox.app/privacy") {
                    Link("Privacy Policy", destination: privacyURL)
                }
            }
            
            Section {
                Button("Reset All Settings", role: .destructive) {
                    resetSettings()
                }
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .alert("DeepSeek API Key", isPresented: $showingApiKeyAlert) {
            TextField("API Key", text: $apiKeyForDisplay)
                .textContentType(.password)
            Button("Save") {
                deepseekApiKey = apiKeyForDisplay
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter your DeepSeek API key. Get one at https://platform.deepseek.com")
        }
    }
    
    private func projectCount() -> Int {
        return FileManagerService.shared.getAllProjects().count
    }
    
    private func fileCount() -> Int {
        return FileManagerService.shared.getAllProjects().reduce(0) { $0 + $1.files.count }
    }
    
    private func resetSettings() {
        editorFontSize = 14
        autoSave = true
        aiModel = "deepseek-v4-flash"
        deepseekApiKey = ""
        terminalFontSize = 12
        showLineNumbers = true
        autoComplete = true
        soundEnabled = true
        hapticEnabled = true
        aiPrivacyMode = false
        themeManager.mode = .dark
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}