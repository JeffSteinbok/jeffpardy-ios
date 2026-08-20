import XCTest
@testable import JeffpardyIOS

final class PlayerIdentityStoreTests: XCTestCase {
    private let suiteName = "com.jeffsteinbok.jeffpardy.tests.PlayerIdentityStore"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testPlayerID_IsStableAndGameCodeIsCaseInsensitive() {
        let store = PlayerIdentityStore(defaults: defaults)

        let firstID = store.playerID(for: "abc123")
        let secondID = store.playerID(for: "ABC123")

        XCTAssertEqual(firstID, secondID)
    }

    func testPlayerID_IsDifferentForEachGame() {
        let store = PlayerIdentityStore(defaults: defaults)

        XCTAssertNotEqual(
            store.playerID(for: "ABC123"),
            store.playerID(for: "XYZ789")
        )
    }
}
