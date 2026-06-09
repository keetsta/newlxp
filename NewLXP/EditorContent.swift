import Foundation
import SwiftUI

// MARK: - Editor.js parsing

/// Block of an Editor.js document.
enum EditorBlock: Hashable {
    case header(level: Int, text: String)
    case paragraph(text: String)
    case list(ordered: Bool, items: [String])
    case checklist(items: [(checked: Bool, text: String)])
    case table(withHeading: Bool, rows: [[String]])
    case quote(text: String, caption: String?)
    case delimiter
    case image(url: URL, caption: String?)
    case embed(url: URL, caption: String?)
    case code(text: String)
    case warning(title: String, message: String)
    case linkCard(url: URL, title: String?, description: String?)
    case attachment(url: URL, name: String?, sizeBytes: Int?)
    case raw(html: String)
    case unsupported(type: String)

    var id: String {
        switch self {
        case .header(let l, let t): return "h\(l):\(t.hashValue)"
        case .paragraph(let t): return "p:\(t.hashValue)"
        case .list(let o, let i): return "l\(o):\(i.hashValue)"
        case .checklist(let items): return "cl:\(items.map { "\($0.checked):\($0.text)" }.hashValue)"
        case .table(_, let r): return "tbl:\(r.hashValue)"
        case .quote(let t, _): return "q:\(t.hashValue)"
        case .delimiter: return "delim"
        case .image(let u, _): return "img:\(u.absoluteString)"
        case .embed(let u, _): return "emb:\(u.absoluteString)"
        case .code(let t): return "code:\(t.hashValue)"
        case .warning(let t, let m): return "warn:\(t.hashValue):\(m.hashValue)"
        case .linkCard(let u, _, _): return "link:\(u.absoluteString)"
        case .attachment(let u, _, _): return "att:\(u.absoluteString)"
        case .raw(let h): return "raw:\(h.hashValue)"
        case .unsupported(let t): return "x:\(t)"
        }
    }
}

extension EditorBlock {
    // Tuple `(Bool, String)` is не Hashable из коробки на iOS 16; сводим
    // checklist к строкам при сравнении.
    static func == (lhs: EditorBlock, rhs: EditorBlock) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum EditorJSParser {
    /// Try to parse an Editor.js JSON string. Returns nil if input is not Editor.js.
    static func parse(_ raw: String) -> [EditorBlock]? {
        guard let data = raw.data(using: .utf8) else { return nil }

        // Editor.js documents may come either as a top-level array of blocks
        // (custom backend variant) or as `{ "blocks": [...] }` (canonical).
        if let arr = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] {
            return arr.compactMap(parseBlock)
        }
        if let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
           let arr = obj["blocks"] as? [[String: Any]] {
            return arr.compactMap(parseBlock)
        }
        return nil
    }

    private static func parseBlock(_ dict: [String: Any]) -> EditorBlock? {
        guard let type = dict["type"] as? String else { return nil }
        let payload = dict["data"] as? [String: Any] ?? [:]
        switch type {
        case "header":
            let level = (payload["level"] as? Int) ?? 2
            let text = payload["text"] as? String ?? ""
            return .header(level: level, text: text)
        case "paragraph":
            return .paragraph(text: payload["text"] as? String ?? "")
        case "list":
            let style = payload["style"] as? String ?? "unordered"
            let items: [String]
            if let strs = payload["items"] as? [String] {
                items = strs
            } else if let nested = payload["items"] as? [[String: Any]] {
                items = nested.compactMap { $0["content"] as? String ?? $0["text"] as? String }
            } else {
                items = []
            }
            return .list(ordered: style == "ordered", items: items)
        case "table":
            let withHeadings = payload["withHeadings"] as? Bool ?? false
            let content = (payload["content"] as? [[String]]) ?? []
            return .table(withHeading: withHeadings, rows: content)
        case "quote":
            let text = payload["text"] as? String ?? ""
            let caption = payload["caption"] as? String
            return .quote(text: text, caption: caption?.isEmpty == false ? caption : nil)
        case "delimiter":
            return .delimiter
        case "image", "simpleImage", "picture", "imageBlock":
            let urlString: String? = {
                if let f = payload["file"] as? [String: Any] {
                    if let u = f["url"] as? String { return u }
                    if let u = f["src"] as? String { return u }
                }
                if let u = payload["url"] as? String { return u }
                if let u = payload["src"] as? String { return u }
                if let u = payload["imageUrl"] as? String { return u }
                if let u = payload["link"] as? String { return u }
                return nil
            }()
            let caption = (payload["caption"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            guard let raw = urlString, !raw.isEmpty else {
                LXPLog.debug("[LXP][img] empty url in image block: \(payload)")
                return .unsupported(type: "image-empty")
            }
            let absolute = raw.hasPrefix("//") ? "https:" + raw : raw
            guard let url = URL(string: absolute) else {
                LXPLog.debug("[LXP][img] invalid url: \(absolute)")
                return .unsupported(type: "image-bad-url")
            }
            LXPLog.debug("[LXP][img] parsed image block url=\(url.absoluteString)")
            return .image(url: url, caption: caption)
        case "embed":
            // data: { service, source, embed, caption }
            let urlString = (payload["embed"] as? String) ?? (payload["source"] as? String)
            guard let raw = urlString, let url = URL(string: raw) else { return nil }
            let caption = (payload["caption"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            return .embed(url: url, caption: caption)
        case "checklist":
            let items: [(Bool, String)]
            if let arr = payload["items"] as? [[String: Any]] {
                items = arr.map { (($0["checked"] as? Bool) ?? false, ($0["text"] as? String) ?? "") }
            } else {
                items = []
            }
            return .checklist(items: items)
        case "code":
            let text = (payload["code"] as? String) ?? (payload["text"] as? String) ?? ""
            return .code(text: text)
        case "warning":
            let title = (payload["title"] as? String) ?? ""
            let message = (payload["message"] as? String) ?? ""
            return .warning(title: title, message: message)
        case "linkTool", "link":
            let raw = (payload["link"] as? String) ?? (payload["url"] as? String) ?? ""
            guard let url = URL(string: raw) else { return nil }
            let meta = payload["meta"] as? [String: Any]
            let title = (meta?["title"] as? String) ?? (payload["title"] as? String)
            let desc = (meta?["description"] as? String) ?? (payload["description"] as? String)
            return .linkCard(url: url, title: title?.isEmpty == false ? title : nil,
                             description: desc?.isEmpty == false ? desc : nil)
        case "attaches", "attachment", "file":
            let f = payload["file"] as? [String: Any] ?? [:]
            let raw = (f["url"] as? String) ?? (payload["url"] as? String) ?? ""
            guard let url = URL(string: raw) else { return nil }
            let name = (payload["title"] as? String) ?? (f["name"] as? String) ?? url.lastPathComponent
            let size = (f["size"] as? Int) ?? (payload["size"] as? Int)
            return .attachment(url: url, name: name, sizeBytes: size)
        case "raw":
            let html = (payload["html"] as? String) ?? ""
            return .raw(html: html)
        default:
            LXPLog.debug("[LXP][editor] unsupported block type=\(type) payload=\(payload)")
            return .unsupported(type: type)
        }
    }
}

// MARK: - Inline HTML → AttributedString

enum InlineHTML {
    /// Converts a small subset of HTML inline tags (b/strong/i/em/u/br/a) into AttributedString.
    /// Anchor `<a href="…">` устанавливает `link` атрибут — SwiftUI `Text`
    /// сам делает их кликабельными. Unknown tags are stripped.
    static func attributed(_ html: String) -> AttributedString {
        let normalized = html.replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "<br/>", with: "\n")
            .replacingOccurrences(of: "<br />", with: "\n")

        var result = AttributedString()
        var index = normalized.startIndex
        var styles: [InlineStyle] = []

        while index < normalized.endIndex {
            if normalized[index] == "<" {
                guard let close = normalized[index...].firstIndex(of: ">") else { break }
                let raw = String(normalized[normalized.index(after: index)..<close])
                let trimmed = raw.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("/") {
                    let kind = String(trimmed.dropFirst()).lowercased()
                    if let i = styles.lastIndex(where: { $0.tag == kind }) {
                        styles.remove(at: i)
                    }
                } else {
                    let lower = trimmed.lowercased()
                    let kind = lower.split(separator: " ").first.map(String.init) ?? lower
                    if kind == "a" {
                        let href = parseHref(from: trimmed)
                        styles.append(InlineStyle(tag: "a", href: href))
                    } else if let s = InlineStyle(tag: kind) {
                        styles.append(s)
                    }
                }
                index = normalized.index(after: close)
                continue
            }

            // Plain run until next '<'
            let next = normalized[index...].firstIndex(of: "<") ?? normalized.endIndex
            var run = AttributedString(decode(String(normalized[index..<next])))
            for s in styles { s.apply(to: &run) }
            result.append(run)
            index = next
        }
        return result
    }

    /// Достаёт значение `href="..."` (или `'...'`) из тега `<a href="x">`.
    private static func parseHref(from tagBody: String) -> String? {
        let lower = tagBody.lowercased()
        guard let hrefRange = lower.range(of: "href") else { return nil }
        var i = hrefRange.upperBound
        // Skip whitespace and '='
        while i < lower.endIndex, lower[i].isWhitespace || lower[i] == "=" { i = lower.index(after: i) }
        guard i < tagBody.endIndex else { return nil }
        // Map indices from lower to tagBody — они одинаковы по позициям.
        let startInTag = tagBody.index(tagBody.startIndex, offsetBy: lower.distance(from: lower.startIndex, to: i))
        let quote = tagBody[startInTag]
        if quote == "\"" || quote == "'" {
            let after = tagBody.index(after: startInTag)
            guard let end = tagBody[after...].firstIndex(of: quote) else { return nil }
            return String(tagBody[after..<end])
        }
        // Без кавычек: до пробела или конца
        let end = tagBody[startInTag...].firstIndex(where: { $0.isWhitespace }) ?? tagBody.endIndex
        return String(tagBody[startInTag..<end])
    }

    private static func decode(_ s: String) -> String {
        s.replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
    }

    private struct InlineStyle {
        let tag: String
        let href: String?

        init?(tag: String) {
            switch tag {
            case "b", "strong", "i", "em", "u": self.tag = tag
            default: return nil
            }
            self.href = nil
        }

        init(tag: String, href: String?) {
            self.tag = tag
            self.href = href
        }

        func apply(to run: inout AttributedString) {
            switch tag {
            case "b", "strong":
                run.font = .body.bold()
            case "i", "em":
                run.font = (run.font ?? .body).italic()
            case "u":
                run.underlineStyle = .single
            case "a":
                if let href, let url = URL(string: href) {
                    run.link = url
                    run.foregroundColor = .accentColor
                    run.underlineStyle = .single
                }
            default:
                break
            }
        }
    }
}

// MARK: - SwiftUI renderer

struct EditorContentView: View {
    let blocks: [EditorBlock]
    /// Если задано — встроенные `.image` блоки становятся тапабельными,
    /// тап вызывает замыкание с URL картинки. Используется в `AnswerView`,
    /// чтобы открыть фото на полный экран. По умолчанию nil — картинка
    /// рендерится без жеста (поведение до этого изменения).
    var onImageTap: ((URL) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
    }

    @ViewBuilder
    private func blockView(_ block: EditorBlock) -> some View {
        switch block {
        case .header(let level, let text):
            Text(InlineHTML.attributed(text))
                .font(headerFont(for: level))
                .frame(maxWidth: .infinity, alignment: .leading)
        case .paragraph(let text):
            Text(InlineHTML.attributed(text))
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .list(let ordered, let items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(ordered ? "\(i + 1)." : "•")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 18, alignment: .leading)
                        Text(InlineHTML.attributed(item))
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        case .table(let withHeading, let rows):
            tableView(withHeading: withHeading, rows: rows)
        case .quote(let text, let caption):
            VStack(alignment: .leading, spacing: 4) {
                Text(InlineHTML.attributed(text))
                    .font(.body.italic())
                if let caption {
                    Text("— \(caption)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, 12)
            .overlay(alignment: .leading) {
                Rectangle().fill(Color.secondary.opacity(0.4)).frame(width: 3)
            }
        case .delimiter:
            Divider().padding(.vertical, 4)
        case .image(let url, let caption):
            VStack(alignment: .leading, spacing: 6) {
                if let onImageTap {
                    Button {
                        onImageTap(url)
                    } label: {
                        RemoteImage(url: url)
                    }
                    .buttonStyle(.plain)
                } else {
                    RemoteImage(url: url)
                }
                if let caption {
                    Text(InlineHTML.attributed(caption))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .embed(let url, let caption):
            VStack(alignment: .leading, spacing: 6) {
                Link(destination: url) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.rectangle")
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Открыть видео")
                                .font(.subheadline.weight(.semibold))
                            Text(url.host ?? url.absoluteString)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.secondary.opacity(0.08)))
                }
                .buttonStyle(.plain)
                if let caption {
                    Text(InlineHTML.attributed(caption))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        case .checklist(let items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: item.checked ? "checkmark.square.fill" : "square")
                            .font(.body)
                            .foregroundStyle(item.checked ? Color.accentColor : Color.secondary)
                        Text(InlineHTML.attributed(item.text))
                            .font(.body)
                            .strikethrough(item.checked, color: .secondary)
                            .foregroundStyle(item.checked ? Color.secondary : Color.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        case .code(let text):
            ScrollView(.horizontal, showsIndicators: false) {
                Text(text)
                    .font(.system(.footnote, design: .monospaced))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.10)))
        case .warning(let title, let message):
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 4) {
                    if !title.isEmpty {
                        Text(InlineHTML.attributed(title))
                            .font(.subheadline.weight(.semibold))
                    }
                    if !message.isEmpty {
                        Text(InlineHTML.attributed(message))
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange.opacity(0.12)))
        case .linkCard(let url, let title, let description):
            Link(destination: url) {
                HStack(spacing: 10) {
                    Image(systemName: "link")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title ?? url.host ?? url.absoluteString)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(2)
                        if let description, !description.isEmpty {
                            Text(description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        } else {
                            Text(url.host ?? url.absoluteString)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "arrow.up.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
            }
            .buttonStyle(.plain)
        case .attachment(let url, let name, let sizeBytes):
            Link(destination: url) {
                HStack(spacing: 10) {
                    Image(systemName: "paperclip")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name ?? url.lastPathComponent)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        if let sizeBytes {
                            Text(formatBytes(sizeBytes))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "arrow.down.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
            }
            .buttonStyle(.plain)
        case .raw(let html):
            // Не пытаемся отрендерить произвольный HTML, но хоть текст вытащим —
            // лучше, чем потерять блок.
            Text(InlineHTML.attributed(html))
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .unsupported(let type):
            Text("[\(type)]")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func formatBytes(_ count: Int) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: Int64(count))
    }

    private func headerFont(for level: Int) -> Font {
        switch level {
        case 1: .title2.weight(.semibold)
        case 2: .title3.weight(.semibold)
        case 3: .headline
        default: .subheadline.weight(.semibold)
        }
    }

    private func tableView(withHeading: Bool, rows: [[String]]) -> some View {
        // Нормализуем число столбцов — в Editor.js строки могут приходить
        // разной длины. Grid требует одинакового кол-ва GridRow-ячеек.
        let columnCount = rows.map(\.count).max() ?? 0
        guard columnCount > 0 else { return AnyView(EmptyView()) }

        let table = Grid(alignment: .topLeading, horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                GridRow {
                    ForEach(0..<columnCount, id: \.self) { col in
                        let cell = col < row.count ? row[col] : ""
                        let isHeader = withHeading && idx == 0
                        Text(InlineHTML.attributed(cell))
                            .font(isHeader ? .footnote.weight(.semibold) : .footnote)
                            .foregroundStyle(isHeader ? Color.primary : Color.primary.opacity(0.92))
                            .padding(.vertical, 7)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(rowBackground(row: idx, isHeader: isHeader))
                            .overlay(alignment: .trailing) {
                                if col < columnCount - 1 {
                                    Rectangle()
                                        .fill(Color.secondary.opacity(0.18))
                                        .frame(width: 0.5)
                                }
                            }
                            .overlay(alignment: .bottom) {
                                if idx < rows.count - 1 {
                                    Rectangle()
                                        .fill(Color.secondary.opacity(0.18))
                                        .frame(height: 0.5)
                                }
                            }
                    }
                }
            }
        }

        return AnyView(
            ScrollView(.horizontal, showsIndicators: false) {
                table
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.05))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 0.5)
                    )
            }
        )
    }

    private func rowBackground(row: Int, isHeader: Bool) -> some View {
        if isHeader {
            return Color.secondary.opacity(0.14)
        }
        return row.isMultiple(of: 2) ? Color.clear : Color.secondary.opacity(0.05)
    }
}

// MARK: - Remote image with explicit URLSession + diagnostics

@MainActor
final class RemoteImageLoader {
    static let shared = RemoteImageLoader()
    private var cache: [URL: UIImage] = [:]
    private var inflight: [URL: Task<UIImage?, Never>] = [:]

    func image(for url: URL) -> UIImage? { cache[url] }

    func load(_ url: URL) async -> UIImage? {
        if let cached = cache[url] { return cached }
        if let task = inflight[url] { return await task.value }
        let task = Task<UIImage?, Never> {
            do {
                var req = URLRequest(url: url)
                req.setValue("Mozilla/5.0 NewLXP iOS", forHTTPHeaderField: "User-Agent")
                let (data, response) = try await URLSession.shared.data(for: req)
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                if status >= 400 {
                    LXPLog.debug("[LXP][img] HTTP \(status) \(url.absoluteString)")
                    return nil
                }
                guard let img = UIImage(data: data) else {
                    LXPLog.debug("[LXP][img] decode failed (\(data.count) bytes) \(url.absoluteString)")
                    return nil
                }
                self.cache[url] = img
                return img
            } catch {
                LXPLog.debug("[LXP][img] error \(error.localizedDescription) \(url.absoluteString)")
                return nil
            }
        }
        inflight[url] = task
        let result = await task.value
        inflight[url] = nil
        return result
    }
}

struct RemoteImage: View {
    let url: URL
    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if failed {
                Link(destination: url) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo")
                        Text("Открыть изображение").font(.footnote)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.08))
                    ProgressView()
                }
                .aspectRatio(16/9, contentMode: .fit)
            }
        }
        .task(id: url) {
            if let cached = RemoteImageLoader.shared.image(for: url) {
                self.image = cached
                return
            }
            if let loaded = await RemoteImageLoader.shared.load(url) {
                self.image = loaded
            } else {
                self.failed = true
            }
        }
    }
}
