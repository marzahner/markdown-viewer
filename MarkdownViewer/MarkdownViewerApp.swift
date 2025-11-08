import SwiftUI
import UniformTypeIdentifiers
import Combine

// MARK: - Theme Definition
enum MarkdownTheme: String, CaseIterable, Identifiable {
    case gameboy = "Game Boy"
    case macos = "macOS"
    case deepBlue = "Deep Blue"

    var id: String { rawValue }

    var background: Color {
        switch self {
        case .gameboy:
            return Color(red: 0.608, green: 0.737, blue: 0.059) // #9bbc0f
        case .macos:
            return Color(NSColor.textBackgroundColor)
        case .deepBlue:
            return Color(red: 0.02, green: 0.063, blue: 0.961) // #0510F5
        }
    }

    var textPrimary: Color {
        switch self {
        case .gameboy:
            return Color(red: 0.059, green: 0.220, blue: 0.059) // #0f380f
        case .macos:
            return Color(NSColor.textColor)
        case .deepBlue:
            return Color.white
        }
    }

    var textSecondary: Color {
        switch self {
        case .gameboy:
            return Color(red: 0.192, green: 0.384, blue: 0.188) // #306230
        case .macos:
            return Color(NSColor.secondaryLabelColor)
        case .deepBlue:
            return Color(white: 0.8)
        }
    }

    var accent: Color {
        switch self {
        case .gameboy:
            return Color(red: 0.545, green: 0.675, blue: 0.059) // #8bac0f
        case .macos:
            return Color.accentColor
        case .deepBlue:
            return Color(white: 0.6)
        }
    }

    var codeBackground: Color {
        switch self {
        case .gameboy:
            return Color(red: 0.059, green: 0.220, blue: 0.059) // #0f380f
        case .macos:
            return Color(NSColor.controlBackgroundColor)
        case .deepBlue:
            return Color.black
        }
    }

    var codeText: Color {
        switch self {
        case .gameboy:
            return Color(red: 0.608, green: 0.737, blue: 0.059) // #9bbc0f
        case .macos:
            return Color(NSColor.textColor)
        case .deepBlue:
            return Color.white
        }
    }
}

// MARK: - File Info
struct FileInfo: Codable {
    let path: String
    let dateAdded: Date
}

// MARK: - Recent Files Manager
class RecentFilesManager: ObservableObject {
    static let shared = RecentFilesManager()
    @Published var recentFiles: [FileInfo] = []
    private let maxRecent = 5
    private let key = "recentMarkdownFiles"

    init() {
        loadRecent()
    }

    func addFile(_ url: URL) {
        // Remove if already exists
        recentFiles.removeAll { $0.path == url.path }
        // Add to front with current date
        let fileInfo = FileInfo(path: url.path, dateAdded: Date())
        recentFiles.insert(fileInfo, at: 0)
        // Limit to max
        if recentFiles.count > maxRecent {
            recentFiles = Array(recentFiles.prefix(maxRecent))
        }
        saveRecent()
    }

    func getURL(for fileInfo: FileInfo) -> URL? {
        let url = URL(fileURLWithPath: fileInfo.path)
        return FileManager.default.fileExists(atPath: fileInfo.path) ? url : nil
    }

    private func saveRecent() {
        if let encoded = try? JSONEncoder().encode(recentFiles) {
            UserDefaults.standard.set(encoded, forKey: key)
            print("Saved recent files: \(recentFiles.map { $0.path })")
        }
    }

    private func loadRecent() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([FileInfo].self, from: data) else {
            print("No recent files found")
            return
        }

        recentFiles = decoded.filter { fileInfo in
            let exists = FileManager.default.fileExists(atPath: fileInfo.path)
            print("Checking file: \(fileInfo.path), exists: \(exists)")
            return exists
        }
        print("Loaded \(recentFiles.count) recent files")
    }
}

// MARK: - Window State Manager
class WindowStateManager {
    static let shared = WindowStateManager()
    
    func saveWindowState(_ window: NSWindow, forFile url: URL) {
        let key = "window_\(url.path.hash)"
        let frame = window.frame
        UserDefaults.standard.set(NSStringFromRect(frame), forKey: key)
    }
    
    func restoreWindowState(forFile url: URL) -> NSRect? {
        let key = "window_\(url.path.hash)"
        guard let frameString = UserDefaults.standard.string(forKey: key) else { return nil }
        return NSRectFromString(frameString)
    }
}

@main
struct MarkdownViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: "Markdown Viewer")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        setupPopover()
    }
    
    func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 240, height: 300)
        popover?.behavior = .applicationDefined  // Stays open until explicitly closed
        popover?.contentViewController = NSHostingController(rootView: MenuView(closeAction: { [weak self] in
            self?.popover?.performClose(nil)
        }))
    }
    
    @objc func togglePopover() {
        guard statusItem?.button != nil else { return }
        
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                if let button = statusItem?.button {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                }
            }
        }
    }
}

struct MenuView: View {
    @State private var isDragging = false
    @State private var selectedTheme: MarkdownTheme = .gameboy
    @State private var lastDroppedDate: Date?
    @ObservedObject private var recentFiles = RecentFilesManager.shared
    let closeAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
            HStack {
                Text("Markdown Viewer")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button(action: closeAction) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))

            VStack(spacing: 12) {
                // Improved drop zone with gradient and animation
                VStack(spacing: 10) {
                    Image(systemName: isDragging ? "arrow.down.circle.fill" : "doc.text.fill")
                        .font(.system(size: 36))
                        .foregroundColor(isDragging ? .accentColor : .secondary)
                        .symbolRenderingMode(.hierarchical)
                        .animation(.spring(response: 0.3), value: isDragging)

                    Text(isDragging ? "Drop here" : "Drop .md file")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isDragging ? .accentColor : .primary)

                    Text("or click to browse")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDragging ?
                            LinearGradient(colors: [Color.accentColor.opacity(0.15), Color.accentColor.opacity(0.05)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [Color.gray.opacity(0.08), Color.gray.opacity(0.03)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isDragging ? Color.accentColor.opacity(0.5) : Color.gray.opacity(0.2),
                            style: StrokeStyle(lineWidth: 2, dash: isDragging ? [] : [5, 3])
                        )
                )
                .scaleEffect(isDragging ? 1.02 : 1.0)
                .animation(.spring(response: 0.3), value: isDragging)
                .onDrop(of: [UTType.fileURL], isTargeted: $isDragging) { providers in
                    handleDrop(providers: providers)
                    return true
                }
                .padding(.top, 8)

                // Date added below drop zone
                if let date = lastDroppedDate {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 9))
                        Text("Added \(formatDate(date))")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.secondary.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                }

                // Theme selector - compact design
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text("Theme")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 8) {
                        ForEach(MarkdownTheme.allCases) { theme in
                            Button(action: {
                                selectedTheme = theme
                            }) {
                                VStack(spacing: 4) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(theme.background)
                                            .frame(width: 56, height: 36)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .strokeBorder(selectedTheme == theme ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: selectedTheme == theme ? 2.5 : 1)
                                            )
                                            .shadow(color: selectedTheme == theme ? Color.accentColor.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)

                                        if selectedTheme == theme {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.accentColor)
                                                .background(
                                                    Circle()
                                                        .fill(Color.white)
                                                        .frame(width: 12, height: 12)
                                                )
                                        }
                                    }
                                    Text(theme.rawValue)
                                        .font(.system(size: 9, weight: selectedTheme == theme ? .semibold : .regular))
                                        .foregroundColor(selectedTheme == theme ? .primary : .secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 8)
                
                if !recentFiles.recentFiles.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recent")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(recentFiles.recentFiles, id: \.path) { fileInfo in
                                Button(action: {
                                    if let url = recentFiles.getURL(for: fileInfo) {
                                        openMarkdownWindow(url: url)
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "doc.text")
                                                .font(.system(size: 10))
                                            Text(URL(fileURLWithPath: fileInfo.path).lastPathComponent)
                                                .font(.system(size: 11))
                                                .lineLimit(1)
                                            Spacer()
                                        }
                                        Text("Added: \(formatDate(fileInfo.dateAdded))")
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary.opacity(0.5))
                                    }
                                    .contentShape(Rectangle())
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 4)
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.primary)
                                .background(Color.gray.opacity(0.05))
                            }
                        }
                    }
                }
                
                Divider()
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack {
                        Image(systemName: "power")
                            .font(.system(size: 11))
                        Text("Quit")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(width: 240)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil),
                      url.pathExtension == "md" else { return }

                DispatchQueue.main.async {
                    lastDroppedDate = Date()
                    openMarkdownWindow(url: url)
                }
            }
        }
    }

    func openMarkdownWindow(url: URL) {
        print("Opening file: \(url.path)")
        RecentFilesManager.shared.addFile(url)

        let savedFrame = WindowStateManager.shared.restoreWindowState(forFile: url)
        let defaultFrame = NSRect(x: 0, y: 0, width: 900, height: 700)

        let window = NSWindow(
            contentRect: savedFrame ?? defaultFrame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = url.lastPathComponent
        window.contentView = NSHostingView(rootView: MarkdownView(fileURL: url, window: window, theme: selectedTheme))

        if savedFrame == nil {
            window.center()
        }

        window.makeKeyAndOrderFront(nil)

        // Save position on move/resize
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: window,
            queue: .main
        ) { _ in
            WindowStateManager.shared.saveWindowState(window, forFile: url)
        }

        NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: window,
            queue: .main
        ) { _ in
            WindowStateManager.shared.saveWindowState(window, forFile: url)
        }
    }
}

// MARK: - Markdown Block Types
enum MarkdownBlock {
    case header(String, level: Int)
    case paragraph(String)
    case listItem(String)
    case blockQuote(String)
    case codeBlock(String, language: String)
    case image(url: String, alt: String)
    case space
}

struct MarkdownView: View {
    let fileURL: URL
    let window: NSWindow?
    let theme: MarkdownTheme
    @State private var markdownString: String = ""
    @State private var isLoading = true
    @State private var parsedBlocks: [MarkdownBlock] = []

    init(fileURL: URL, window: NSWindow? = nil, theme: MarkdownTheme = .gameboy) {
        self.fileURL = fileURL
        self.window = window
        self.theme = theme
    }
    
    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .tint(theme.textPrimary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(parsedBlocks.indices, id: \.self) { index in
                            renderBlock(parsedBlocks[index])
                        }
                    }
                    .padding(40)
                    .frame(maxWidth: 800)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .onAppear {
            loadMarkdown()
        }
    }
    
    func loadMarkdown() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                let blocks = parseMarkdown(content)
                DispatchQueue.main.async {
                    self.parsedBlocks = blocks
                    self.markdownString = content
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.parsedBlocks = [.paragraph("Error loading file: \(error.localizedDescription)")]
                    self.isLoading = false
                }
            }
        }
    }
    
    func parseMarkdown(_ markdown: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = markdown.components(separatedBy: .newlines)
        var i = 0
        
        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Code blocks
            if trimmed.hasPrefix("```") {
                let language = String(trimmed.dropFirst(3).trimmingCharacters(in: .whitespaces))
                var codeLines: [String] = []
                i += 1
                
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                
                blocks.append(.codeBlock(codeLines.joined(separator: "\n"), language: language))
                i += 1
                continue
            }
            
            // Headers
            if trimmed.hasPrefix("######") {
                blocks.append(.header(String(trimmed.dropFirst(7)), level: 6))
            } else if trimmed.hasPrefix("#####") {
                blocks.append(.header(String(trimmed.dropFirst(6)), level: 5))
            } else if trimmed.hasPrefix("####") {
                blocks.append(.header(String(trimmed.dropFirst(5)), level: 4))
            } else if trimmed.hasPrefix("###") {
                blocks.append(.header(String(trimmed.dropFirst(4)), level: 3))
            } else if trimmed.hasPrefix("##") {
                blocks.append(.header(String(trimmed.dropFirst(3)), level: 2))
            } else if trimmed.hasPrefix("#") {
                blocks.append(.header(String(trimmed.dropFirst(2)), level: 1))
            }
            // List items
            else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
                blocks.append(.listItem(String(trimmed.dropFirst(2))))
            }
            // Numbered lists
            else if let match = trimmed.range(of: "^\\d+\\. ", options: .regularExpression) {
                blocks.append(.listItem(String(trimmed[match.upperBound...])))
            }
            // Block quote
            else if trimmed.hasPrefix("> ") {
                blocks.append(.blockQuote(String(trimmed.dropFirst(2))))
            }
            // Images
            else if trimmed.range(of: "^!\\[([^\\]]*)\\]\\(([^\\)]+)(?:\\s+\"([^\"]+)\")?\\)", options: .regularExpression) != nil {
                let imagePattern = "^!\\[([^\\]]*)\\]\\(([^\\)]+)(?:\\s+\"([^\"]+)\")?\\)"
                if let regex = try? NSRegularExpression(pattern: imagePattern),
                   let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) {
                    let altText = match.range(at: 1).location != NSNotFound ? String(trimmed[Range(match.range(at: 1), in: trimmed)!]) : ""
                    let url = match.range(at: 2).location != NSNotFound ? String(trimmed[Range(match.range(at: 2), in: trimmed)!]) : ""
                    blocks.append(.image(url: url, alt: altText))
                }
            }
            // Empty line
            else if trimmed.isEmpty {
                blocks.append(.space)
            }
            // Regular paragraph
            else {
                blocks.append(.paragraph(line))
            }
            
            i += 1
        }
        
        return blocks
    }
    
    @ViewBuilder
    func renderBlock(_ block: MarkdownBlock) -> some View {
        switch block {
        case .header(let text, let level):
            renderHeader(text, level: level)
        case .paragraph(let text):
            renderParagraph(text)
        case .listItem(let text):
            renderListItem(text)
        case .blockQuote(let text):
            renderBlockQuote(text)
        case .codeBlock(let code, let language):
            renderCodeBlock(code, language: language)
        case .image(let url, let alt):
            renderImage(url: url, alt: alt)
        case .space:
            Spacer().frame(height: 8)
        }
    }
    
    func renderHeader(_ text: String, level: Int) -> some View {
        let sizes: [CGFloat] = [32, 28, 24, 20, 18, 16]
        return Text(parseInlineMarkdown(text))
            .font(.system(size: sizes[min(level - 1, 5)], weight: .bold, design: .monospaced))
            .foregroundColor(theme.textPrimary)
            .padding(.top, 8)
            .textSelection(.enabled)
    }

    func renderParagraph(_ text: String) -> some View {
        Text(parseInlineMarkdown(text))
            .font(.system(size: 15, weight: .regular, design: .monospaced))
            .foregroundColor(theme.textSecondary)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }

    func renderListItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(theme.textPrimary)
            Text(parseInlineMarkdown(text))
                .font(.system(size: 15, weight: .regular, design: .monospaced))
                .foregroundColor(theme.textSecondary)
                .textSelection(.enabled)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    func renderBlockQuote(_ text: String) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(theme.textSecondary)
                .frame(width: 4)
            Text(parseInlineMarkdown(text))
                .font(.system(size: 15, weight: .regular, design: .monospaced))
                .foregroundColor(theme.textSecondary.opacity(0.8))
                .textSelection(.enabled)
        }
        .padding(.vertical, 4)
        .fixedSize(horizontal: false, vertical: true)
    }
    
    func renderCodeBlock(_ code: String, language: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if !language.isEmpty {
                    Text(language.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.codeText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }

                Spacer()

                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(code, forType: .string)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                        Text("COPY")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(theme.codeText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.codeBackground.opacity(0.5))
                }
                .buttonStyle(.plain)
                .padding(4)
            }
            .background(theme.codeBackground)

            ScrollView(.horizontal, showsIndicators: true) {
                Text(code)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(theme.codeText)
                    .padding(16)
                    .textSelection(.enabled)
            }
            .background(theme.codeBackground)
        }
    }

    func renderImage(url: String, alt: String) -> some View {
        VStack {
            if url.hasPrefix("http://") || url.hasPrefix("https://") {
                // Remote image
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .padding()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 600)
                            .cornerRadius(8)
                    case .failure:
                        HStack(spacing: 8) {
                            Image(systemName: "photo.badge.exclamationmark")
                                .foregroundColor(theme.textSecondary)
                            Text(alt.isEmpty ? "Failed to load image" : alt)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(theme.textSecondary)
                        }
                        .padding()
                        .background(theme.accent.opacity(0.1))
                        .cornerRadius(8)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                // Local image - resolve relative to markdown file
                let imageURL = resolveLocalImageURL(url)
                if let imageURL = imageURL,
                   let nsImage = NSImage(contentsOf: imageURL) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 600)
                        .cornerRadius(8)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.badge.exclamationmark")
                            .foregroundColor(theme.textSecondary)
                        Text(alt.isEmpty ? "Image not found: \(url)" : alt)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding()
                    .background(theme.accent.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 8)
    }

    func resolveLocalImageURL(_ path: String) -> URL? {
        // If absolute path
        if path.hasPrefix("/") {
            return URL(fileURLWithPath: path)
        }

        // Relative to markdown file directory
        let baseURL = fileURL.deletingLastPathComponent()
        return baseURL.appendingPathComponent(path)
    }

    func parseInlineMarkdown(_ text: String) -> AttributedString {
        var processedText = text
        var ranges: [(range: Range<String.Index>, type: String, originalLength: Int)] = []

        // Find all markdown patterns and their positions
        // Bold **text**
        let boldPattern = "\\*\\*(.+?)\\*\\*"
        if let regex = try? NSRegularExpression(pattern: boldPattern) {
            let matches = regex.matches(in: processedText, range: NSRange(processedText.startIndex..., in: processedText))
            for match in matches {
                if let contentRange = Range(match.range(at: 1), in: processedText) {
                    ranges.append((range: contentRange, type: "bold", originalLength: match.range.length))
                }
            }
        }

        // Inline code `code` - process before italic to avoid conflicts
        let codePattern = "`([^`]+)`"
        if let regex = try? NSRegularExpression(pattern: codePattern) {
            let matches = regex.matches(in: processedText, range: NSRange(processedText.startIndex..., in: processedText))
            for match in matches {
                if let contentRange = Range(match.range(at: 1), in: processedText) {
                    ranges.append((range: contentRange, type: "code", originalLength: match.range.length))
                }
            }
        }

        // Italic *text*
        let italicPattern = "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)"
        if let regex = try? NSRegularExpression(pattern: italicPattern) {
            let matches = regex.matches(in: processedText, range: NSRange(processedText.startIndex..., in: processedText))
            for match in matches {
                if let range = Range(match.range, in: processedText),
                   let contentRange = Range(match.range(at: 1), in: processedText) {
                    // Check if this range is not inside a code block
                    let isInCode = ranges.contains { $0.type == "code" && range.lowerBound >= $0.range.lowerBound && range.upperBound <= $0.range.upperBound }
                    if !isInCode {
                        ranges.append((range: contentRange, type: "italic", originalLength: match.range.length))
                    }
                }
            }
        }

        // Remove markdown syntax
        processedText = processedText.replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "$1", options: .regularExpression)
        processedText = processedText.replacingOccurrences(of: "`([^`]+)`", with: "$1", options: .regularExpression)
        processedText = processedText.replacingOccurrences(of: "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)", with: "$1", options: .regularExpression)

        var result = AttributedString(processedText)

        // Apply formatting to the content text (without markers)
        // Bold
        for (origRange, type, _) in ranges where type == "bold" {
            let content = String(text[origRange])
            if let range = result.range(of: content) {
                result[range].font = .system(size: 15, weight: .bold, design: .monospaced)
            }
        }

        // Code
        for (origRange, type, _) in ranges where type == "code" {
            let content = String(text[origRange])
            if let range = result.range(of: content) {
                result[range].font = .system(size: 14, weight: .semibold, design: .monospaced)
                result[range].foregroundColor = theme.textPrimary
                result[range].backgroundColor = theme.accent.opacity(0.5)
            }
        }

        // Italic
        for (origRange, type, _) in ranges where type == "italic" {
            let content = String(text[origRange])
            if let range = result.range(of: content) {
                result[range].font = .system(size: 15, weight: .regular, design: .monospaced).italic()
            }
        }

        return result
    }
    
    func highlightCode(_ code: String, language: String) -> AttributedString {
        var result = AttributedString(code)
        result.foregroundColor = theme.accent

        let keywords: [String] = {
            switch language.lowercased() {
            case "swift":
                return ["func", "var", "let", "class", "struct", "enum", "if", "else", "for", "while", "return", "import", "guard", "switch", "case"]
            case "python":
                return ["def", "class", "if", "else", "elif", "for", "while", "return", "import", "from", "try", "except"]
            case "javascript", "js", "typescript", "ts":
                return ["function", "const", "let", "var", "if", "else", "for", "while", "return", "import", "export", "class", "async", "await"]
            default:
                return []
            }
        }()

        for keyword in keywords {
            let pattern = "\\b\(keyword)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: code, range: NSRange(code.startIndex..., in: code))
                for match in matches {
                    if let range = Range(match.range, in: code),
                       let attrRange = result.range(of: String(code[range])) {
                        result[attrRange].foregroundColor = theme.background
                        result[attrRange].font = .system(size: 13, weight: .bold, design: .monospaced)
                    }
                }
            }
        }

        return result
    }
}

extension NSFont {
    func withTraits(_ traits: NSFontDescriptor.SymbolicTraits) -> NSFont {
        let descriptor = self.fontDescriptor.withSymbolicTraits(traits)
        return NSFont(descriptor: descriptor, size: 0) ?? self
    }
}
