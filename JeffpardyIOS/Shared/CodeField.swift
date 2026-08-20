import SwiftUI

struct CodeField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        TextField(
            "",
            text: $text,
            prompt: Text(title).foregroundStyle(.white.opacity(0.55))
        )
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .keyboardType(.asciiCapable)
            .textFieldStyle(JeffpardyTextFieldStyle())
            .onChange(of: text) { _, newValue in
                text = String(
                    newValue
                        .uppercased()
                        .filter { $0.isLetter || $0.isNumber }
                        .prefix(6)
                )
            }
    }
}
