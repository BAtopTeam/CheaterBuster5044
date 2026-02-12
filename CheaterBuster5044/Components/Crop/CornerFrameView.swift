import SwiftUI

struct CornerFrameView: View {
    @Binding var cropSize: CGSize
    @Binding var cropPosition: CGPoint
    var containerSize: CGSize

    var fixedAspectRatio: CGFloat?
    var aspectRatioHandler: ((CGSize) -> Void)?

    @State private var currentFrameSize: CGSize = .zero
    @State private var startCropSize: CGSize = .zero
    @State private var startCropPosition: CGPoint = .zero
    @State private var activeCorner: Corner? = nil

    var isDraggingCorner: Bool
    var dragLocation: CGPoint
    var onCornerDragEnded: () -> Void = {}

    let lineLength: CGFloat = 20
    let frameWidth: CGFloat = 1
    let cornerWidth: CGFloat = 4
    let color: Color = Color.black
    let handleSize: CGFloat = 44

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            Color.clear
                .onAppear {
                    currentFrameSize = size
                }
                .onChange(of: size) { newSize in
                    currentFrameSize = newSize
                }

            ZStack {
                Rectangle()
                    .stroke(color, lineWidth: frameWidth)

                cornerHandle(.topLeft)
                cornerHandle(.topRight)
                cornerHandle(.bottomLeft)
                cornerHandle(.bottomRight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    func position(for corner: Corner) -> CGPoint {
        switch corner {
            case .topLeft:
                return CGPoint(x: cropPosition.x - cropSize.width / 2, y: cropPosition.y - cropSize.height / 2)
            case .topRight:
                return CGPoint(x: cropPosition.x + cropSize.width / 2, y: cropPosition.y - cropSize.height / 2)
            case .bottomLeft:
                return CGPoint(x: cropPosition.x - cropSize.width / 2, y: cropPosition.y + cropSize.height / 2)
            case .bottomRight:
                return CGPoint(x: cropPosition.x + cropSize.width / 2, y: cropPosition.y + cropSize.height / 2)
        }
    }

    enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    private func cornerHandle(_ corner: Corner) -> some View {
        let position: CGPoint = {
            switch corner {
                case .topLeft: return CGPoint(x: 0, y: 0)
                case .topRight: return CGPoint(x: currentFrameSize.width, y: 0)
                case .bottomLeft: return CGPoint(x: 0, y: currentFrameSize.height)
                case .bottomRight: return CGPoint(x: currentFrameSize.width, y: currentFrameSize.height)
            }
        }()

        return Circle()
            .fill(Color.white)
            .frame(width: 24, height: 24)
            .frame(width: handleSize, height: handleSize)
            .contentShape(Rectangle())
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if startCropSize == .zero {
                            startCropSize = cropSize
                            startCropPosition = cropPosition
                        }

                        activeCorner = corner

                        let dx = value.translation.width
                        let dy = value.translation.height

                        var newSize = startCropSize
                        var newPosition = startCropPosition

                        let newPosX = max(0, min(dragLocation.x - 10, dx / 2))
                        let newPosY = max(0, min(dragLocation.y - 10, dy / 2))

                        switch corner {
                            case .topLeft:
                                newSize.width -= dx
                                newSize.height -= dy
                                newPosition.x += newPosX
                                newPosition.y += newPosY
                            case .topRight:
                                newSize.width += dx
                                newSize.height -= dy
                                newPosition.x += newPosX
                                newPosition.y += newPosY
                            case .bottomLeft:
                                newSize.width -= dx
                                newSize.height += dy
                                newPosition.x += newPosX
                                newPosition.y += newPosY
                            case .bottomRight:
                                newSize.width += dx
                                newSize.height += dy
                                newPosition.x += newPosX
                                newPosition.y += newPosY
                        }

                        if let aspectRatio = fixedAspectRatio {
                            let calculatedHeight = newSize.width / aspectRatio
                            newSize.height = calculatedHeight

                            if newSize.height > containerSize.height {
                                newSize.height = containerSize.height
                                newSize.width = newSize.height * aspectRatio
                            }

                            newSize.width = min(max(100, newSize.width), containerSize.width)
                            newSize.height = min(max(100, newSize.height), containerSize.height)
                        } else {
                            newSize.width = max(100, min(newSize.width, containerSize.width))
                            newSize.height = max(100, min(newSize.height, containerSize.height))
                        }

                        let halfWidth = newSize.width / 2
                        let halfHeight = newSize.height / 2

                        newPosition.x = min(max(newPosition.x, halfWidth), containerSize.width - halfWidth)
                        newPosition.y = min(max(newPosition.y, halfHeight), containerSize.height - halfHeight)

                        cropSize = newSize
                        cropPosition = newPosition
                    }
                    .onEnded { _ in
                        startCropSize = .zero
                        startCropPosition = .zero
                        activeCorner = nil
                        onCornerDragEnded()
                    })
    }
}

struct CornerIndicatorShape: Shape {
    let corner: CornerFrameView.Corner

    func path(in rect: CGRect) -> Path {
        var path = Path()

        switch corner {
            case .topLeft:
                path.move(to: CGPoint(x: 0, y: rect.height))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: rect.width, y: 0))

            case .topRight:
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: rect.width, y: 0))
                path.addLine(to: CGPoint(x: rect.width, y: rect.height))

            case .bottomLeft:
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: rect.height))
                path.addLine(to: CGPoint(x: rect.width, y: rect.height))

            case .bottomRight:
                path.move(to: CGPoint(x: rect.width, y: 0))
                path.addLine(to: CGPoint(x: rect.width, y: rect.height))
                path.addLine(to: CGPoint(x: 0, y: rect.height))
        }

        return path
    }
}
