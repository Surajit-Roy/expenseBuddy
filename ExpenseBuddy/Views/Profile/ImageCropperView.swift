//
//  ImageCropperView.swift
//  ExpenseBuddy
//

import SwiftUI

struct ImageCropperView: View {
    let image: UIImage
    let onCropped: (UIImage) -> Void
    let onCancel: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isProcessing = false
    
    private let cropSize: CGFloat = 280
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                topBar
                
                Spacer()
                
                // Crop area
                cropArea
                
                Spacer()
                
                // Hint
                Text("Pinch to zoom, drag to reposition")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 20)
                
                // Bottom bar
                bottomBar
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("Move and Scale")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Invisible spacer to balance layout
            Text("Cancel")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.clear)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // MARK: - Crop Area
    
    private var cropArea: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            
            ZStack {
                // Movable / zoomable image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cropSize, height: cropSize)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(dragGesture)
                    .gesture(magnificationGesture)
                    .position(center)
                
                // Dark overlay with circular cutout
                overlayMask(center: center, in: geo.size)
                
                // Circle border
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: cropSize, height: cropSize)
                    .position(center)
            }
        }
    }
    
    private func overlayMask(center: CGPoint, in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            // Full dark overlay
            let fullRect = CGRect(origin: .zero, size: canvasSize)
            context.fill(Path(fullRect), with: .color(.black.opacity(0.6)))
            
            // Punch out the circle
            let circleRect = CGRect(
                x: center.x - cropSize / 2,
                y: center.y - cropSize / 2,
                width: cropSize,
                height: cropSize
            )
            context.blendMode = .destinationOut
            context.fill(Path(ellipseIn: circleRect), with: .color(.white))
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Bottom Bar
    
    private var bottomBar: some View {
        HStack {
            Button(action: {
                // Reset
                scale = 1.0
                lastScale = 1.0
                offset = .zero
                lastOffset = .zero
            }) {
                Text("Reset")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    isProcessing = true
                    await performCrop()
                    isProcessing = false
                }
            }) {
                HStack(spacing: 8) {
                    if isProcessing {
                        ProgressView().tint(.white)
                    }
                    Text("Choose")
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
            .disabled(isProcessing)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
    
    // MARK: - Gestures
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                // Add boundary checks here if we want to prevent dragging too far
                lastOffset = offset
            }
    }
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                scale *= delta
                scale = min(max(scale, 1.0), 4.0)
            }
            .onEnded { _ in
                lastScale = 1.0
            }
    }
    
    // MARK: - Crop Logic
    
    private func performCrop() async {
        // Output size for the profile picture (128x128 is perfect for avatars and makes data ~5x smaller)
        let outputSize: CGFloat = 128
        
        // 1. Move the heavy lifting to a background thread
        let resultImage = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            // 0. Normalize the image orientation (crucial for accurate cropping)
            guard let normalizedImage = image.normalized(),
                  let cgImage = normalizedImage.cgImage else {
                return nil
            }
            
            let imageSize = normalizedImage.size
            
            // 1. Determine the displayed size of the image within the crop area (before scaling)
            let aspect = imageSize.width / imageSize.height
            let baseWidth: CGFloat
            let baseHeight: CGFloat
            
            if aspect > 1 { // Landscape
                baseHeight = cropSize
                baseWidth = cropSize * aspect
            } else { // Portrait
                baseWidth = cropSize
                baseHeight = cropSize / aspect
            }
            
            // 2. Apply scale
            let scaledWidth = baseWidth * scale
            let scaledHeight = baseHeight * scale
            
            // 3. Coordinate conversion
            let scaleFactor = imageSize.width / scaledWidth
            
            let dx = -offset.width * scaleFactor
            let dy = -offset.height * scaleFactor
            
            let cropWidthInImage = cropSize * scaleFactor
            let cropHeightInImage = cropSize * scaleFactor
            
            let originX = (imageSize.width - cropWidthInImage) / 2 + dx
            let originY = (imageSize.height - cropHeightInImage) / 2 + dy
            
            let cropRect = CGRect(
                x: max(0, originX),
                y: max(0, originY),
                width: min(cropWidthInImage, imageSize.width - max(0, originX)),
                height: min(cropHeightInImage, imageSize.height - max(0, originY))
            )
            
            // 4. Perform the crop
            guard let croppedCgImage = cgImage.cropping(to: cropRect) else {
                return nil
            }
            
            let croppedImage = UIImage(cgImage: croppedCgImage)
            
            // 5. Resize to final output size
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: outputSize, height: outputSize))
            let finalImage = renderer.image { _ in
                croppedImage.draw(in: CGRect(origin: .zero, size: CGSize(width: outputSize, height: outputSize)))
            }
            
            return finalImage
        }.value
        
        if let resultImage {
            onCropped(resultImage)
        } else {
            onCropped(image)
        }
    }
}

// MARK: - UIImage Orientation Helper
extension UIImage {
    func normalized() -> UIImage? {
        if imageOrientation == .up { return self }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }
}
