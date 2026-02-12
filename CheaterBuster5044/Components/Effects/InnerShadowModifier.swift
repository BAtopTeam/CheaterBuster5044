import SwiftUI

struct InnerShadowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat
    var x: CGFloat = 0
    var y: CGFloat = 0
    var cornerRadiusContent: CGFloat = 100
    
    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadiusContent)
                    .fill(color)
                    .blur(radius: radius)
                    .mask(content)
                    .allowsHitTesting(false)
            }
            
            .overlay {
                content
                    .blur(radius: radius)
                    .offset(x: x, y: y)
                    .mask(content)
                    .allowsHitTesting(false)
            }
    }
}

extension View {
    func innerShadow(
        color: Color,
        radius: CGFloat,
        x: CGFloat = 0,
        y: CGFloat = 0
    ) -> some View {
        modifier(InnerShadowModifier(color: color, radius: radius, x: x, y: y))
    }
}

