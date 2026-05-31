//
//  MaskRemovalProcessor.swift
//  Film-Converter
//

import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

enum MaskRemovalProcessor {
    nonisolated static func process(frame: FilmFrame) throws -> URL {
        guard let sourceURL = frame.imageURL else {
            throw MaskRemovalError.missingSourceImage
        }

        let maxPixelSize = 3200
        guard let sourceImage = downsampledImage(from: sourceURL, maxPixelSize: maxPixelSize) else {
            throw MaskRemovalError.unreadableSourceImage
        }

        let width = sourceImage.width
        let height = sourceImage.height
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
            throw MaskRemovalError.renderFailed
        }

        context.draw(sourceImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let sampleArea = sampleArea(width: width, height: height)
        var histograms = ChannelHistograms()
        var samplePixelCount = 0

        for y in sampleArea.yRange {
            for x in sampleArea.xRange {
                let index = y * bytesPerRow + x * bytesPerPixel
                let red = 255 - pixels[index]
                let green = 255 - pixels[index + 1]
                let blue = 255 - pixels[index + 2]

                histograms.red[Int(red)] += 1
                histograms.green[Int(green)] += 1
                histograms.blue[Int(blue)] += 1
                samplePixelCount += 1
            }
        }

        let redLevels = levels(for: histograms.red, pixelCount: samplePixelCount)
        let greenLevels = levels(for: histograms.green, pixelCount: samplePixelCount)
        let blueLevels = levels(for: histograms.blue, pixelCount: samplePixelCount)
        var neutralSample = ChannelAverages()

        for y in 0..<height {
            for x in 0..<width {
                let index = y * bytesPerRow + x * bytesPerPixel
                let red = normalize(255 - pixels[index], levels: redLevels)
                let green = normalize(255 - pixels[index + 1], levels: greenLevels)
                let blue = normalize(255 - pixels[index + 2], levels: blueLevels)

                pixels[index] = red
                pixels[index + 1] = green
                pixels[index + 2] = blue

                if sampleArea.xRange.contains(x), sampleArea.yRange.contains(y) {
                    neutralSample.addIfNeutral(
                        red: Double(red) / 255,
                        green: Double(green) / 255,
                        blue: Double(blue) / 255
                    )
                }
            }
        }

        let neutralFactors = neutralFactors(from: neutralSample)

        for index in stride(from: 0, to: pixels.count, by: bytesPerPixel) {
            let red = Double(pixels[index]) / 255 * neutralFactors.red
            let green = Double(pixels[index + 1]) / 255 * neutralFactors.green
            let blue = Double(pixels[index + 2]) / 255 * neutralFactors.blue
            let saturated = increaseSaturation(red: red, green: green, blue: blue, amount: 1.08)

            pixels[index] = toByte(toneMapped(saturated.red))
            pixels[index + 1] = toByte(toneMapped(saturated.green))
            pixels[index + 2] = toByte(toneMapped(saturated.blue))
        }

        guard let outputContext = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ),
              let outputImage = outputContext.makeImage() else {
            throw MaskRemovalError.renderFailed
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Film-Converter-MaskRemoval", isDirectory: true)
            .appendingPathComponent("\(frame.id.uuidString).png")

        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        guard let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw MaskRemovalError.writeFailed
        }

        CGImageDestinationAddImage(destination, outputImage, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw MaskRemovalError.writeFailed
        }

        return outputURL
    }

    nonisolated private static func downsampledImage(from url: URL, maxPixelSize: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]

        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    nonisolated private static func sampleArea(width: Int, height: Int) -> (xRange: Range<Int>, yRange: Range<Int>) {
        let inset = max(0, Int(Double(min(width, height)) * 0.045))
        let xStart = min(inset, max(width - 1, 0))
        let yStart = min(inset, max(height - 1, 0))
        let xEnd = max(xStart + 1, width - inset)
        let yEnd = max(yStart + 1, height - inset)
        return (xStart..<min(xEnd, width), yStart..<min(yEnd, height))
    }

    nonisolated private static func levels(for histogram: [Int], pixelCount: Int) -> ChannelLevels {
        let blackTarget = max(0, Int(Double(pixelCount) * 0.005))
        let whiteTarget = max(blackTarget + 1, Int(Double(pixelCount) * 0.99))

        var cumulative = 0
        var black = 0
        var white = 255

        for value in 0..<histogram.count {
            cumulative += histogram[value]
            if cumulative >= blackTarget {
                black = value
                break
            }
        }

        cumulative = 0

        for value in 0..<histogram.count {
            cumulative += histogram[value]
            if cumulative >= whiteTarget {
                white = value
                break
            }
        }

        if white <= black {
            white = min(255, black + 1)
        }

        return ChannelLevels(black: black, white: white)
    }

    nonisolated private static func normalize(_ value: UInt8, levels: ChannelLevels) -> UInt8 {
        let normalized = clamp(
            Double(Int(value) - levels.black) / Double(levels.white - levels.black) * 255,
            lowerBound: 0,
            upperBound: 255
        )
        return UInt8(normalized.rounded())
    }

    nonisolated private static func neutralFactors(from sample: ChannelAverages) -> RGBFactors {
        guard sample.count > 200 else {
            return RGBFactors(red: 1, green: 1, blue: 1)
        }

        let red = sample.red / Double(sample.count)
        let green = sample.green / Double(sample.count)
        let blue = sample.blue / Double(sample.count)
        let target = (red + green + blue) / 3

        return RGBFactors(
            red: clamp(target / max(red, 0.001), lowerBound: 0.72, upperBound: 1.38),
            green: clamp(target / max(green, 0.001), lowerBound: 0.72, upperBound: 1.38),
            blue: clamp(target / max(blue, 0.001), lowerBound: 0.72, upperBound: 1.38)
        )
    }

    nonisolated private static func increaseSaturation(
        red: Double,
        green: Double,
        blue: Double,
        amount: Double
    ) -> RGBFactors {
        let luma = 0.2126 * red + 0.7152 * green + 0.0722 * blue

        return RGBFactors(
            red: luma + (red - luma) * amount,
            green: luma + (green - luma) * amount,
            blue: luma + (blue - luma) * amount
        )
    }

    nonisolated private static func toneMapped(_ value: Double) -> Double {
        let clamped = clamp(value, lowerBound: 0, upperBound: 1)
        let gammaAdjusted = pow(clamped, 0.94)
        return clamp((gammaAdjusted - 0.5) * 1.045 + 0.5, lowerBound: 0, upperBound: 1)
    }

    nonisolated private static func toByte(_ value: Double) -> UInt8 {
        UInt8((clamp(value, lowerBound: 0, upperBound: 1) * 255).rounded())
    }

    nonisolated private static func clamp(_ value: Double, lowerBound: Double, upperBound: Double) -> Double {
        min(max(value, lowerBound), upperBound)
    }
}

private struct ChannelHistograms {
    var red = [Int](repeating: 0, count: 256)
    var green = [Int](repeating: 0, count: 256)
    var blue = [Int](repeating: 0, count: 256)

    nonisolated init() {
    }
}

private struct ChannelLevels {
    let black: Int
    let white: Int

    nonisolated init(black: Int, white: Int) {
        self.black = black
        self.white = white
    }
}

private struct ChannelAverages {
    var red = 0.0
    var green = 0.0
    var blue = 0.0
    var count = 0

    nonisolated init() {
    }

    nonisolated mutating func addIfNeutral(red: Double, green: Double, blue: Double) {
        let maxChannel = max(red, max(green, blue))
        let minChannel = min(red, min(green, blue))
        let luma = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        let saturation = maxChannel > 0 ? (maxChannel - minChannel) / maxChannel : 0

        guard luma > 0.14, luma < 0.86, saturation < 0.58 else {
            return
        }

        self.red += red
        self.green += green
        self.blue += blue
        count += 1
    }
}

private struct RGBFactors {
    let red: Double
    let green: Double
    let blue: Double

    nonisolated init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

enum MaskRemovalError: LocalizedError {
    case missingSourceImage
    case unreadableSourceImage
    case renderFailed
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .missingSourceImage:
            "这张照片没有可处理的源文件。"
        case .unreadableSourceImage:
            "无法读取这张照片。"
        case .renderFailed:
            "去色罩渲染失败。"
        case .writeFailed:
            "无法写入处理后的照片。"
        }
    }
}
