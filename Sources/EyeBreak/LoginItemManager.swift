import Foundation

final class LoginItemManager {
    private var label: String { "com.davideagostini.eyebreak" }

    func setEnabled(_ enabled: Bool) throws {
        let fileManager = FileManager.default
        let launchAgents = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("LaunchAgents")
        let plistURL = launchAgents.appendingPathComponent("\(label).plist")

        if enabled {
            try fileManager.createDirectory(at: launchAgents, withIntermediateDirectories: true)
            let bundlePath = Bundle.main.bundlePath
            let plist = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>\(label)</string>
                <key>ProgramArguments</key>
                <array>
                    <string>/usr/bin/open</string>
                    <string>\(bundlePath)</string>
                </array>
                <key>RunAtLoad</key>
                <true/>
            </dict>
            </plist>
            """
            try plist.write(to: plistURL, atomically: true, encoding: .utf8)
        } else if fileManager.fileExists(atPath: plistURL.path) {
            try fileManager.removeItem(at: plistURL)
        }
    }
}
