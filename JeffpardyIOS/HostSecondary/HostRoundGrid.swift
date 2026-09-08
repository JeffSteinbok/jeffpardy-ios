import SwiftUI

/// Reports a category row's natural height so every row can adopt the tallest one.
private struct CategoryCardHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// The category board the host sees between clues: one vertical list, every row the same
/// height. Rows lay the title and air date out side by side rather than stacking them, so a
/// standard six-category round still fits on a phone without scrolling.
struct HostRoundGrid: View {
    let round: HostGameRound

    @State private var rowHeight: CGFloat?

    private static let rowSpacing: CGFloat = 8

    var body: some View {
        VStack(spacing: 10) {
            Text("\(round.name.uppercased()) ROUND")
                .font(.system(size: 22, weight: .black))
                .fontWidth(.condensed)
                .tracking(1.2)
                .shadow(color: .black, radius: 2, x: 2, y: 2)

            VStack(spacing: Self.rowSpacing) {
                ForEach(round.categories, id: \.title) { category in
                    row(for: category)
                }
            }
            // Every row matches the tallest, so a category with a comment does not make
            // the list ragged.
            .onPreferenceChange(CategoryCardHeightKey.self) { height in
                Task { @MainActor in
                    guard height > 0 else {
                        return
                    }
                    rowHeight = height
                }
            }
        }
    }

    private func row(for category: HostCategory) -> some View {
        JeffpardyCard(padding: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(category.title.uppercased())
                        .font(.subheadline.weight(.black))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    Spacer(minLength: 8)

                    if let airDate = category.formattedAirDate {
                        Text(airDate)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(JeffpardyTheme.gold)
                            .layoutPriority(1)
                    }
                }

                if let comment = category.comment, !comment.isEmpty {
                    Text(comment)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: CategoryCardHeightKey.self,
                    value: proxy.size.height
                )
            }
        }
        .frame(height: rowHeight)
    }
}
