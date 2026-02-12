import SwiftUI

struct MaskPath: Shape {
    let containerSize: CGSize
    let cropSize: CGSize
    var offsetX: CGFloat = 0
    var offsetY: CGFloat = 0
    var isFlipped = false

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(CGRect(origin: .zero, size: containerSize))
        let cropRect = CGRect(x: offsetX, y: offsetY, width: cropSize.width, height: cropSize.height)
        path.addRect(cropRect)
        return path
    }
}
