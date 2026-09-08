import SwiftUI
import XCTest
@testable import JeffpardyIOS

@MainActor
final class HostRoundGridTests: XCTestCase {
    /// Content width on the narrowest supported iPhone (375pt) minus the host display's
    /// 24pt padding on each side.
    private let contentWidth: CGFloat = 327

    /// Vertical space the grid gets on that phone: the safe area minus the nav bar, the
    /// connection header, and the surrounding padding.
    private let availableHeight: CGFloat = 560

    private func round(categoryCount: Int, comment: String?) -> HostGameRound {
        HostGameRound(
            id: 0,
            categories: (0..<categoryCount).map { index in
                HostCategory(
                    title: "POTENT POTABLES \(index + 1)",
                    comment: comment,
                    airDate: "2004-03-15"
                )
            }
        )
    }

    private func renderedHeight(for round: HostGameRound) throws -> CGFloat {
        let renderer = ImageRenderer(
            content: HostRoundGrid(round: round)
                .frame(width: contentWidth)
        )
        let size = try XCTUnwrap(renderer.uiImage?.size)
        return size.height
    }

    func testSixCategoryRoundFitsWithoutScrolling() throws {
        let height = try renderedHeight(for: round(categoryCount: 6, comment: nil))

        XCTAssertLessThan(
            height,
            availableHeight,
            "A six-category round should fit on a phone without scrolling."
        )
    }

    func testSixCategoryRoundWithCommentsFitsWithoutScrolling() throws {
        let height = try renderedHeight(
            for: round(
                categoryCount: 6,
                comment: "Answers must name the beverage in the form of a question."
            )
        )

        XCTAssertLessThan(
            height,
            availableHeight,
            "Category comments should not push a six-category round off the screen."
        )
    }
}
