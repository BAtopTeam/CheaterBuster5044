import SwiftUI
import UIKit

struct CropImage: View {
    @Environment(\.dismiss) var dismiss
    
    let image: UIImage
    let onDone: (UIImage) -> Void
    
    @State private var cropSize: CGSize = .zero
    @State private var cropPosition: CGPoint = .zero
    @State private var isDraggingCorner: Bool = false
    @State private var dragLocation: CGPoint = .zero
    @State private var containerSize: CGSize = .zero
    @State private var displayImageSize: CGSize = .zero
    @State private var displayImageOffset: CGPoint = .zero
    @State private var currentGestureDragOffset: CGSize = .zero
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            GeometryReader { geometry in
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    
                    if containerSize == .zero {
                        Color.clear
                            .onAppear {
                                setupCropArea(geometry: geometry)
                            }
                    } else {
                        imageView
                            .overlay {
                                cropOverlay
                            }
                    }
                }
            }
        }
        .background(Color.black)
    }
    
    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.white)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 100)
                            .fill(Color.Colors.black)
                            .opacity(0.6)
                    )
                    .embedInLightGlass(radius: 100, showShadow: false)
                    .contentShape(Capsule())
            }
            
            Spacer()

            Button {
                let croppedImage = applyCrop(
                    in: containerSize,
                    gestureScale: 1.0,
                    gestureDragOffset: currentGestureDragOffset
                )
                onDone(croppedImage)
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.white)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 100)
                            .fill(Color.Colors.black)
                            .opacity(0.6)
                    )
                    .embedInLightGlass(radius: 100, showShadow: false)
                    .contentShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black)
    }
    
    private var imageView: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: containerSize.width, height: containerSize.height)
    }
    
    private var cropOverlay: some View {
        CropFrameWithGestures(
            cropSize: $cropSize,
            cropPosition: $cropPosition,
            containerSize: containerSize,
            isDraggingCorner: isDraggingCorner,
            dragLocation: dragLocation,
            onCropSizeChange: { _ in },
            onCornerDragEnd: {
                isDraggingCorner = false
            },
            onAspectRatioChange: { _ in },
            onDragUpdate: { value in
                let proposedX = cropPosition.x + value.translation.width
                let proposedY = cropPosition.y + value.translation.height
                
                let halfWidth = cropSize.width / 2
                let halfHeight = cropSize.height / 2
                
                let clampedX = min(max(proposedX, halfWidth), containerSize.width - halfWidth)
                let clampedY = min(max(proposedY, halfHeight), containerSize.height - halfHeight)
                
                currentGestureDragOffset = CGSize(width: clampedX - cropPosition.x, height: clampedY - cropPosition.y)
            },
            onDragEnd: { value in
                let proposedX = cropPosition.x + value.translation.width
                let proposedY = cropPosition.y + value.translation.height
                
                let halfWidth = cropSize.width / 2
                let halfHeight = cropSize.height / 2
                
                let clampedX = min(max(proposedX, halfWidth), containerSize.width - halfWidth)
                let clampedY = min(max(proposedY, halfHeight), containerSize.height - halfHeight)
                
                cropPosition = CGPoint(x: clampedX, y: clampedY)
                currentGestureDragOffset = .zero
            }
        )
    }
    
    private func setupCropArea(geometry: GeometryProxy) {
        containerSize = geometry.size
        
        let imageAspectRatio = image.size.width / image.size.height
        let containerAspectRatio = geometry.size.width / geometry.size.height
        
        if imageAspectRatio > containerAspectRatio {
            displayImageSize = CGSize(width: geometry.size.width, height: geometry.size.width / imageAspectRatio)
            displayImageOffset = CGPoint(x: 0, y: (geometry.size.height - displayImageSize.height) / 2)
        } else {
            displayImageSize = CGSize(width: geometry.size.height * imageAspectRatio, height: geometry.size.height)
            displayImageOffset = CGPoint(x: (geometry.size.width - displayImageSize.width) / 2, y: 0)
        }
        
        let initialCropSize = min(displayImageSize.width * 0.8, displayImageSize.height * 0.8)
        cropSize = CGSize(width: initialCropSize, height: initialCropSize)
        cropPosition = CGPoint(
            x: geometry.size.width / 2,
            y: geometry.size.height / 2
        )
    }
    
    func cropImage(
        in geometrySize: CGSize,
        gestureScale: CGFloat,
        gestureDragOffset: CGSize) -> UIImage?
    {
        let fixedImage = image.fixedOrientation()
        guard let cgImage = fixedImage.cgImage else { return nil }

        let imageSize = CGSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = geometrySize.width / geometrySize.height

        var displayedImageSize = CGSize.zero
        var imageOffsetX: CGFloat = 0
        var imageOffsetY: CGFloat = 0

        if imageAspect > containerAspect {
            displayedImageSize.width = geometrySize.width
            displayedImageSize.height = geometrySize.width / imageAspect
            imageOffsetY = (geometrySize.height - displayedImageSize.height) / 2
        } else {
            displayedImageSize.height = geometrySize.height
            displayedImageSize.width = geometrySize.height * imageAspect
            imageOffsetX = (geometrySize.width - displayedImageSize.width) / 2
        }

        let actualFrameWidth = cropSize.width * gestureScale
        let actualFrameHeight = cropSize.height * gestureScale

        let frameCenterX = cropPosition.x + gestureDragOffset.width
        let frameCenterY = cropPosition.y + gestureDragOffset.height

        let frameMinX = frameCenterX - actualFrameWidth / 2
        let frameMinY = frameCenterY - actualFrameHeight / 2
        let frameMaxX = frameMinX + actualFrameWidth
        let frameMaxY = frameMinY + actualFrameHeight

        let imageMinX = imageOffsetX
        let imageMinY = imageOffsetY
        let imageMaxX = imageOffsetX + displayedImageSize.width
        let imageMaxY = imageOffsetY + displayedImageSize.height

        let cropMinX = max(frameMinX, imageMinX)
        let cropMinY = max(frameMinY, imageMinY)
        let cropMaxX = min(frameMaxX, imageMaxX)
        let cropMaxY = min(frameMaxY, imageMaxY)

        guard cropMinX < cropMaxX, cropMinY < cropMaxY else { return fixedImage }

        let cropXInImageView = cropMinX - imageOffsetX
        let cropYInImageView = cropMinY - imageOffsetY
        let cropWidthInImageView = cropMaxX - cropMinX
        let cropHeightInImageView = cropMaxY - cropMinY

        guard cropWidthInImageView > 0, cropHeightInImageView > 0 else { return fixedImage }

        let scaleX = imageSize.width / displayedImageSize.width
        let scaleY = imageSize.height / displayedImageSize.height

        let cropRect = CGRect(
            x: cropXInImageView * scaleX,
            y: cropYInImageView * scaleY,
            width: cropWidthInImageView * scaleX,
            height: cropHeightInImageView * scaleY)

        guard cropRect.width > 0, cropRect.height > 0,
              cropRect.maxX <= imageSize.width,
              cropRect.maxY <= imageSize.height,
              cropRect.minX >= 0,
              cropRect.minY >= 0
        else {
            return fixedImage
        }

        guard let croppedCGImage = cgImage.cropping(to: cropRect) else { return fixedImage }
        let croppedImage = UIImage(cgImage: croppedCGImage, scale: fixedImage.scale, orientation: .up)

        return croppedImage
    }

    func applyCrop(
        in geometrySize: CGSize,
        gestureScale: CGFloat,
        gestureDragOffset: CGSize) -> UIImage
    {
        if let result = cropImage(
            in: geometrySize,
            gestureScale: gestureScale,
            gestureDragOffset: gestureDragOffset)
        {
            return result
        }

        return image
    }
}

extension UIImage {
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2)
        default:
            break
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        guard let cgImage = self.cgImage,
              let colorSpace = cgImage.colorSpace else {
            return self
        }
        
        let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: cgImage.bitmapInfo.rawValue
        )
        
        guard let context = context else {
            return self
        }
        
        context.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        guard let cgImageNew = context.makeImage() else {
            return self
        }
        
        return UIImage(cgImage: cgImageNew, scale: scale, orientation: .up)
    }
}

#Preview {
    CropImage(
        image: UIImage(resource: .rateUs),
        onDone: { _ in }
    )
}
