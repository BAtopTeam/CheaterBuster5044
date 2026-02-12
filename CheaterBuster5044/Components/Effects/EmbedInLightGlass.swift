import SwiftUI

struct EmbedInLightGlass: ViewModifier {
    var radius: CGFloat = 100
    var showShadow: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color.Colors.primaryBG.opacity(0.5))
                    .innerShadow(color: Color.Colors.white, radius: radius, x: 2, y: 2)
            )
            .background(
                Color.Colors.white.opacity(0.2)
                    .blur(radius: 10)
                    .clipShape(RoundedRectangle(cornerRadius: radius))
            )
            .contentShape(Rectangle())
            .shadow(color: Color.Colors.shadow.opacity(showShadow ? 1 : 0), radius: 12, y: 5)
    }
}

extension View {
    func embedInLightGlass(radius: CGFloat = 100, showShadow: Bool = false) -> some View {
        self.modifier(EmbedInLightGlass(radius: radius, showShadow: showShadow))
    }
}

#Preview {
    Text("Example")
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .embedInLightGlass()
        .padding()
        .background(Color.Colors.primaryBG)
}
