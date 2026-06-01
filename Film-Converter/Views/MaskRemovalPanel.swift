//
//  MaskRemovalPanel.swift
//  Film-Converter
//

import AppKit
import ImageIO
import SwiftUI

struct MaskRemovalPanel: View {
    @Environment(\.appLanguage) private var language
    @Binding var frame: FilmFrame
    @State private var isProcessing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.text("maskRemoval"))
                        .font(.system(size: 18, weight: .semibold))
                    Text(language.text("maskRemovalSubtitle"))
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

                        Text(isProcessing ? language.text("processingState") : language.text("runMaskRemoval"))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing || frame.imageURL == nil)

                VStack(spacing: 18) {
                    AdjustmentSlider(
                        title: language.text("temperature"),
                        value: $frame.editSettings.maskRemoval.temperature,
                        range: 2000...50000,
                        resetValue: frame.editSettings.maskRemoval.baseTemperature,
                        valueFormatter: { "\(Int($0.rounded()))K" },
                        trackGradient: Gradient(colors: [
                            Color.blue,
                            Color.cyan.opacity(0.85),
                            Color.white.opacity(0.95),
                            Color.yellow
                        ])
                    )

                    AdjustmentSlider(
                        title: language.text("tint"),
                        value: $frame.editSettings.maskRemoval.tint,
                        range: -150...150,
                        resetValue: frame.editSettings.maskRemoval.baseTint,
                        trackGradient: Gradient(colors: [
                            Color.green,
                            Color.white.opacity(0.95),
                            Color.pink
                        ])
                    )

                    AdjustmentSlider(
                        title: language.text("exposure"),
                        value: $frame.editSettings.maskRemoval.exposure,
                        range: -100...100
                    )

                    AdjustmentSlider(
                        title: language.text("contrast"),
                        value: $frame.editSettings.maskRemoval.contrast,
                        range: -100...100
                    )

                    AdjustmentSlider(
                        title: language.text("highlights"),
                        value: $frame.editSettings.maskRemoval.highlights,
                        range: -100...100
                    )

                    AdjustmentSlider(
                        title: language.text("shadows"),
                        value: $frame.editSettings.maskRemoval.shadows,
                        range: -100...100
                    )

                    AdjustmentSlider(
                        title: language.text("whiteLevel"),
                        value: $frame.editSettings.maskRemoval.whiteLevel,
                        range: -100...100
                    )

                    AdjustmentSlider(
                        title: language.text("blackLevel"),
                        value: $frame.editSettings.maskRemoval.blackLevel,
                        range: -100...100
                    )

                    AdjustmentSlider(
                        title: language.text("vibrance"),
                        value: $frame.editSettings.maskRemoval.vibrance,
                        range: -100...100
                    )

                    AdjustmentSlider(
                        title: language.text("saturation"),
                        value: $frame.editSettings.maskRemoval.saturation,
                        range: -100...100
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
        .task(id: frame.displayImageURL) {
            await estimateInitialWhiteBalanceIfNeeded()
        }
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
                frame.editSettings.maskRemoval.lastError = localizedProcessingError(error)
            }

            isProcessing = false
        }
    }

    private func localizedProcessingError(_ error: Error) -> String {
        let message = error.localizedDescription
        if language == .zhHans {
            return message
        }

        switch message {
        case "这张照片没有可处理的源文件。":
            return "This photo has no source file to process."
        case "无法读取这张照片。":
            return "Could not read this photo."
        case "去色罩渲染失败。":
            return "Mask removal rendering failed."
        case "无法写入处理后的照片。":
            return "Could not write the processed photo."
        default:
            return message
        }
    }

    private func estimateInitialWhiteBalanceIfNeeded() async {
        guard !frame.editSettings.maskRemoval.hasEstimatedWhiteBalance,
              let imageURL = frame.displayImageURL else {
            return
        }

        let estimate = await Task.detached(priority: .utility) {
            WhiteBalanceEstimate.load(from: imageURL)
        }.value

        guard !Task.isCancelled else {
            return
        }

        frame.editSettings.maskRemoval.baseTemperature = estimate.temperature
        frame.editSettings.maskRemoval.baseTint = estimate.tint
        frame.editSettings.maskRemoval.temperature = estimate.temperature
        frame.editSettings.maskRemoval.tint = estimate.tint
        frame.editSettings.maskRemoval.hasEstimatedWhiteBalance = true
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

private struct WhiteBalanceEstimate: Sendable {
    let temperature: Double
    let tint: Double

    nonisolated static func load(from url: URL) -> WhiteBalanceEstimate {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return WhiteBalanceEstimate(temperature: 6500, tint: 0)
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 180
        ]

        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
              let pixels = rgbaPixels(from: image) else {
            return WhiteBalanceEstimate(temperature: 6500, tint: 0)
        }

        var redTotal = 0.0
        var greenTotal = 0.0
        var blueTotal = 0.0
        var sampleCount = 0.0

        for index in stride(from: 0, to: pixels.count, by: 4) {
            let red = Double(pixels[index]) / 255
            let green = Double(pixels[index + 1]) / 255
            let blue = Double(pixels[index + 2]) / 255
            let luma = 0.2126 * red + 0.7152 * green + 0.0722 * blue

            guard luma > 0.08, luma < 0.92 else {
                continue
            }

            redTotal += red
            greenTotal += green
            blueTotal += blue
            sampleCount += 1
        }

        guard sampleCount > 0 else {
            return WhiteBalanceEstimate(temperature: 6500, tint: 0)
        }

        let averageRed = redTotal / sampleCount
        let averageGreen = greenTotal / sampleCount
        let averageBlue = blueTotal / sampleCount
        let magenta = (averageRed + averageBlue) / 2
        let redBlueBias = averageRed - averageBlue

        return WhiteBalanceEstimate(
            temperature: clamp(6500 - redBlueBias * 9000, to: 2000...50000).rounded(),
            tint: clamp((magenta - averageGreen) * 170, to: -150...150).rounded()
        )
    }

    nonisolated private static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
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
        redFactor = (1 + settings.temperatureAdjustment / 170 + settings.tintAdjustment / 380).clamped(to: 0.55...1.6)
        greenFactor = (1 - settings.tintAdjustment / 170).clamped(to: 0.55...1.6)
        blueFactor = (1 - settings.temperatureAdjustment / 170 + settings.tintAdjustment / 380).clamped(to: 0.55...1.6)
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

private struct AdjustmentSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var resetValue = 0.0
    var valueFormatter: (Double) -> String = { "\(Int($0.rounded()))" }
    var trackGradient: Gradient?

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

            slider
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded {
                        withAnimation(.snappy(duration: 0.16)) {
                            value = resetValue
                        }
                    }
            )
        }
    }

    @ViewBuilder
    private var slider: some View {
        if let trackGradient {
            NativeColoredSlider(
                value: $value,
                range: range,
                resetValue: resetValue,
                gradient: trackGradient
            )
        } else {
            nativeSlider
                .frame(height: 26)
                .tint(Color(nsColor: .secondaryLabelColor))
        }
    }

    private var nativeSlider: some View {
        Slider(
            value: Binding(
                get: { value },
                set: { value = $0.rounded() }
            ),
            in: range,
            step: 1
        )
        .labelsHidden()
        .controlSize(.regular)
    }
}

private struct NativeColoredSlider: NSViewRepresentable {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let resetValue: Double
    let gradient: Gradient

    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value)
    }

    func makeNSView(context: Context) -> ResettableNSSlider {
        let slider = ResettableNSSlider(value: value, minValue: range.lowerBound, maxValue: range.upperBound, target: context.coordinator, action: #selector(Coordinator.valueChanged(_:)))
        slider.isContinuous = true
        slider.controlSize = .regular
        slider.cell = ColoredSliderCell(gradientColors: nsColors(from: gradient))
        slider.onDoubleClick = {
            value = resetValue
        }
        return slider
    }

    func updateNSView(_ nsView: ResettableNSSlider, context: Context) {
        if nsView.minValue != range.lowerBound {
            nsView.minValue = range.lowerBound
        }
        if nsView.maxValue != range.upperBound {
            nsView.maxValue = range.upperBound
        }
        if nsView.doubleValue != value {
            nsView.doubleValue = value
        }
        if let cell = nsView.cell as? ColoredSliderCell {
            cell.gradientColors = nsColors(from: gradient)
        }
        nsView.onDoubleClick = {
            value = resetValue
        }
    }

    private func nsColors(from gradient: Gradient) -> [NSColor] {
        gradient.stops.map { stop in
            NSColor(stop.color).usingColorSpace(.sRGB) ?? .white
        }
    }

    final class Coordinator: NSObject {
        @Binding var value: Double

        init(value: Binding<Double>) {
            _value = value
        }

        @objc func valueChanged(_ sender: NSSlider) {
            value = sender.doubleValue.rounded()
        }
    }
}

private final class ResettableNSSlider: NSSlider {
    var onDoubleClick: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            onDoubleClick?()
            return
        }

        super.mouseDown(with: event)
    }
}

private final class ColoredSliderCell: NSSliderCell {
    var gradientColors: [NSColor]

    init(gradientColors: [NSColor]) {
        self.gradientColors = gradientColors
        super.init()
    }

    required init(coder: NSCoder) {
        gradientColors = [.controlAccentColor, .controlAccentColor]
        super.init(coder: coder)
    }

    override func drawBar(inside rect: NSRect, flipped: Bool) {
        let barHeight = 4.0
        let barRect = NSRect(
            x: rect.minX + 2,
            y: rect.midY - barHeight / 2,
            width: max(rect.width - 4, 1),
            height: barHeight
        )
        let path = NSBezierPath(roundedRect: barRect, xRadius: barHeight / 2, yRadius: barHeight / 2)

        NSColor.separatorColor.withAlphaComponent(0.18).setFill()
        path.fill()

        NSGraphicsContext.saveGraphicsState()
        path.addClip()
        NSGradient(colors: gradientColors)?.draw(in: barRect, angle: 0)
        NSGraphicsContext.restoreGraphicsState()

        NSColor.white.withAlphaComponent(0.36).setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }
}
