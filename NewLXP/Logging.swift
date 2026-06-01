import Foundation

/// Лог приложения. В Debug-сборке пишет в stdout с префиксом, в Release —
/// no-op. Старые `print("[LXP]...")` сайты переехали сюда, чтобы консоль
/// продакшена была чистой.
enum LXPLog {
    static func debug(_ message: @autoclosure () -> String) {
        #if DEBUG
        print(message())
        #endif
    }
}
