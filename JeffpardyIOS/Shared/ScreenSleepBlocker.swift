import SwiftUI
import UIKit

/// Keeps the display awake while a game is in progress. Players stare at the buzzer
/// without touching it, and the host secondary window is meant to be watched, not tapped,
/// so the idle timer would otherwise dim the screen mid-clue.
///
/// Requests are counted rather than toggled directly, so a screen that stops requesting
/// while another still needs the display awake cannot turn the idle timer back on.
@MainActor
enum ScreenSleepBlocker {
    private static var requestCount = 0

    static func addRequest() {
        requestCount += 1
        apply()
    }

    static func removeRequest() {
        requestCount = max(0, requestCount - 1)
        apply()
    }

    private static func apply() {
        UIApplication.shared.isIdleTimerDisabled = requestCount > 0
    }
}

private struct KeepScreenAwakeModifier: ViewModifier {
    let isActive: Bool

    @State private var isRequesting = false

    func body(content: Content) -> some View {
        content
            .onAppear { sync(to: isActive) }
            .onChange(of: isActive) { _, newValue in sync(to: newValue) }
            .onDisappear { sync(to: false) }
    }

    private func sync(to shouldRequest: Bool) {
        guard shouldRequest != isRequesting else {
            return
        }

        isRequesting = shouldRequest
        if shouldRequest {
            ScreenSleepBlocker.addRequest()
        } else {
            ScreenSleepBlocker.removeRequest()
        }
    }
}

extension View {
    /// Prevents the device from auto-locking while `isActive` is true.
    func keepScreenAwake(_ isActive: Bool) -> some View {
        modifier(KeepScreenAwakeModifier(isActive: isActive))
    }
}
