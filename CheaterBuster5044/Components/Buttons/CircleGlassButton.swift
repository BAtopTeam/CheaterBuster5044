import SwiftUI

struct CircleGlassButton: View {
    var icn: ImageResource
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(icn)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .padding(10)
                .embedInLightGlass(radius: 0, showShadow: false)
                .contentShape(Circle())
        }
    }
}

#Preview {
    CircleGlassButton(icn: .Icns.chevronLeft, action: { })
}
