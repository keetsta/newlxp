import Foundation
import os

/// Лог приложения. Пишет двумя путями:
///  • `print` → stdout, виден в Xcode-дебаггере, в `idevicesyslog`/Console
///    отображается без `subsystem` (просто строкой через `NewLXP[…]`).
///  • `os.Logger` → unified log, виден в Console.app по фильтру
///    `subsystem == me.keetsta.NewLXP` и в Xcode (если в нижней панели
///    выбран All Output / Debug Output).
/// Двойная запись нужна потому что Xcode-консоль ненадёжно показывает
/// чистый `os_log` — print гарантирует, что мы увидим лог при отладке.
enum LXPLog {
    private static let logger = Logger(subsystem: "me.keetsta.NewLXP", category: "lxp")

    static func debug(_ message: @autoclosure () -> String) {
        let text = message()
        print(text)
        logger.log("\(text, privacy: .public)")
    }
}
