import SwiftUI
import WebKit

struct CodeMirrorView: UIViewRepresentable {
    @Binding var code: String
    var fontSize: CGFloat
    var onCodeChange: ((String) -> Void)?
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        configuration.userContentController.add(context.coordinator, name: "editor")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = UIColor(hex: "#1E1E1E")
        webView.scrollView.backgroundColor = UIColor(hex: "#1E1E1E")
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.bounces = true
        webView.scrollView.alwaysBounceVertical = true
        context.coordinator.webView = webView
        
        if let htmlURL = Bundle.main.url(forResource: "codemirror", withExtension: "html", subdirectory: "WebResources") {
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
        } else if let htmlURL = Bundle.main.url(forResource: "codemirror", withExtension: "html") {
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
        } else if let htmlContent = loadHTMLFromBundle() {
            webView.loadHTMLString(htmlContent, baseURL: nil)
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let script = "if (window.setCode) { window.setCode(\(code.javascriptString)); }"
        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                print("Error setting code: \(error)")
            }
        }
        
        let fontScript = "if (window.setFontSize) { window.setFontSize(\(Int(fontSize))); }"
        webView.evaluateJavaScript(fontScript) { _, error in
            if let error = error {
                print("Error setting font size: \(error)")
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func loadHTMLFromBundle() -> String? {
        if let path = Bundle.main.path(forResource: "codemirror", ofType: "html", inDirectory: "WebResources"),
           let content = try? String(contentsOfFile: path, encoding: .utf8) {
            return content
        }
        if let path = Bundle.main.path(forResource: "codemirror", ofType: "html"),
           let content = try? String(contentsOfFile: path, encoding: .utf8) {
            return content
        }
        return nil
    }
    
    class Coordinator: NSObject, WKScriptMessageHandler {
        var parent: CodeMirrorView
        weak var webView: WKWebView?
        
        init(_ parent: CodeMirrorView) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any],
                  let type = body["type"] as? String else {
                return
            }
            
            switch type {
            case "codeChange":
                if let newCode = body["code"] as? String {
                    DispatchQueue.main.async {
                        self.parent.code = newCode
                        self.parent.onCodeChange?(newCode)
                    }
                }
            case "ready":
                let script = "if (window.setCode) { window.setCode(\(self.parent.code.javascriptString)); }"
                if let webView = self.findWebView() {
                    webView.evaluateJavaScript(script, completionHandler: nil)
                }
            default:
                break
            }
        }
        
        private func findWebView() -> WKWebView? {
            return webView
        }
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: 1
        )
    }
}

extension String {
    var javascriptString: String {
        return self.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}