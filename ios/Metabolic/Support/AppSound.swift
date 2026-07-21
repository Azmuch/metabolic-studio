import AudioToolbox
import Foundation

/// Short UI sounds. `achievement()` plays a bundled `achievement.m4a`/`.caf` if one is added to the
/// app, otherwise a pleasant built-in success chime — pair it with `Haptics.success()` at the call
/// site. Drop a custom sound file named `achievement` into the app target to override.
enum AppSound {
    private static let achievementID: SystemSoundID = {
        if let url = Bundle.main.url(forResource: "achievement", withExtension: "m4a")
            ?? Bundle.main.url(forResource: "achievement", withExtension: "caf") {
            var id: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(url as CFURL, &id)
            return id
        }
        return 1394   // Built-in success chime — pleasant and always available.
    }()

    static func achievement() {
        AudioServicesPlaySystemSound(achievementID)
    }
}
