import XCTest
@testable import JeffpardyIOS

final class AppConfigurationTests: XCTestCase {
    func testHostSecondaryURL_CombinesUppercaseCodesInFragment() {
        let url = AppConfiguration.hostSecondaryURL(
            gameCode: "abc123",
            hostCode: "def456"
        )

        XCTAssertEqual(
            url?.absoluteString,
            "https://jeffpardy.azurewebsites.net/HostSecondary#ABC123DEF456"
        )
    }

    func testGameCodeFromPlayerURL_ReturnsUppercaseCode() {
        let url = URL(string: "https://jeffpardy.azurewebsites.net/player#abc123")!

        XCTAssertEqual(
            AppConfiguration.gameCode(fromPlayerURL: url),
            "ABC123"
        )
    }

    func testGameCodeFromPlayerURL_RejectsHostSecondaryURL() {
        let url = URL(
            string: "https://jeffpardy.azurewebsites.net/hostSecondary#ABC123DEF456"
        )!

        XCTAssertNil(AppConfiguration.gameCode(fromPlayerURL: url))
    }

    func testGameCodeFromPlayerURL_RejectsAnotherHost() {
        let url = URL(string: "https://example.com/player#ABC123")!

        XCTAssertNil(AppConfiguration.gameCode(fromPlayerURL: url))
    }

    func testPlayerURL_CreatesShareableUppercaseLink() {
        XCTAssertEqual(
            AppConfiguration.playerURL(gameCode: "abc123")?.absoluteString,
            "https://jeffpardy.azurewebsites.net/player#ABC123"
        )
    }

    func testPlayerURL_RejectsInvalidCode() {
        XCTAssertNil(AppConfiguration.playerURL(gameCode: "ABC"))
        XCTAssertNil(AppConfiguration.playerURL(gameCode: "ABC!23"))
    }
}
