//
//  UpdateService.swift
//  HeadsUp
//
//  Update checking and notification service
//  Ready for Sparkle integration or GitHub Releases API
//

import Cocoa
import Foundation

// MARK: - Update Service Protocol

protocol UpdateServiceProtocol {
    func checkForUpdates(completion: @escaping (UpdateInfo?) -> Void)
    func checkForUpdatesInBackground()
}

// MARK: - Update Info

struct UpdateInfo {
    let version: String
    let releaseNotes: String
    let downloadURL: URL
    let publishedDate: Date

    var isNewerThan(currentVersion: String) -> Bool {
        return version.compare(currentVersion, options: .numeric) == .orderedDescending
    }
}

// MARK: - GitHub Release Response

private struct GitHubRelease: Codable {
    let tagName: String
    let name: String
    let body: String
    let htmlUrl: String
    let publishedAt: String
    let assets: [Asset]

    struct Asset: Codable {
        let name: String
        let browserDownloadUrl: String

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadUrl = "browser_download_url"
        }
    }

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
        case assets
    }
}

// MARK: - Update Service Implementation

class UpdateService: UpdateServiceProtocol {

    // MARK: - Properties

    static let shared = UpdateService()

    private let githubRepo = "Merkost/HeadsUp"
    private let currentVersion = "0.2.0"

    private let lastCheckKey = "LastUpdateCheckDate"
    private let checkInterval: TimeInterval = 86400 // 24 hours

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    func checkForUpdates(completion: @escaping (UpdateInfo?) -> Void) {
        let urlString = "https://api.github.com/repos/\(githubRepo)/releases/latest"

        guard let url = URL(string: urlString) else {
            print("❌ Invalid GitHub API URL")
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Update check failed: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            guard let data = data else {
                print("❌ No data received from GitHub API")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            do {
                let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                let updateInfo = self.parseRelease(release)

                DispatchQueue.main.async {
                    completion(updateInfo)
                }
            } catch {
                print("❌ Failed to decode GitHub release: \(error)")
                DispatchQueue.main.async { completion(nil) }
            }
        }

        task.resume()
    }

    func checkForUpdatesInBackground() {
        // Check if we should perform automatic check
        let lastCheck = UserDefaults.standard.object(forKey: lastCheckKey) as? Date ?? Date.distantPast
        let timeSinceLastCheck = Date().timeIntervalSince(lastCheck)

        guard timeSinceLastCheck >= checkInterval else {
            print("⏭ Skipping update check (last checked \(Int(timeSinceLastCheck / 3600)) hours ago)")
            return
        }

        print("🔍 Checking for updates in background...")

        checkForUpdates { [weak self] updateInfo in
            guard let self = self, let update = updateInfo else { return }

            // Save last check date
            UserDefaults.standard.set(Date(), forKey: self.lastCheckKey)

            // Check if update is newer
            if update.isNewerThan(currentVersion: self.currentVersion) {
                print("🎉 New version available: \(update.version)")
                self.showUpdateNotification(update)
            } else {
                print("✅ App is up to date (current: \(self.currentVersion))")
            }
        }
    }

    // MARK: - Private Methods

    private func parseRelease(_ release: GitHubRelease) -> UpdateInfo {
        // Parse version from tag (remove 'v' prefix if present)
        var version = release.tagName
        if version.hasPrefix("v") {
            version = String(version.dropFirst())
        }

        // Find .dmg or .zip download URL
        let downloadURL: URL
        if let dmgAsset = release.assets.first(where: { $0.name.hasSuffix(".dmg") || $0.name.hasSuffix(".zip") }) {
            downloadURL = URL(string: dmgAsset.browserDownloadUrl) ?? URL(string: release.htmlUrl)!
        } else {
            downloadURL = URL(string: release.htmlUrl)!
        }

        // Parse date
        let dateFormatter = ISO8601DateFormatter()
        let publishedDate = dateFormatter.date(from: release.publishedAt) ?? Date()

        return UpdateInfo(
            version: version,
            releaseNotes: release.body,
            downloadURL: downloadURL,
            publishedDate: publishedDate
        )
    }

    private func showUpdateNotification(_ update: UpdateInfo) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Update Available"
            alert.informativeText = """
            A new version of HeadsUp is available!

            Current version: \(self.currentVersion)
            New version: \(update.version)

            Would you like to download it now?
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Download")
            alert.addButton(withTitle: "Later")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NSWorkspace.shared.open(update.downloadURL)
            }
        }
    }

    // MARK: - Manual Update Check

    func checkForUpdatesManually() {
        print("🔍 Manual update check requested...")

        checkForUpdates { [weak self] updateInfo in
            guard let self = self else { return }

            if let update = updateInfo {
                if update.isNewerThan(currentVersion: self.currentVersion) {
                    print("🎉 New version available: \(update.version)")
                    self.showUpdateDialog(update)
                } else {
                    print("✅ App is up to date")
                    self.showUpToDateDialog()
                }
            } else {
                self.showUpdateCheckFailedDialog()
            }
        }
    }

    private func showUpdateDialog(_ update: UpdateInfo) {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = """
        Version \(update.version) is now available!
        You're currently using version \(self.currentVersion).

        Release Notes:
        \(update.releaseNotes.prefix(200))...

        Would you like to download the update?
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "View Release Notes")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(update.downloadURL)
        } else if response == .alertSecondButtonReturn {
            NSWorkspace.shared.open(URL(string: "https://github.com/\(githubRepo)/releases/latest")!)
        }
    }

    private func showUpToDateDialog() {
        let alert = NSAlert()
        alert.messageText = "You're Up to Date"
        alert.informativeText = "HeadsUp \(currentVersion) is currently the newest version available."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showUpdateCheckFailedDialog() {
        let alert = NSAlert()
        alert.messageText = "Update Check Failed"
        alert.informativeText = "Unable to check for updates. Please check your internet connection and try again later."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
