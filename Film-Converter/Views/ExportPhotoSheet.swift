//
//  ExportPhotoSheet.swift
//  Film-Converter
//

import AppKit
import SwiftUI

struct ExportPhotoSheet: View {
    let frame: FilmFrame
    let roll: FilmRoll

    @Environment(\.appLanguage) private var language
    @Environment(\.dismiss) private var dismiss
    @State private var settings = ExportPhotoSettings()
    @State private var exportError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(language.text("exportPhoto"))
                    .font(.system(size: 22, weight: .semibold))
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
                .help(language.text("close"))
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)
            .padding(.bottom, 16)

            Divider()

            HStack(spacing: 0) {
                ExportSettingsPane(
                    settings: $settings,
                    chooseDestination: chooseDestination
                )
                .frame(width: 340)

                Divider()

                ExportPreviewPane(
                    frame: frame,
                    roll: roll,
                    settings: settings
                )
            }

            Divider()

            HStack {
                Spacer()
                Button(language.text("cancel")) {
                    dismiss()
                }
                Button(language.text("export")) {
                    exportPhoto()
                }
                .buttonStyle(.borderedProminent)
                .disabled(settings.fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || settings.destinationURL == nil)
            }
            .padding(18)
        }
        .frame(width: 980, height: 650)
        .onAppear {
            settings.fileName = frame.title
        }
        .alert(language.text("exportFailed"), isPresented: exportErrorBinding) {
            Button(language.text("ok"), role: .cancel) {
                exportError = nil
            }
        } message: {
            Text(exportError ?? "")
        }
    }

    private func chooseDestination() {
        let panel = NSOpenPanel()
        panel.title = language.text("chooseExportLocation")
        panel.prompt = language.text("choose")
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK else {
            return
        }

        settings.destinationURL = panel.url
    }

    private var exportErrorBinding: Binding<Bool> {
        Binding(
            get: { exportError != nil },
            set: { isPresented in
                if !isPresented {
                    exportError = nil
                }
            }
        )
    }

    @MainActor
    private func exportPhoto() {
        guard let destinationURL = settings.destinationURL else {
            return
        }

        let renderSize = exportRenderSize(
            frame: frame,
            roll: roll,
            includesFilmBorder: settings.includesFilmBorder,
            includesPhotoInfoFrame: settings.includesPhotoInfoFrame
        )
        let renderedView = ExportPreviewArtwork(
            frame: frame,
            roll: roll,
            includesFilmBorder: settings.includesFilmBorder,
            includesPhotoInfoFrame: settings.includesPhotoInfoFrame
        )
        .frame(width: renderSize.width, height: renderSize.height)
        .background(Color.clear)

        let renderer = ImageRenderer(content: renderedView)
        renderer.proposedSize = ProposedViewSize(renderSize)
        renderer.scale = 1

        guard let image = renderer.nsImage,
              let data = image.encodedData(format: settings.format, quality: settings.quality) else {
            exportError = language.text("renderExportFailed")
            return
        }

        do {
            let outputURL = destinationURL
                .appending(path: sanitizedFileName(settings.fileName))
                .appendingPathExtension(settings.format.fileExtension)
            try data.write(to: outputURL, options: .atomic)
            dismiss()
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func sanitizedFileName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let components = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: invalidCharacters)
        let sanitized = components.joined(separator: "-")
        return sanitized.isEmpty ? frame.title : sanitized
    }
}

private struct ExportSettingsPane: View {
    @Environment(\.appLanguage) private var language
    @Binding var settings: ExportPhotoSettings
    let chooseDestination: () -> Void

    var body: some View {
        ScrollView {
            Form {
                Section(language.text("file")) {
                    TextField(language.text("fileName"), text: $settings.fileName)

                    Picker(language.text("format"), selection: $settings.format) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.title).tag(format)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(settings.destinationURL?.path(percentEncoded: false) ?? language.text("noExportLocation"))
                            .font(.caption)
                            .lineLimit(2)
                            .truncationMode(.middle)
                            .foregroundStyle(settings.destinationURL == nil ? .secondary : .primary)

                        Button(language.text("chooseLocation"), action: chooseDestination)
                    }
                }

                Section(language.text("image")) {
                    Toggle(language.text("includeEdits"), isOn: $settings.includesEdits)
                    Toggle(language.text("addFilmBorder"), isOn: $settings.includesFilmBorder)
                    Toggle(language.text("addPhotoInfo"), isOn: $settings.includesPhotoInfoFrame)

                    if settings.format == .jpeg {
                        Slider(value: $settings.quality, in: 0.55...1.0, step: 0.05) {
                            Text(language.text("quality"))
                        } minimumValueLabel: {
                            Text("55")
                                .font(.caption)
                        } maximumValueLabel: {
                            Text("100")
                                .font(.caption)
                        }
                        Text(String(format: language.text("jpegQualityFormat"), Int(settings.quality * 100)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .padding(.vertical, 10)
        }
    }
}

private struct ExportPreviewPane: View {
    @Environment(\.appLanguage) private var language
    let frame: FilmFrame
    let roll: FilmRoll
    let settings: ExportPhotoSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.text("preview"))
                        .font(.system(size: 16, weight: .semibold))
                    Text(settings.includesFilmBorder ? String(format: language.text("filmBaseStyleFormat"), roll.format) : language.text("photoOnly"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            ZStack {
                Color(nsColor: .textBackgroundColor)

                ExportPreviewArtwork(
                    frame: frame,
                    roll: roll,
                    includesFilmBorder: settings.includesFilmBorder,
                    includesPhotoInfoFrame: settings.includesPhotoInfoFrame
                )
                .padding(34)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(.quaternary, lineWidth: 1)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct ExportPreviewArtwork: View {
    let frame: FilmFrame
    let roll: FilmRoll
    let includesFilmBorder: Bool
    let includesPhotoInfoFrame: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                if includesPhotoInfoFrame {
                    PhotoInfoExportFrame(
                        frame: frame,
                        roll: roll,
                        includesFilmBorder: includesFilmBorder
                    )
                } else {
                    ExportArtworkCore(
                        frame: frame,
                        roll: roll,
                        includesFilmBorder: includesFilmBorder
                    )
                }
            }
            .frame(width: size.width, height: size.height)
        }
    }
}

private struct ExportArtworkCore: View {
    let frame: FilmFrame
    let roll: FilmRoll
    let includesFilmBorder: Bool

    var body: some View {
        if includesFilmBorder {
            if roll.usesMediumFormatBorder {
                MediumFormatBorder(frame: frame, roll: roll)
            } else {
                ThirtyFiveMillimeterBorder(frame: frame, roll: roll)
            }
        } else {
            FrameArtwork(frame: frame, cornerRadius: 0)
                .aspectRatio(outputAspectRatio, contentMode: .fit)
        }
    }

    private var outputAspectRatio: CGFloat {
        editedOutputAspectRatio(for: frame)
    }
}

private struct PhotoInfoExportFrame: View {
    let frame: FilmFrame
    let roll: FilmRoll
    let includesFilmBorder: Bool

    var body: some View {
        GeometryReader { proxy in
            let sidePadding = min(max(proxy.size.width * 0.018, 10), 56)
            let topPadding = min(max(proxy.size.height * 0.018, 10), 56)

            VStack(spacing: 0) {
                ExportArtworkCore(
                    frame: frame,
                    roll: roll,
                    includesFilmBorder: includesFilmBorder
                )
                .aspectRatio(artworkAspectRatio, contentMode: .fit)
                .frame(
                    maxWidth: proxy.size.width - sidePadding * 2,
                    maxHeight: proxy.size.height * 0.8
                )
                .padding(.horizontal, sidePadding)
                .padding(.top, topPadding)

                VStack(alignment: .center, spacing: 8) {
                    Text(cameraTitle)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    Text(photoInfoLine)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.black.opacity(0.66))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 12)
                .padding(.horizontal, sidePadding)
                .padding(.bottom, max(topPadding, 14))
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background(Color.white)
        }
        .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
    }

    private var artworkAspectRatio: CGFloat {
        exportArtworkAspectRatio(
            frame: frame,
            roll: roll,
            includesFilmBorder: includesFilmBorder
        )
    }

    private var cameraTitle: String {
        roll.cameraModel?.isEmpty == false ? roll.cameraModel ?? "Camera" : "Camera"
    }

    private var photoInfoLine: String {
        [
            frame.captureInfo.iso.isEmpty ? nil : "ISO \(frame.captureInfo.iso)",
            frame.captureInfo.aperture.isEmpty ? nil : frame.captureInfo.aperture,
            frame.captureInfo.shutterSpeed.isEmpty ? nil : frame.captureInfo.shutterSpeed,
            frame.captureInfo.exposureCompensation.isEmpty ? nil : frame.captureInfo.exposureCompensation,
            frame.captureInfo.focalLength.isEmpty ? nil : frame.captureInfo.focalLength,
            frame.captureInfo.capturedAt.isEmpty ? nil : frame.captureInfo.capturedAt,
            frame.captureInfo.location.isEmpty ? nil : frame.captureInfo.location
        ]
        .compactMap(\.self)
        .joined(separator: " · ")
    }
}

private struct MediumFormatBorder: View {
    let frame: FilmFrame
    let roll: FilmRoll

    var body: some View {
        GeometryReader { proxy in
            let horizontalRail = proxy.size.height * 0.055
            let sideInset = proxy.size.width * 0.035

            ZStack {
                Rectangle()
                    .fill(.black)

                FrameArtwork(frame: frame, cornerRadius: 0)
                    .aspectRatio(frame.editSettings.crop.outputAspectRatio(in: frame.editSettings.crop.canvasAspectRatio(for: frame.imageAspectRatio)), contentMode: .fill)
                    .frame(
                        width: proxy.size.width - sideInset * 2,
                        height: proxy.size.height - horizontalRail * 2
                    )
                    .clipShape(Rectangle())
                    .overlay {
                        Rectangle()
                            .stroke(.black.opacity(0.72), lineWidth: 2)
                    }

                VStack(spacing: 0) {
                    MediumFormatEdgeText(
                        stock: roll.stock,
                        frameNumber: frame.number,
                        content: .stock,
                        alignment: .leading
                    )
                    .frame(height: horizontalRail)

                    Spacer()

                    MediumFormatEdgeText(
                        stock: roll.stock,
                        frameNumber: frame.number,
                        content: .frameNumber,
                        alignment: .trailing
                    )
                    .frame(height: horizontalRail)
                }
                .padding(.horizontal, sideInset * 0.45)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct MediumFormatEdgeText: View {
    enum ContentKind {
        case stock
        case frameNumber
    }

    enum Alignment {
        case leading
        case trailing
    }

    let stock: String
    let frameNumber: Int
    let content: ContentKind
    let alignment: Alignment

    var body: some View {
        HStack(spacing: 8) {
            if alignment == .trailing {
                Spacer()
            }

            if content == .stock {
                Text(stock.uppercased())
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(1.25)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } else {
                Text("▶")
                    .font(.system(size: 6, weight: .bold))

                Text(String(format: "%02d", frameNumber))
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(1.0)
            }

            if alignment == .leading {
                Spacer()
            }
        }
        .foregroundStyle(.warmFilmText)
        .opacity(0.92)
        .padding(.horizontal, 18)
    }
}

private struct ThirtyFiveMillimeterBorder: View {
    let frame: FilmFrame
    let roll: FilmRoll

    var body: some View {
        if outputAspectRatio >= 1 {
            LandscapeThirtyFiveMillimeterBorder(frame: frame, roll: roll, outputAspectRatio: outputAspectRatio)
        } else {
            PortraitThirtyFiveMillimeterBorder(frame: frame, roll: roll, outputAspectRatio: outputAspectRatio)
        }
    }

    private var outputAspectRatio: CGFloat {
        editedOutputAspectRatio(for: frame)
    }
}

private struct PortraitThirtyFiveMillimeterBorder: View {
    let frame: FilmFrame
    let roll: FilmRoll
    let outputAspectRatio: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let stripWidth = proxy.size.width * 0.135
            let imageWidth = proxy.size.width - stripWidth * 2

            HStack(spacing: 0) {
                SprocketStrip(
                    stock: roll.stock,
                    frameNumber: frame.number,
                    orientation: .vertical,
                    content: .stock
                )
                .frame(width: stripWidth)

                FrameArtwork(frame: frame, cornerRadius: 0)
                    .aspectRatio(outputAspectRatio, contentMode: .fill)
                    .frame(width: imageWidth, height: proxy.size.height)
                    .clipShape(Rectangle())

                SprocketStrip(
                    stock: roll.stock,
                    frameNumber: frame.number,
                    orientation: .vertical,
                    content: .frameNumber
                )
                .frame(width: stripWidth)
            }
            .background(Color.black)
            .clipShape(Rectangle())
        }
        .aspectRatio(outputAspectRatio / 0.73, contentMode: .fit)
    }
}

private struct LandscapeThirtyFiveMillimeterBorder: View {
    let frame: FilmFrame
    let roll: FilmRoll
    let outputAspectRatio: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let stripHeight = proxy.size.height * 0.135
            let imageHeight = proxy.size.height - stripHeight * 2

            VStack(spacing: 0) {
                SprocketStrip(
                    stock: roll.stock,
                    frameNumber: frame.number,
                    orientation: .horizontal,
                    content: .stock
                )
                .frame(height: stripHeight)

                FrameArtwork(frame: frame, cornerRadius: 0)
                    .aspectRatio(outputAspectRatio, contentMode: .fill)
                    .frame(width: proxy.size.width, height: imageHeight)
                    .clipShape(Rectangle())

                SprocketStrip(
                    stock: roll.stock,
                    frameNumber: frame.number,
                    orientation: .horizontal,
                    content: .frameNumber
                )
                .frame(height: stripHeight)
            }
            .background(Color.black)
            .clipShape(Rectangle())
        }
        .aspectRatio(outputAspectRatio * 0.73, contentMode: .fit)
    }
}

private struct SprocketStrip: View {
    enum Orientation {
        case horizontal
        case vertical
    }

    enum ContentKind {
        case stock
        case frameNumber
    }

    enum Side {
        case leading
        case trailing
    }

    let stock: String
    let frameNumber: Int
    let orientation: Orientation
    let content: ContentKind

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black

                if orientation == .vertical {
                    let holeWidth = proxy.size.width * 0.5
                    let holeHeight = proxy.size.height * 0.055

                    VStack(spacing: proxy.size.height * 0.048) {
                        ForEach(0..<7, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.white.opacity(0.96))
                                .frame(width: holeWidth, height: holeHeight)
                        }
                    }
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height / 2)

                    Film35EdgeText(
                        stock: shortStockName(stock),
                        frameNumber: frameNumber,
                        content: content
                    )
                    .frame(width: proxy.size.height * 0.62, height: proxy.size.width * 0.3)
                    .rotationEffect(.degrees(-90))
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height / 2)
                } else {
                    let holeWidth = proxy.size.width * 0.055
                    let holeHeight = proxy.size.height * 0.5

                    HStack(spacing: proxy.size.width * 0.048) {
                        ForEach(0..<7, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.white.opacity(0.96))
                                .frame(width: holeWidth, height: holeHeight)
                        }
                    }
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.5)

                    Film35EdgeText(
                        stock: shortStockName(stock),
                        frameNumber: frameNumber,
                        content: content
                    )
                    .frame(width: proxy.size.width * 0.5, height: proxy.size.height * 0.3)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.5)
                }
            }
        }
    }

    private func shortStockName(_ stock: String) -> String {
        stock
            .replacingOccurrences(of: "Fujifilm", with: "FUJI")
            .replacingOccurrences(of: "Kodak", with: "KODAK")
            .uppercased()
    }
}

private struct Film35EdgeText: View {
    let stock: String
    let frameNumber: Int
    let content: SprocketStrip.ContentKind

    var body: some View {
        HStack(spacing: 12) {
            if content == .stock {
                Text(stock)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(1.1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
            } else {
                Text("▶")
                    .font(.system(size: 7, weight: .bold))
                Text(String(format: "%02d", frameNumber))
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(0.8)
            }
        }
        .foregroundStyle(.yellowFilmText)
        .opacity(0.94)
    }
}

private struct ExportPhotoSettings {
    var fileName = ""
    var format = ExportFormat.jpeg
    var destinationURL: URL?
    var includesEdits = true
    var includesFilmBorder = false
    var includesPhotoInfoFrame = false
    var quality = 0.9
}

private enum ExportFormat: String, CaseIterable, Identifiable {
    case jpeg
    case png
    case tiff

    var id: String { rawValue }

    var title: String {
        switch self {
        case .jpeg:
            "JPEG"
        case .png:
            "PNG"
        case .tiff:
            "TIFF"
        }
    }

    var fileExtension: String {
        rawValue
    }
}

private func editedOutputAspectRatio(for frame: FilmFrame) -> CGFloat {
    frame.editSettings.crop.outputAspectRatio(
        in: frame.editSettings.crop.canvasAspectRatio(for: frame.imageAspectRatio)
    )
}

private func exportArtworkAspectRatio(frame: FilmFrame, roll: FilmRoll, includesFilmBorder: Bool) -> CGFloat {
    let outputAspectRatio = editedOutputAspectRatio(for: frame)
    guard includesFilmBorder else {
        return outputAspectRatio
    }

    if roll.usesMediumFormatBorder {
        return 1
    }

    return outputAspectRatio >= 1 ? outputAspectRatio * 0.73 : outputAspectRatio / 0.73
}

private func exportRenderSize(
    frame: FilmFrame,
    roll: FilmRoll,
    includesFilmBorder: Bool,
    includesPhotoInfoFrame: Bool
) -> CGSize {
    var aspectRatio = exportArtworkAspectRatio(
        frame: frame,
        roll: roll,
        includesFilmBorder: includesFilmBorder
    )
    if includesPhotoInfoFrame {
        aspectRatio *= 0.82
    }

    let longEdge: CGFloat = 3200
    if aspectRatio >= 1 {
        return CGSize(width: longEdge, height: longEdge / aspectRatio)
    } else {
        return CGSize(width: longEdge * aspectRatio, height: longEdge)
    }
}

private extension NSImage {
    func encodedData(format: ExportFormat, quality: Double) -> Data? {
        guard let tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }

        switch format {
        case .jpeg:
            return bitmap.representation(
                using: .jpeg,
                properties: [.compressionFactor: quality]
            )
        case .png:
            return bitmap.representation(using: .png, properties: [:])
        case .tiff:
            return tiffRepresentation
        }
    }
}

private extension ShapeStyle where Self == Color {
    static var warmFilmText: Color {
        Color(red: 1.0, green: 0.75, blue: 0.58)
    }

    static var yellowFilmText: Color {
        Color(red: 1.0, green: 0.72, blue: 0.12)
    }
}
