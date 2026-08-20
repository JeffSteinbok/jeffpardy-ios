import SwiftUI

struct AnimatedLaunchView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isLogoRaised = false
    @State private var isContentVisible = false
    @State private var isSplashVisible = true

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RootView()
                    .opacity(isContentVisible ? 1 : 0)

                if isSplashVisible {
                    VStack {
                        JeffpardyLogo()
                            .frame(maxWidth: 340)
                            .offset(
                                y: isLogoRaised
                                    ? -geometry.size.height * 0.31
                                    : 0
                            )
                            .opacity(isContentVisible ? 0 : 1)
                    }
                    .padding(.horizontal, 28)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .jeffpardyBackground()
                    .allowsHitTesting(false)
                }
            }
            .task {
                await animateLaunch()
            }
        }
    }

    private func animateLaunch() async {
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.15)) {
                isContentVisible = true
                isSplashVisible = false
            }
            return
        }

        try? await Task.sleep(for: .milliseconds(280))
        guard !Task.isCancelled else {
            return
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
            isLogoRaised = true
        }

        try? await Task.sleep(for: .milliseconds(180))
        guard !Task.isCancelled else {
            return
        }

        withAnimation(.easeOut(duration: 0.24)) {
            isContentVisible = true
        }

        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else {
            return
        }

        isSplashVisible = false
    }
}

#Preview {
    AnimatedLaunchView()
}

