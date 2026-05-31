//
//  FilmFrame.swift
//  Film-Converter
//

import AppKit
import SwiftUI

struct FilmFrame: Identifiable, Hashable {
    let id = UUID()
    var number: Int
    var title: String
    var exposure: String
    var palette: [Color]
    var imageURL: URL?
    var captureInfo = PhotoCaptureInfo()
    var editSettings = PhotoEditSettings()

    var displayImageURL: URL? {
        editSettings.maskRemoval.processedImageURL ?? imageURL
    }

    var imageAspectRatio: CGFloat {
        guard let displayImageURL,
              let image = ImageCache.image(for: displayImageURL),
              image.size.height > 0 else {
            return 3 / 2
        }

        return image.size.width / image.size.height
    }
}

struct PhotoCaptureInfo: Hashable {
    var iso = ""
    var aperture = ""
    var shutterSpeed = ""
    var capturedAt = ""
    var location = ""
    var notes = ""
}

struct PhotoEditSettings: Hashable {
    var isInverted = false
    var crop = CropSettings()
    var maskRemoval = MaskRemovalSettings()
}

struct MaskRemovalSettings: Hashable {
    var processedImageURL: URL?
    var temperature = 0.0
    var tint = 0.0
    var exposure = 0.0
    var contrast = 0.0
    var highlights = 0.0
    var shadows = 0.0
    var whiteLevel = 0.0
    var blackLevel = 0.0
    var vibrance = 0.0
    var saturation = 0.0
    var lastError: String?

    var hasProcessedImage: Bool {
        processedImageURL != nil
    }

    var colorAdjustment: Color {
        let red = (1 + temperature / 170 + tint / 380).clamped(to: 0.55...1.6)
        let green = (1 - tint / 170).clamped(to: 0.55...1.6)
        let blue = (1 - temperature / 170 + tint / 380).clamped(to: 0.55...1.6)
        return Color(red: red, green: green, blue: blue)
    }

    var brightnessAdjustment: Double {
        let exposureLift = exposure / 220
        let shadowLift = shadows / 520
        let highlightTrim = -highlights / 780
        let whiteLift = whiteLevel / 760
        let blackTrim = -blackLevel / 620
        return (exposureLift + shadowLift + highlightTrim + whiteLift + blackTrim).clamped(to: -0.55...0.55)
    }

    var contrastAdjustment: Double {
        (1 + contrast / 115 + whiteLevel / 360 - blackLevel / 420).clamped(to: 0.35...2.25)
    }

    var saturationAdjustment: Double {
        (1 + saturation / 100 + vibrance / 180).clamped(to: 0...2.6)
    }
}

struct CropSettings: Hashable {
    var aspectRatio = CropAspectRatio.original
    var selection = NormalizedCropRect()
    var isFlippedHorizontally = false
    var isFlippedVertically = false
    var rotationDegrees = 0

    var isRotatedSideways: Bool {
        abs(rotationDegrees % 180) == 90
    }

    func canvasAspectRatio(for imageAspectRatio: CGFloat) -> CGFloat {
        isRotatedSideways ? 1 / imageAspectRatio : imageAspectRatio
    }

    func targetAspectRatio(in canvasAspectRatio: CGFloat) -> CGFloat {
        switch aspectRatio {
        case .original:
            canvasAspectRatio
        default:
            aspectRatio.value
        }
    }

    func outputAspectRatio(in canvasAspectRatio: CGFloat) -> CGFloat {
        let selectionAspectRatio = CGFloat(selection.width / selection.height) * canvasAspectRatio
        return max(selectionAspectRatio, 0.05)
    }

    mutating func setAspectRatio(_ ratio: CropAspectRatio, in canvasAspectRatio: CGFloat) {
        aspectRatio = ratio
        selection = selection.fitted(
            to: targetAspectRatio(in: canvasAspectRatio),
            inCanvasAspectRatio: canvasAspectRatio
        )
    }

    mutating func rotateClockwise(imageAspectRatio: CGFloat) {
        rotationDegrees = (rotationDegrees + 90) % 360
        refitSelectionAfterTransform(imageAspectRatio: imageAspectRatio)
    }

    mutating func rotateCounterclockwise(imageAspectRatio: CGFloat) {
        rotationDegrees = (rotationDegrees + 270) % 360
        refitSelectionAfterTransform(imageAspectRatio: imageAspectRatio)
    }

    mutating func refitSelectionAfterTransform(imageAspectRatio: CGFloat) {
        let canvasAspectRatio = canvasAspectRatio(for: imageAspectRatio)
        selection = selection.fitted(
            to: targetAspectRatio(in: canvasAspectRatio),
            inCanvasAspectRatio: canvasAspectRatio
        )
    }
}

struct NormalizedCropRect: Hashable {
    var x = 0.0
    var y = 0.0
    var width = 1.0
    var height = 1.0

    var rect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }

    func fitted(to targetAspectRatio: CGFloat, inCanvasAspectRatio canvasAspectRatio: CGFloat) -> NormalizedCropRect {
        let centerX = x + width / 2
        let centerY = y + height / 2
        var nextWidth = width
        var nextHeight = width * Double(canvasAspectRatio / targetAspectRatio)

        if nextHeight > height {
            nextHeight = height
            nextWidth = height * Double(targetAspectRatio / canvasAspectRatio)
        }

        nextWidth = min(nextWidth, 1)
        nextHeight = min(nextHeight, 1)

        return NormalizedCropRect(
            x: (centerX - nextWidth / 2).clamped(to: 0...(1 - nextWidth)),
            y: (centerY - nextHeight / 2).clamped(to: 0...(1 - nextHeight)),
            width: nextWidth,
            height: nextHeight
        )
    }
}

enum CropAspectRatio: String, CaseIterable, Identifiable {
    case original
    case square
    case ratio3x2
    case ratio4x3
    case ratio16x9
    case ratio6x7

    var id: String { rawValue }

    var title: String {
        switch self {
        case .original:
            "原始"
        case .square:
            "1:1"
        case .ratio3x2:
            "3:2"
        case .ratio4x3:
            "4:3"
        case .ratio16x9:
            "16:9"
        case .ratio6x7:
            "6:7"
        }
    }

    var value: CGFloat {
        switch self {
        case .original, .ratio3x2:
            3 / 2
        case .square:
            1
        case .ratio4x3:
            4 / 3
        case .ratio16x9:
            16 / 9
        case .ratio6x7:
            6 / 7
        }
    }
}

extension FilmFrame {
    static func makeSet(count: Int, prefix: String, colors: [Color]) -> [FilmFrame] {
        (1...count).map { index in
            FilmFrame(
                number: index,
                title: "\(prefix)-\(String(format: "%02d", index))",
                exposure: index.isMultiple(of: 3) ? "+0.7 EV" : "ISO 400 · f/2.8",
                palette: [
                    colors[index % colors.count],
                    colors[(index + 1) % colors.count],
                    colors[(index + 2) % colors.count]
                ],
                captureInfo: PhotoCaptureInfo(
                    iso: "400",
                    aperture: "f/2.8",
                    shutterSpeed: "1/125",
                    capturedAt: "",
                    location: "",
                    notes: ""
                )
            )
        }
    }

    static func imported(from urls: [URL], startingAt startNumber: Int) -> [FilmFrame] {
        urls.enumerated().map { offset, url in
            let number = startNumber + offset

            return FilmFrame(
                number: number,
                title: url.deletingPathExtension().lastPathComponent,
                exposure: "Imported",
                palette: [.gray, .black, .white],
                imageURL: url
            )
        }
    }
}
