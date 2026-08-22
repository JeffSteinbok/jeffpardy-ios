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
                    VStack(spacing: 0) {
                        JeffpardyLogo()
                            .frame(maxWidth: 300)
                            .padding(.top, 16)
                            .offset(
                                y: isLogoRaised
                                    ? 0
                                    : (geometry.size.height - 180) / 2
                            )
                        Spacer()
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

        try? await Task.sleep(for: .milliseconds(850))
        guard !Task.isCancelled else {
            return
        }

        withAnimation(.spring(response: 0.55, dampingFraction: 0.84)) {
            isLogoRaised = true
        }

        try? await Task.sleep(for: .milliseconds(240))
        guard !Task.isCancelled else {
            return
        }

        withAnimation(.easeOut(duration: 0.2)) {
            isContentVisible = true
        }

        try? await Task.sleep(for: .milliseconds(200))
        guard !Task.isCancelled else {
            return
        }

        isSplashVisible = false
    }
}

#Preview {
    AnimatedLaunchView()
}
