import SwiftUI

struct CropOverlayMask: View {
    let containerSize: CGSize
    let cropSize: CGSize
    let cropPosition: CGPoint
    let gestureDragOffset: CGSize

    var body: some View {
        let colorBG = Color(hex: "141414")

        ZStack {
            MaskPath(containerSize: containerSize, cropSize: cropSize, offsetY: 0)
                .fill(colorBG, style: FillStyle(eoFill: true))
                .frame(width: cropSize.width, height: cropSize.height)
                .position(
                    x: max(0, cropPosition.x + gestureDragOffset.width),
                    y: max(0, cropPosition.y + gestureDragOffset.height))

            MaskPath(containerSize: containerSize, cropSize: cropSize, offsetY: containerSize.height - cropSize.height)
                .fill(colorBG, style: FillStyle(eoFill: true))
                .frame(width: cropSize.width, height: cropSize.height)
                .position(
                    x: max(0, cropPosition.x + gestureDragOffset.width),
                    y: (cropSize.height - containerSize.height) +
                        (max(0, cropPosition.y) + gestureDragOffset.height))

            MaskPath(
                containerSize: CGSize(width: containerSize.width, height: containerSize.height),
                cropSize: CGSize(width: containerSize.width, height: cropSize.height),
                offsetY: 0,
                isFlipped: true)
                .fill(colorBG, style: FillStyle(eoFill: true))
                .scaleEffect(x: -1, y: -1)
                .rotationEffect(.degrees(180))
                .frame(width: cropSize.width, height: cropSize.height)
                .position(
                    x: cropPosition.x + gestureDragOffset.width,
                    y: cropPosition.y + gestureDragOffset.height - containerSize.height)

            MaskPath(containerSize: containerSize, cropSize: cropSize, offsetX: containerSize.width - cropSize.width)
                .fill(colorBG, style: FillStyle(eoFill: true))
                .frame(width: cropSize.width, height: cropSize.height)
                .position(
                    x: cropSize.width + max(0, cropPosition.x + gestureDragOffset.width) - containerSize.width,
                    y: max(0, cropPosition.y + gestureDragOffset.height))

            MaskPath(
                containerSize: containerSize,
                cropSize: cropSize,
                offsetX: containerSize.width - cropSize.width,
                offsetY: containerSize.height - cropSize.height)
                .fill(colorBG, style: FillStyle(eoFill: true))
                .frame(width: cropSize.width, height: cropSize.height)
                .position(
                    x: cropSize.width + max(0, cropPosition.x + gestureDragOffset.width) - containerSize.width,
                    y: cropSize.height + max(0, cropPosition.y + gestureDragOffset.height) - containerSize.height)
        }
        .compositingGroup()
        .drawingGroup()
        .blendMode(.normal)
        .opacity(0.65)
        .allowsHitTesting(false)
    }
}
