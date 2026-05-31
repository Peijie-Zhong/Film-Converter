//
//  MaskRemovalPanel.swift
//  Film-Converter
//

import AppKit
import ImageIO
import SwiftUI

struct MaskRemovalPanel: View {
    @Binding var frame: FilmFrame
    @State private var isProcessing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("去色罩")
                        .font(.system(size: 18, weight: .semibold))
                    Text("反转负片并校正胶片底色")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                MaskHistogramView(
                    imageURL: frame.displayImageURL,
                    adjustment: HistogramAdjustment(settings: frame.editSettings.maskRemoval)
                )
                    .frame(height: 112)

                Button {
                    removeMask()
                } label: {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "wand.and.stars.inverse")
                        }

                        Text(isProcessing ? "处理中" : "执行去色罩")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing || frame.imageURL == nil)

                VStack(spacing: 18) {
                    GradientAdjustmentSlider(
                        title: "色温",
                        value: $frame.editSettings.maskRemoval.temperature,
                        range: -100...100,
                        gradient: Gradient(colors: [.blue, .white, .yellow])
                    )

                    GradientAdjustmentSlider(
                        title: "色调",
                        value: $frame.editSettings.maskRemoval.tint,
                        range: -100...100,
                        gradient: Gradient(colors: [.green, .white, .pink])
                    )

                    GradientAdjustmentSlider(
                        title: "曝光度",
                        value: $frame.editSettings.maskRemoval.exposure,
                        range: -100...100,
                        gradient: Gradient(colors: [.black, .gray, .white])
                    )

                    GradientAdjustmentSlider(
                        title: "对比度",
                        value: $frame.editSettings.maskRemoval.contrast,
                        range: -100...100,
                        gradient: Gradient(colors: [.gray.opacity(0.45), .white, .black])
                    )

                    GradientAdjustmentSlider(
                        title: "高光",
                        value: $frame.editSettings.maskRemoval.highlights,
                        range: -100...100,
                        gradient: Gradient(colors: [.gray, .white])
                    )

                    GradientAdjustmentSlider(
                        title: "阴影",
                        value: $frame.editSettings.maskRemoval.shadows,
                        range: -100...100,
                        gradient: Gradient(colors: [.black, .gray])
                    )

                    GradientAdjustmentSlider(
                        title: "白色色阶",
                        value: $frame.editSettings.maskRemoval.whiteLevel,
                        range: -100...100,
                        gradient: Gradient(colors: [.gray.opacity(0.5), .white])
                    )

                    GradientAdjustmentSlider(
                        title: "黑色色阶",
                        value: $frame.editSettings.maskRemoval.blackLevel,
                        range: -100...100,
                        gradient: Gradient(colors: [.black, .gray.opacity(0.75)])
                    )

                    GradientAdjustmentSlider(
                        title: "鲜艳度",
                        value: $frame.editSettings.maskRemoval.vibrance,
                        range: -100...100,
                        gradient: Gradient(colors: [.gray, .orange, .pink])
                    )

                    GradientAdjustmentSlider(
                        title: "饱和度",
                        value: $frame.editSettings.maskRemoval.saturation,
                        range: -100...100,
                        gradient: Gradient(colors: [.gray, .red, .purple])
                    )
                }

                if let error = frame.editSettings.maskRemoval.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(18)
        }
        .frame(width: 268)
    }

    private func removeMask() {
        let currentFrame = frame

        isProcessing = true
        frame.editSettings.maskRemoval.lastError = nil

        Task {
            do {
                let outputURL = try await Task.detached(priority: .userInitiated) {
                    try MaskRemovalProcessor.process(frame: currentFrame)
                }.value

                frame.editSettings.maskRemoval.processedImageURL = outputURL
                frame.editSettings.maskRemoval.lastError = nil
            } catch {
                frame.editSettings.maskRemoval.lastError = error.localizedDescription
            }

            isProcessing = false
        }
    }
}

private struct MaskHistogramView: View {
    let imageURL: URL?
    let adjustment: HistogramAdjustment
    @State private var histogram = HistogramData.empty

    var body: some View {
        let request = HistogramRequest(imageURL: imageURL, adjustment: adjustment)

        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)

            context.fill(
                Path(roundedRect: rect, cornerRadius: 8),
                with: .color(Color(nsColor: .controlBackgroundColor))
            )

            draw(histogram.red, color: .red.opacity(0.82), in: rect, context: &context)
            draw(histogram.green, color: .green.opacity(0.82), in: rect, context: &context)
            draw(histogram.blue, color: .blue.opacity(0.82), in: rect, context: &context)

            context.stroke(
                Path(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 8),
                with: .color(.white.opacity(0.16)),
                lineWidth: 1
            )
        }
        .task(id: request) {
            do {
                try await Task.sleep(for: .milliseconds(70))
            } catch {
                return
            }

            let nextHistogram = await Task.detached(priority: .utility) {
                HistogramData.load(from: request.imageURL, adjustment: request.adjustment)
            }.value

            guard !Task.isCancelled else {
                return
            }

            histogram = nextHistogram
        }
    }

    private func draw(
        _ bins: [Double],
        color: Color,
        in rect: CGRect,
        context: inout GraphicsContext
    ) {
        guard bins.count > 1 else {
            return
        }

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))

        for index in bins.indices {
            let x = rect.minX + CGFloat(index) / CGFloat(bins.count - 1) * rect.width
            let y = rect.maxY - CGFloat(bins[index]) * rect.height
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()

        context.fill(path, with: .color(color.opacity(0.22)))
        context.stroke(path, with: .color(color), lineWidth: 1.2)
    }

}

private struct HistogramData: Equatable {
    var red: [Double]
    var green: [Double]
    var blue: [Double]

    nonisolated static let empty = HistogramData(
        red: [Double](repeating: 0, count: 64),
        green: [Double](repeating: 0, count: 64),
        blue: [Double](repeating: 0, count: 64)
    )

    nonisolated init(red: [Double], green: [Double], blue: [Double]) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    nonisolated static func load(from url: URL?, adjustment: HistogramAdjustment) -> HistogramData {
        guard let url,
              let image = downsampledImage(from: url),
              let data = rgbaPixels(from: image) else {
            return .empty
        }

        var red = [Double](repeating: 0, count: 64)
        var green = [Double](repeating: 0, count: 64)
        var blue = [Double](repeating: 0, count: 64)

        for index in stride(from: 0, to: data.count, by: 4) {
            let adjusted = adjustment.apply(
                red: Double(data[index]) / 255,
                green: Double(data[index + 1]) / 255,
                blue: Double(data[index + 2]) / 255
            )

            red[Int(adjusted.red * 255) / 4] += 1
            green[Int(adjusted.green * 255) / 4] += 1
            blue[Int(adjusted.blue * 255) / 4] += 1
        }

        return HistogramData(
            red: normalized(red),
            green: normalized(green),
            blue: normalized(blue)
        )
    }

    nonisolated private static func downsampledImage(from url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 256
        ]

        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    nonisolated private static func rgbaPixels(from image: CGImage) -> [UInt8]? {
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: &pixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return nil
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixels
    }

    nonisolated private static func normalized(_ bins: [Double]) -> [Double] {
        let maxValue = bins.max() ?? 0

        guard maxValue > 0 else {
            return bins
        }

        return bins.map { sqrt($0 / maxValue) }
    }
}

private struct HistogramRequest: Hashable {
    let imageURL: URL?
    let adjustment: HistogramAdjustment
}

private struct HistogramAdjustment: Hashable, Sendable {
    let redFactor: Double
    let greenFactor: Double
    let blueFactor: Double
    let brightness: Double
    let contrast: Double
    let saturation: Double

    init(settings: MaskRemovalSettings) {
        redFactor = (1 + settings.temperature / 170 + settings.tint / 380).clamped(to: 0.55...1.6)
        greenFactor = (1 - settings.tint / 170).clamped(to: 0.55...1.6)
        blueFactor = (1 - settings.temperature / 170 + settings.tint / 380).clamped(to: 0.55...1.6)
        brightness = settings.brightnessAdjustment
        contrast = settings.contrastAdjustment
        saturation = settings.saturationAdjustment
    }

    nonisolated func apply(red: Double, green: Double, blue: Double) -> (red: Double, green: Double, blue: Double) {
        let brightenedRed = red + brightness
        let brightenedGreen = green + brightness
        let brightenedBlue = blue + brightness

        let contrastedRed = (brightenedRed - 0.5) * contrast + 0.5
        let contrastedGreen = (brightenedGreen - 0.5) * contrast + 0.5
        let contrastedBlue = (brightenedBlue - 0.5) * contrast + 0.5

        let luma = 0.2126 * contrastedRed + 0.7152 * contrastedGreen + 0.0722 * contrastedBlue
        let saturatedRed = luma + (contrastedRed - luma) * saturation
        let saturatedGreen = luma + (contrastedGreen - luma) * saturation
        let saturatedBlue = luma + (contrastedBlue - luma) * saturation

        return (
            clamp(saturatedRed * redFactor),
            clamp(saturatedGreen * greenFactor),
            clamp(saturatedBlue * blueFactor)
        )
    }

    nonisolated private func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

private struct GradientAdjustmentSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let gradient: Gradient
    var resetValue = 0.0
    var valueFormatter: (Double) -> String = { "\(Int($0.rounded()))" }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(valueFormatter(value))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            GeometryReader { proxy in
                let knobX = xPosition(in: proxy.size.width)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .frame(height: 14)
                        .overlay {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: gradient,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .opacity(0.72)
                                )
                                .padding(3)
                        }
                        .overlay(alignment: .top) {
                            Capsule()
                                .fill(.white.opacity(0.34))
                                .frame(height: 3)
                                .padding(.horizontal, 5)
                                .padding(.top, 3)
                        }
                        .overlay {
                            Capsule()
                                .strokeBorder(.white.opacity(0.32), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.12), radius: 5, y: 2)

                    Circle()
                        .fill(.thinMaterial)
                        .frame(width: 22, height: 22)
                        .overlay {
                            Circle()
                                .strokeBorder(.white.opacity(0.72), lineWidth: 1.2)
                        }
                        .overlay(alignment: .topLeading) {
                            Circle()
                                .fill(.white.opacity(0.68))
                                .frame(width: 7, height: 7)
                                .padding(5)
                        }
                        .shadow(color: .black.opacity(0.28), radius: 7, y: 2)
                        .offset(x: knobX - 11)
                }
                .frame(height: 26)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            updateValue(x: gesture.location.x, width: proxy.size.width)
                        }
                )
                .simultaneousGesture(
                    TapGesture(count: 2)
                        .onEnded {
                            withAnimation(.snappy(duration: 0.16)) {
                                value = resetValue
                            }
                        }
                )
            }
            .frame(height: 26)
        }
    }

    private func xPosition(in width: CGFloat) -> CGFloat {
        let progress = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return CGFloat(progress.clamped(to: 0...1)) * width
    }

    private func updateValue(x: CGFloat, width: CGFloat) {
        let progress = Double((x / max(width, 1)).clamped(to: 0...1))
        let nextValue = (range.lowerBound + progress * (range.upperBound - range.lowerBound)).rounded()

        if nextValue != value {
            value = nextValue
        }
    }
}
