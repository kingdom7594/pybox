import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct PyBoxEntry: TimelineEntry {
    let date: Date
    let recentProjects: [WidgetProject]
    let lastOutput: String
}

struct WidgetProject: Identifiable, Codable {
    let id: String
    let name: String
    let modifiedAt: Date
}

// MARK: - Provider

struct PyBoxProvider: TimelineProvider {
    func placeholder(in context: Context) -> PyBoxEntry {
        PyBoxEntry(date: Date(), recentProjects: [
            WidgetProject(id: "1", name: "Sample Project", modifiedAt: Date())
        ], lastOutput: "")
    }

    func getSnapshot(in context: Context, completion: @escaping (PyBoxEntry) -> Void) {
        let entry = PyBoxEntry(date: Date(), recentProjects: loadProjects(), lastOutput: loadLastOutput())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PyBoxEntry>) -> Void) {
        let entry = PyBoxEntry(date: Date(), recentProjects: loadProjects(), lastOutput: loadLastOutput())
        let nextUpdate = Date().addingTimeInterval(60 * 15)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    // MARK: - Data Loading

    private func loadProjects() -> [WidgetProject] {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.pybox.ide") else {
            return []
        }
        let fileURL = containerURL.appendingPathComponent("Library/Preferences/recent_projects.json")
        guard let data = try? Data(contentsOf: fileURL),
              let projects = try? JSONDecoder().decode([WidgetProject].self, from: data) else {
            return []
        }
        return projects
    }

    private func loadLastOutput() -> String {
        let defaults = UserDefaults(suiteName: "group.com.pybox.ide")
        return defaults?.string(forKey: "last_output") ?? ""
    }
}

// MARK: - Widget Views

struct PyBoxWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: PyBoxEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .foregroundColor(.green)
                Text("PyBox")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            if let first = entry.recentProjects.first {
                Text(first.name)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text("Tap to open")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text("No projects")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("🐍 Ready")
                .font(.caption2)
                .foregroundColor(.green)
        }
        .padding()
        .widgetURL(URL(string: "pybox://open"))
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .foregroundColor(.green)
                Text("PyBox")
                    .font(.headline)
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Divider()

            if entry.recentProjects.isEmpty {
                Text("No recent projects")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(entry.recentProjects.prefix(3)) { project in
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text(project.name)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Text(project.modifiedAt, style: .date)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if !entry.lastOutput.isEmpty {
                Divider()
                Text(entry.lastOutput)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .widgetURL(URL(string: "pybox://open"))
    }
}

// MARK: - Widget Definition

@main
struct PyBoxWidget: Widget {
    let kind: String = "PyBoxWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PyBoxProvider()) { entry in
            if #available(iOS 17.0, *) {
                PyBoxWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                PyBoxWidgetView(entry: entry)
                    .padding()
                    .background(Color(.systemBackground))
            }
        }
        .configurationDisplayName("PyBox")
        .description("Quick access to your Python projects.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
