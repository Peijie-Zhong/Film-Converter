//
//  SinglePhotoView.swift
//  Film-Converter
//

import SwiftUI

struct SinglePhotoView: View {
    @Environment(\.appLanguage) private var language
    let roll: FilmRoll
    @Binding var frame: FilmFrame
    let transitionNamespace: Namespace.ID
    @Binding var activeTool: ToolPanel?
    let onClose: () -> Void

    @State private var zoomScale = 1.0

    private var isCropping: Bool {
        activeTool == .crop
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(.borderless)
                .help(language.text("backHome"))

                VStack(alignment: .leading, spacing: 2) {
                    Text(frame.title)
                        .font(.system(size: 20, weight: .semibold))
                    Text("\(roll.name) · \(frame.exposure)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(.bar)

            ZStack {
                Color(nsColor: .textBackgroundColor).opacity(0.55)

                GeometryReader { proxy in
                    let canvasAspectRatio = frame.editSettings.crop.canvasAspectRatio(for: frame.imageAspectRatio)
                    let outputAspectRatio = isCropping
                        ? canvasAspectRatio
                        : frame.editSettings.crop.outputAspectRatio(in: canvasAspectRatio)
                    let footerHeight = 38.0
                    let viewportSize = CGSize(
                        width: max(280, proxy.size.width - 76),
                        height: max(240, proxy.size.height - footerHeight - 36)
                    )
                    let photoSize = fittedPhotoSize(in: viewportSize, aspectRatio: outputAspectRatio)

                    VStack(spacing: 12) {
                        ZStack {
                            FrameArtwork(
                                frame: frame,
                                appliesCrop: !isCropping,
                                appliesTransform: true,
                                cornerRadius: 0
                            )
                                .aspectRatio(outputAspectRatio, contentMode: .fill)
                                .frame(width: photoSize.width, height: photoSize.height)
                                .matchedGeometryEffect(id: frame.id, in: transitionNamespace)
                                .scaleEffect(zoomScale)
                                .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
                                .animation(.snappy(duration: 0.24), value: frame.editSettings.crop.rotationDegrees)
                                .animation(.snappy(duration: 0.18), value: frame.editSettings.crop.isFlippedHorizontally)
                                .animation(.snappy(duration: 0.18), value: frame.editSettings.crop.isFlippedVertically)

                            ZoomInputView(
                                onScroll: { deltaY in
                                    zoom(by: exp(deltaY * 0.003))
                                },
                                onMagnify: { magnification in
                                    zoom(by: max(0.1, 1 + magnification))
                                },
                                onDoubleClick: onClose,
                                onConfirm: confirmCrop
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                            if isCropping {
                                CropOverlay(crop: $frame.editSettings.crop)
                                    .frame(width: photoSize.width, height: photoSize.height)
                                    .scaleEffect(zoomScale)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 240, maxHeight: .infinity)
                        .clipped()

                        Text("Frame \(String(format: "%02d", frame.number)) · \(Int(zoomScale * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(height: 18)
                    }
                    .padding(.vertical, 12)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func zoom(by factor: Double) {
        let nextScale = (zoomScale * factor).clamped(to: 0.25...4.0)
        zoomScale = nextScale
    }

    private func confirmCrop() {
        guard isCropping else {
            return
        }

        withAnimation(.snappy(duration: 0.18)) {
            activeTool = nil
        }
    }

    private func fittedPhotoSize(in availableSize: CGSize, aspectRatio: CGFloat) -> CGSize {
        let widthFromHeight = availableSize.height * aspectRatio

        if widthFromHeight <= availableSize.width {
            return CGSize(width: widthFromHeight, height: availableSize.height)
        }

        return CGSize(width: availableSize.width, height: availableSize.width / aspectRatio)
    }
}
