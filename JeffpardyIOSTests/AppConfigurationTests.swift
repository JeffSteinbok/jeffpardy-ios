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
}

