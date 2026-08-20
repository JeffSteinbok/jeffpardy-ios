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
            url.host?.caseInsensitiveCompare(baseURL.host ?? "") == .orderedSame,
            url.path.lowercased() == "/player",
            let fragment = url.fragment,
            fragment.count == 6,
            fragment.allSatisfy({ $0.isLetter || $0.isNumber })
        else {
            return nil
        }

        return fragment.uppercased()
    }
}
