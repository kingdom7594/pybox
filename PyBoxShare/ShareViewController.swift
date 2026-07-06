import UIKit
import Social
import UniformTypeIdentifiers

@objc(ShareViewController)
class ShareViewController: UIViewController {

    private let appGroupID = "group.com.huang.pybox.ide"
    private let typeIdentifierPython = "public.python-script"
    private let typeIdentifierText = "public.plain-text"

    private var activityIndicator: UIActivityIndicatorView!
    private var statusLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        handleIncomingItems()
    }

    private func setupUI() {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        let imageView = UIImageView(image: UIImage(systemName: "doc.text.fill"))
        imageView.tintColor = .systemGreen
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(imageView)

        statusLabel = UILabel()
        statusLabel.text = "正在导入到 PyBox..."
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.font = .systemFont(ofSize: 16)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(statusLabel)

        activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        containerView.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),

            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),

            statusLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            activityIndicator.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            activityIndicator.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }

    @objc private func cancelTapped() {
        extensionContext?.cancelRequest(withError: NSError(domain: "PyBoxShare", code: 0))
    }

    private func handleIncomingItems() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            showError("没有接收到文件")
            return
        }

        var collectedURLs: [URL] = []
        let dispatchGroup = DispatchGroup()

        for item in extensionItems {
            for attachment in item.attachments ?? [] {
                if attachment.hasItemConformingToTypeIdentifier(typeIdentifierPython) ||
                   attachment.hasItemConformingToTypeIdentifier(typeIdentifierText) ||
                   attachment.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                    dispatchGroup.enter()
                    attachment.loadFileRepresentation(forTypeIdentifier: attachment.registeredTypeIdentifiers.first ?? typeIdentifierText) { url, error in
                        defer { dispatchGroup.leave() }
                        guard let url = url else {
                            NSLog("[PyBoxShare] loadFileRepresentation error: \(error?.localizedDescription ?? "unknown")")
                            return
                        }
                        do {
                            let tempURL = FileManager.default.temporaryDirectory
                                .appendingPathComponent(UUID().uuidString)
                                .appendingPathComponent(url.lastPathComponent)
                            try? FileManager.default.removeItem(at: tempURL)
                            try FileManager.default.copyItem(at: url, to: tempURL)
                            collectedURLs.append(tempURL)
                        } catch {
                            NSLog("[PyBoxShare] Failed to copy: \(error.localizedDescription)")
                        }
                    }
                } else if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    dispatchGroup.enter()
                    attachment.loadDataRepresentation(forTypeIdentifier: UTType.plainText.identifier) { data, error in
                        defer { dispatchGroup.leave() }
                        guard let data = data,
                              let text = String(data: data, encoding: .utf8) else { return }
                        let filename = "shared_\(Int(Date().timeIntervalSince1970)).py"
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                        do {
                            try text.write(to: tempURL, atomically: true, encoding: .utf8)
                            collectedURLs.append(tempURL)
                        } catch {
                            NSLog("[PyBoxShare] Failed to write text: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            if collectedURLs.isEmpty {
                self.showError("没有可导入的文件")
            } else {
                self.saveToSharedContainer(urls: collectedURLs)
            }
        }
    }

    private func saveToSharedContainer(urls: [URL]) {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            showError("App Group 不可用")
            return
        }

        let inbox = containerURL.appendingPathComponent("Inbox", isDirectory: true)
        try? FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)

        for url in urls {
            let dest = inbox.appendingPathComponent(url.lastPathComponent)
            do {
                if FileManager.default.fileExists(atPath: dest.path) {
                    try FileManager.default.removeItem(at: dest)
                }
                try FileManager.default.copyItem(at: url, to: dest)
                try? FileManager.default.removeItem(at: url)
                NSLog("[PyBoxShare] Imported \(url.lastPathComponent) to inbox")
            } catch {
                NSLog("[PyBoxShare] Failed to copy to inbox: \(error.localizedDescription)")
            }
        }

        let count = urls.count
        statusLabel.text = "✅ 已导入 \(count) 个文件到 PyBox"
        activityIndicator.stopAnimating()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }

    private func showError(_ message: String) {
        statusLabel.text = "❌ \(message)"
        statusLabel.textColor = .systemRed
        activityIndicator.stopAnimating()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.extensionContext?.cancelRequest(withError: NSError(domain: "PyBoxShare", code: 0))
        }
    }
}
