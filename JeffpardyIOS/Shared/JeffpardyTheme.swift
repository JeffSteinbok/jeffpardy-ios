import SwiftUI

enum JeffpardyTheme {
    static let board = Color(red: 0.082, green: 0.133, blue: 0.545)
    static let boardLight = Color(red: 0.12, green: 0.20, blue: 0.68)
    static let boardDark = Color(red: 0.025, green: 0.055, blue: 0.22)
    static let gold = Color(red: 0.945, green: 0.796, blue: 0.663)
    static let chrome = Color(red: 0.035, green: 0.035, blue: 0.075)
    static let inactive = Color(red: 0.18, green: 0.18, blue: 0.24)
}

struct JeffpardyBackground: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            RadialGradient(
                colors: [JeffpardyTheme.boardLight, JeffpardyTheme.boardDark],
                center: .center,
                startRadius: 20,
                endRadius: 620
            )
            .ignoresSafeArea()

            Canvas { context, size in
                for index in 0..<52 {
                    let x = CGFloat((index * 83 + 29) % 997) / 997 * size.width
                    let y = CGFloat((index * 137 + 71) % 991) / 991 * size.height
                    let diameter = CGFloat(index % 3 + 1)
                    let rect = CGRect(x: x, y: y, width: diameter, height: diameter)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(.white.opacity(index % 4 == 0 ? 0.7 : 0.35))
                    )
                }
            }
            .ignoresSafeArea()

            content
        }
        .foregroundStyle(.white)
    }
}

extension View {
    func jeffpardyBackground() -> some View {
        modifier(JeffpardyBackground())
    }
}

struct JeffpardyLogo: View {
    var body: some View {
        Image("JeffpardyTitle")
            .resizable()
            .scaledToFit()
            .shadow(color: .black.opacity(0.65), radius: 18, y: 10)
            .accessibilityLabel("Jeffpardy")
    }
}

struct JeffpardyCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.16, blue: 0.42),
                        Color(red: 0.035, green: 0.075, blue: 0.25),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(JeffpardyTheme.gold.opacity(0.4), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
    }
}

struct JeffpardyPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.heavy))
            .textCase(.uppercase)
            .tracking(1.2)
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.12, green: 0.20, blue: 0.52), JeffpardyTheme.boardDark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(JeffpardyTheme.gold.opacity(0.55), lineWidth: 1)
            }
            .shadow(color: JeffpardyTheme.gold.opacity(0.25), radius: 14)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
    }
}

struct JeffpardyTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.title3.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.black.opacity(0.32))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.22), lineWidth: 1)
            }
    }
}

struct JeffpardyAttribution: View {
    var body: some View {
        Text(
            "Jeffpardy was created to pass the time during COVID-19. The Jeopardy! game show and all elements thereof are the property of Jeopardy Productions, Inc. This app is not affiliated with, sponsored by, or operated by Jeopardy Productions, Inc."
        )
        .font(.system(size: 8))
        .multilineTextAlignment(.center)
        .foregroundStyle(.white.opacity(0.5))
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("About Jeffpardy")
    }
}
