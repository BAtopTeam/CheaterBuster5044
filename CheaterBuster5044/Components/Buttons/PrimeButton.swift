import SwiftUI

struct PrimeButton: View {
    var title: String
    var action: () -> Void
    var isActive: Bool = true
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.Colors.white)
                .padding(.vertical, 17.5)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(LinearGradient(colors: [Color.Colors.accentTop, Color.Colors.accentBottom],
                                             startPoint: .top, endPoint: .bottom))
                )
                .animation(.interpolatingSpring(duration: 0.2), value: isActive)
                .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!isActive)
        .opacity(isActive ? 1 : 0.5)
    }
}

#Preview {
    PrimeButton(title: "Example", action: {})
}
