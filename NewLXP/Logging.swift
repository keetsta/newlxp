import Foundation
import os

/// Лог приложения. Пишет через `os.Logger` в подсистему `me.keetsta.NewLXP`,
/// категорию `lxp` — видно в Console.app / `idevicesyslog` через
/// `subsystem == me.keetsta.NewLXP`. Логирование активно и в Release,
/// чтобы можно было снять диагностику с реального девайса. На объёмы
/// поводов нет: пишем только осознанно, через `LXPLog.debug`.
enum LXPLog {
    private static let logger = Logger(subsystem: "me.keetsta.NewLXP", category: "lxp")

    static func debug(_ message: @autoclosure () -> String) {
        let text = message()
        logger.log("\(text, privacy: .public)")
    }
}
