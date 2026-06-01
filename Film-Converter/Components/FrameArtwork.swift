//
//  FrameArtwork.swift
//  Film-Converter
//

import AppKit
import SwiftUI

struct FrameArtwork: View {
    let frame: FilmFrame
    var showsFrameNumber = false
    var appliesCrop = true
    var appliesTransform = true
    var cornerRadius: CGFloat = 6

    var body: some View {
        ZStack(alignment: .topTrailing) {
            editedImageContent
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

            if showsFrameNumber {
                Text(String(format: "%02d", frame.number))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 4))
                    .padding(8)
            }
        }
    }

    @ViewBuilder
    private var editedImageContent: some View {
        let crop = frame.editSettings.crop

        GeometryReader { proxy in
            let selection = appliesCrop ? crop.selection.rect : CGRect(x: 0, y: 0, width: 1, height: 1)
            let selectionWidth = max(selection.width, 0.05)
            let selectionHeight = max(selection.height, 0.05)
            let expandedCanvasSize = CGSize(
                width: proxy.size.width / selectionWidth,
                height: proxy.size.height / selectionHeight
            )
            let offset = CGSize(
                width: (0.5 - selection.midX) * expandedCanvasSize.width,
                height: (0.5 - selection.midY) * expandedCanvasSize.height
            )

            ZStack {
                transformedImage(
                    canvasSize: expandedCanvasSize,
                    crop: crop
                )
                .offset(x: offset.width, y: offset.height)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .animation(.snappy(duration: 0.24), value: crop.rotationDegrees)
            .animation(.snappy(duration: 0.18), value: crop.isFlippedHorizontally)
            .animation(.snappy(duration: 0.18), value: crop.isFlippedVertically)
        }
    }

    @ViewBuilder
    private func transformedImage(
        canvasSize: CGSize,
        crop: CropSettings
    ) -> some View {
        let shouldApplyTransform = appliesTransform
        let imageFrameSize = shouldApplyTransform && crop.isRotatedSideways
            ? CGSize(width: canvasSize.height, height: canvasSize.width)
            : canvasSize
        let maskRemoval = frame.editSettings.maskRemoval

        let transformed = imageContent
            .frame(width: imageFrameSize.width, height: imageFrameSize.height)
            .rotationEffect(.degrees(shouldApplyTransform ? Double(crop.rotationDegrees) : 0))
            .scaleEffect(
                x: shouldApplyTransform && crop.isFlippedHorizontally ? -1 : 1,
                y: shouldApplyTransform && crop.isFlippedVertically ? -1 : 1
            )
            .brightness(maskRemoval.brightnessAdjustment)
            .contrast(maskRemoval.contrastAdjustment)
            .saturation(maskRemoval.saturationAdjustment)
            .colorMultiply(maskRemoval.colorAdjustment)
            .frame(width: canvasSize.width, height: canvasSize.height)
            .clipped()

        if frame.editSettings.isInverted {
            transformed.colorInvert()
        } else {
            transformed
        }
    }

    @ViewBuilder
    private var imageContent: some View {
        if let url = frame.displayImageURL, let image = ImageCache.image(for: url) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: frame.palette,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    NegativePattern()
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        .opacity(0.34)
                }
        }
    }
}

private struct NegativePattern: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: size.width * 0.36, height: size.width * 0.36)
                        .offset(
                            x: CGFloat(index - 2) * size.width * 0.18,
                            y: CGFloat(index % 2 == 0 ? -1 : 1) * size.height * 0.18
                        )
                        .blur(radius: 18)
                }

                Rectangle()
                    .fill(.black.opacity(0.18))
                    .frame(height: size.height * 0.18)
                    .rotationEffect(.degrees(-18))
                    .offset(y: size.height * 0.2)
            }
        }
    }
}
