import SwiftUI

struct CodeField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        TextField(title, text: $text)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .keyboardType(.asciiCapable)
            .textFieldStyle(.roundedBorder)
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
