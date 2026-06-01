import SwiftUI

/// Аватар: реальная картинка через `RemoteImageLoader` (с in-memory кэшем),
/// либо инициалы в кружочке-плашке как фолбэк. Используется и для своего
/// профиля, и для одногруппников.
struct AvatarView: View {
    let avatarPath: String?
    let initials: String
    var size: CGFloat = 52
    var fontSize: CGFloat? = nil

    @State private var image: UIImage? = nil
    @State private var failed: Bool = false

    private var resolvedURL: URL? {
        guard let raw = avatarPath?.trimmingCharacters(in: .whitespaces),
              !raw.isEmpty else { return nil }
        if let abs = URL(string: raw), abs.scheme != nil { return abs }
        // Относительный путь — клеим к хосту API.
        let cleaned = raw.hasPrefix("/") ? raw : "/\(raw)"
        return URL(string: "https://api.newlxp.ru\(cleaned)")
    }

    private var defaultFontSize: CGFloat {
        fontSize ?? max(12, size * 0.4)
    }

    var body: some View {
        Group {
            if let image, !failed {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Text(initials)
                    .font(.system(size: defaultFontSize, weight: .semibold, design: .rounded))
                    .frame(width: size, height: size)
                    .lxpGlassCircle()
            }
        }
        .task(id: resolvedURL) {
            failed = false
            image = nil
            guard let url = resolvedURL else { return }
            if let cached = RemoteImageLoader.shared.image(for: url) {
                image = cached
                return
            }
            if let loaded = await RemoteImageLoader.shared.load(url) {
                image = loaded
            } else {
                failed = true
            }
        }
    }
}
