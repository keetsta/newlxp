import Foundation
import SwiftUI

// MARK: - Editor.js parsing

/// Block of an Editor.js document.
enum EditorBlock: Hashable {
    case header(level: Int, text: String)
    case paragraph(text: String)
    case list(ordered: Bool, items: [String])
    case table(withHeading: Bool, rows: [[String]])
    case quote(text: String, caption: String?)
    case delimiter
    case image(url: URL, caption: String?)
    case embed(url: URL, caption: String?)
    case unsupported(type: String)

    var id: String {
        switch self {
        case .header(let l, let t): return "h\(l):\(t.hashValue)"
        case .paragraph(let t): return "p:\(t.hashValue)"
        case .list(let o, let i): return "l\(o):\(i.hashValue)"
        case .table(_, let r): return "tbl:\(r.hashValue)"
        case .quote(let t, _): return "q:\(t.hashValue)"
        case .delimiter: return "delim"
        case .image(let u, _): return "img:\(u.absoluteString)"
        case .embed(let u, _): return "emb:\(u.absoluteString)"
        case .unsupported(let t): return "x:\(t)"
        }
    }
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
                print("[LXP][img] empty url in image block: \(payload)")
                return .unsupported(type: "image-empty")
            }
            let absolute = raw.hasPrefix("//") ? "https:" + raw : raw
            guard let url = URL(string: absolute) else {
                print("[LXP][img] invalid url: \(absolute)")
                return .unsupported(type: "image-bad-url")
            }
            print("[LXP][img] parsed image block url=\(url.absoluteString)")
            return .image(url: url, caption: caption)
        case "embed":
            // data: { service, source, embed, caption }
            let urlString = (payload["embed"] as? String) ?? (payload["source"] as? String)
            guard let raw = urlString, let url = URL(string: raw) else { return nil }
            let caption = (payload["caption"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            return .embed(url: url, caption: caption)
        default:
            print("[LXP][editor] unsupported block type=\(type) payload=\(payload)")
            return .unsupported(type: type)
        }
    }
}

// MARK: - Inline HTML → AttributedString

enum InlineHTML {
    /// Converts a small subset of HTML inline tags (b/strong/i/em/u/br) into AttributedString.
    /// Unknown tags are stripped.
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
                let tag = raw.trimmingCharacters(in: .whitespaces).lowercased()
                if tag.hasPrefix("/") {
                    let kind = String(tag.dropFirst())
                    if let i = styles.lastIndex(where: { $0.tag == kind }) {
                        styles.remove(at: i)
                    }
                } else {
                    let kind = tag.split(separator: " ").first.map(String.init) ?? tag
                    if let s = InlineStyle(tag: kind) {
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

    private static func decode(_ s: String) -> String {
        s.replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
    }

    private struct InlineStyle {
        let tag: String

        init?(tag: String) {
            switch tag {
            case "b", "strong", "i", "em", "u": self.tag = tag
            default: return nil
            }
        }

        func apply(to run: inout AttributedString) {
            switch tag {
            case "b", "strong":
                run.font = .body.bold()
            case "i", "em":
                run.font = (run.font ?? .body).italic()
            case "u":
                run.underlineStyle = .single
            default:
                break
            }
        }
    }
}

// MARK: - SwiftUI renderer

struct EditorContentView: View {
    let blocks: [EditorBlock]

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
                RemoteImage(url: url)
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
        case .unsupported(let type):
            Text("[\(type)]")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
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
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                            Text(InlineHTML.attributed(cell))
                                .font(withHeading && idx == 0 ? .footnote.weight(.semibold) : .footnote)
                                .frame(minWidth: 120, alignment: .leading)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                        }
                    }
                    if idx < rows.count - 1 {
                        Divider().opacity(0.4)
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08))
            }
        }
    }
}

// MARK: - Remote image with explicit URLSession + diagnostics

@Observable
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
                    print("[LXP][img] HTTP \(status) \(url.absoluteString)")
                    return nil
                }
                guard let img = UIImage(data: data) else {
                    print("[LXP][img] decode failed (\(data.count) bytes) \(url.absoluteString)")
                    return nil
                }
                self.cache[url] = img
                return img
            } catch {
                print("[LXP][img] error \(error.localizedDescription) \(url.absoluteString)")
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
