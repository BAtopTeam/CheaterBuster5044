import SwiftUI

struct CropFrameWithGestures: View {
    @Binding var cropSize: CGSize
    @Binding var cropPosition: CGPoint
    let containerSize: CGSize
    let isDraggingCorner: Bool
    let dragLocation: CGPoint
    @GestureState private var gestureDragOffset: CGSize = .zero

    let onCropSizeChange: (CGSize) -> Void
    let onCornerDragEnd: () -> Void
    let onAspectRatioChange: (CGSize) -> Void
    let onDragUpdate: (DragGesture.Value) -> Void
    let onDragEnd: (DragGesture.Value) -> Void

    var body: some View {
        ZStack {
            CropOverlayMask(
                containerSize: containerSize,
                cropSize: cropSize,
                cropPosition: cropPosition,
                gestureDragOffset: gestureDragOffset)

            CornerFrameView(
                cropSize: $cropSize,
                cropPosition: $cropPosition,
                containerSize: containerSize,
                fixedAspectRatio: nil,
                aspectRatioHandler: onAspectRatioChange,
                isDraggingCorner: isDraggingCorner,
                dragLocation: dragLocation,
                onCornerDragEnded: onCornerDragEnd)
                .onChange(of: cropSize, perform: onCropSizeChange)
                .background(Color.black.opacity(0.001))
                .frame(width: cropSize.width, height: cropSize.height)
                .position(
                    x: max(0, cropPosition.x + gestureDragOffset.width),
                    y: cropPosition.y + gestureDragOffset.height)
        }
        .gesture(
            DragGesture()
                .updating($gestureDragOffset) { value, state, _ in
                    onDragUpdate(value)
                    let proposedX = cropPosition.x + value.translation.width
                    let proposedY = cropPosition.y + value.translation.height

                    let halfWidth = cropSize.width / 2
                    let halfHeight = cropSize.height / 2

                    let clampedX = min(max(proposedX, halfWidth), containerSize.width - halfWidth)
                    let clampedY = min(max(proposedY, halfHeight), containerSize.height - halfHeight)

                    state = CGSize(width: clampedX - cropPosition.x, height: clampedY - cropPosition.y)
                }
                .onEnded(onDragEnd))
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var cropSize = CGSize(width: 200, height: 200)
        @State private var cropPosition = CGPoint(x: 200, y: 300)
        
        var body: some View {
            ZStack {
                Color.gray.opacity(0.3)
                    .ignoresSafeArea()
                
                CropFrameWithGestures(
                    cropSize: $cropSize,
                    cropPosition: $cropPosition,
                    containerSize: CGSize(width: 400, height: 600),
                    isDraggingCorner: false,
                    dragLocation: .zero,
                    onCropSizeChange: { _ in },
                    onCornerDragEnd: {},
                    onAspectRatioChange: { _ in },
                    onDragUpdate: { _ in },
                    onDragEnd: { _ in }
                )
            }
        }
    }
    
    return PreviewWrapper()
}
