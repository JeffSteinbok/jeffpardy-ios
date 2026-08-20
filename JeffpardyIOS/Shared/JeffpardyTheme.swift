import SwiftUI

enum JeffpardyTheme {
    static let blue = Color(red: 0.02, green: 0.08, blue: 0.42)
    static let brightBlue = Color(red: 0.03, green: 0.22, blue: 0.72)
    static let gold = Color(red: 0.96, green: 0.73, blue: 0.12)
    static let inactive = Color(red: 0.28, green: 0.30, blue: 0.36)
}

struct JeffpardyBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [JeffpardyTheme.brightBlue, JeffpardyTheme.blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
    }
}

extension View {
    func jeffpardyBackground() -> some View {
        modifier(JeffpardyBackground())
    }
}

