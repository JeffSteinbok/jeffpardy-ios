import Foundation

enum AppConfiguration {
    static var baseURL: URL {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "JEFFPARDY_BASE_URL") as? String,
            let url = URL(string: value),
            let scheme = url.scheme,
            ["http", "https"].contains(scheme.lowercased())
        else {
            preconditionFailure("JEFFPARDY_BASE_URL must be a valid HTTP or HTTPS URL")
        }

        return url
    }

    /// Hosts the site used to live on. Links shared before the move still open the app.
    static var legacyHosts: [String] {
        Bundle.main.object(forInfoDictionaryKey: "JEFFPARDY_LEGACY_HOSTS") as? [String] ?? []
    }

    /// Every host whose links this app treats as its own: the current site plus retired domains.
    static var recognizedHosts: [String] {
        guard let host = baseURL.host else {
            return legacyHosts
        }

        return [host] + legacyHosts.filter { $0.caseInsensitiveCompare(host) != .orderedSame }
    }

    static func isRecognizedHost(_ host: String?) -> Bool {
        guard let host else {
            return false
        }

        return recognizedHosts.contains { $0.caseInsensitiveCompare(host) == .orderedSame }
    }

    static var hubURL: URL {
        baseURL.appending(path: "hub/game")
    }

    static func hostSecondaryURL(gameCode: String, hostCode: String) -> URL? {
        guard
            let url = URL(
                string: "HostSecondary#\(gameCode.uppercased())\(hostCode.uppercased())",
                relativeTo: baseURL
            )
        else {
            return nil
        }

        return url.absoluteURL
    }

    static func gameCode(fromPlayerURL url: URL) -> String? {
        guard
            ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
            isRecognizedHost(url.host),
            url.path.lowercased() == "/player",
            let fragment = url.fragment,
            fragment.count == 6,
            fragment.allSatisfy({ $0.isLetter || $0.isNumber })
        else {
            return nil
        }

        return fragment.uppercased()
    }

    static func playerURL(gameCode: String) -> URL? {
        let normalizedCode = gameCode.uppercased()
        guard
            normalizedCode.count == 6,
            normalizedCode.allSatisfy({ $0.isLetter || $0.isNumber }),
            let url = URL(
                string: "player#\(normalizedCode)",
                relativeTo: baseURL
            )
        else {
            return nil
        }

        return url.absoluteURL
    }
}
