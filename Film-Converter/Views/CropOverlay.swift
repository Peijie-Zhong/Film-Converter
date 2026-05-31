//
//  CropOverlay.swift
//  Film-Converter
//

import SwiftUI

struct CropOverlay: View {
    @Binding var crop: CropSettings

    @State private var dragStartSelection: NormalizedCropRect?
    @State private var resizeStartSelection: NormalizedCropRect?

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let cropRect = displayRect(for: crop.selection, in: size)

            ZStack {
                cropShade(cropRect: cropRect, in: size)

                cropGrid(in: cropRect)

                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(.white, lineWidth: 2)
                    .frame(width: cropRect.width, height: cropRect.height)
                    .position(x: cropRect.midX, y: cropRect.midY)
                    .contentShape(Rectangle())
                    .gesture(moveGesture(in: size))

                ForEach(CropHandle.allCases) { handle in
                    CropHandleView()
                        .position(handle.point(in: cropRect))
                        .gesture(resizeGesture(handle: handle, in: size))
                }
            }
            .frame(width: size.width, height: size.height)
        }
    }

    private func cropShade(cropRect: CGRect, in size: CGSize) -> some View {
        Path { path in
            path.addRect(CGRect(origin: .zero, size: size))
            path.addRoundedRect(in: cropRect, cornerSize: CGSize(width: 3, height: 3))
        }
        .fill(.black.opacity(0.45), style: FillStyle(eoFill: true))
    }

    private func cropGrid(in rect: CGRect) -> some View {
        Path { path in
            let verticalStep = rect.width / 3
            let horizontalStep = rect.height / 3

            for index in 1...2 {
                let x = rect.minX + CGFloat(index) * verticalStep
                path.move(to: CGPoint(x: x, y: rect.minY))
                path.addLine(to: CGPoint(x: x, y: rect.maxY))

                let y = rect.minY + CGFloat(index) * horizontalStep
                path.move(to: CGPoint(x: rect.minX, y: y))
                path.addLine(to: CGPoint(x: rect.maxX, y: y))
            }
        }
        .stroke(.white.opacity(0.72), lineWidth: 1)
    }

    private func moveGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let start = dragStartSelection ?? crop.selection
                dragStartSelection = start

                let nextX = (start.x + Double(value.translation.width / size.width)).clamped(to: 0...(1 - start.width))
                let nextY = (start.y + Double(value.translation.height / size.height)).clamped(to: 0...(1 - start.height))
                crop.selection = NormalizedCropRect(x: nextX, y: nextY, width: start.width, height: start.height)
            }
            .onEnded { _ in
                dragStartSelection = nil
            }
    }

    private func resizeGesture(handle: CropHandle, in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let start = resizeStartSelection ?? crop.selection
                resizeStartSelection = start
                crop.selection = resizedSelection(from: start, handle: handle, translation: value.translation, in: size)
            }
            .onEnded { _ in
                resizeStartSelection = nil
            }
    }

    private func resizedSelection(
        from start: NormalizedCropRect,
        handle: CropHandle,
        translation: CGSize,
        in size: CGSize
    ) -> NormalizedCropRect {
        let minSize = 0.12
        let dx = Double(translation.width / size.width)
        let dy = Double(translation.height / size.height)
        let canvasAspectRatio = size.width / size.height
        let fixedAspectRatio = Double(crop.targetAspectRatio(in: canvasAspectRatio))
        let normalizedHeightForWidth = Double(size.width / size.height) / fixedAspectRatio
        let normalizedWidthForHeight = Double(size.height / size.width) * fixedAspectRatio

        var x = start.x
        var y = start.y
        var width = start.width
        var height = start.height
        let usesVerticalDrag = abs(dy) > abs(dx)

        switch handle {
        case .topLeft:
            if usesVerticalDrag {
                height = (start.height - dy).clamped(to: minSize...start.y + start.height)
                width = height * normalizedWidthForHeight
            } else {
                width = (start.width - dx).clamped(to: minSize...start.x + start.width)
                height = width * normalizedHeightForWidth
            }
            if height > start.y + start.height {
                height = start.y + start.height
                width = height * normalizedWidthForHeight
            }
            x = start.x + start.width - width
            y = start.y + start.height - height
        case .topRight:
            if usesVerticalDrag {
                height = (start.height - dy).clamped(to: minSize...start.y + start.height)
                width = height * normalizedWidthForHeight
            } else {
                width = (start.width + dx).clamped(to: minSize...(1 - start.x))
                height = width * normalizedHeightForWidth
            }
            if height > start.y + start.height {
                height = start.y + start.height
                width = height * normalizedWidthForHeight
            }
            y = start.y + start.height - height
        case .bottomLeft:
            if usesVerticalDrag {
                height = (start.height + dy).clamped(to: minSize...(1 - start.y))
                width = height * normalizedWidthForHeight
            } else {
                width = (start.width - dx).clamped(to: minSize...start.x + start.width)
                height = width * normalizedHeightForWidth
            }
            if height > 1 - start.y {
                height = 1 - start.y
                width = height * normalizedWidthForHeight
            }
            x = start.x + start.width - width
        case .bottomRight:
            if usesVerticalDrag {
                height = (start.height + dy).clamped(to: minSize...(1 - start.y))
                width = height * normalizedWidthForHeight
            } else {
                width = (start.width + dx).clamped(to: minSize...(1 - start.x))
                height = width * normalizedHeightForWidth
            }
            if height > 1 - start.y {
                height = 1 - start.y
                width = height * normalizedWidthForHeight
            }
        }

        return NormalizedCropRect(
            x: x.clamped(to: 0...(1 - width)),
            y: y.clamped(to: 0...(1 - height)),
            width: width.clamped(to: minSize...1),
            height: height.clamped(to: minSize...1)
        )
    }

    private func displayRect(for selection: NormalizedCropRect, in size: CGSize) -> CGRect {
        CGRect(
            x: CGFloat(selection.x) * size.width,
            y: CGFloat(selection.y) * size.height,
            width: CGFloat(selection.width) * size.width,
            height: CGFloat(selection.height) * size.height
        )
    }
}

private enum CropHandle: CaseIterable, Identifiable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    var id: Self { self }

    func point(in rect: CGRect) -> CGPoint {
        switch self {
        case .topLeft:
            CGPoint(x: rect.minX, y: rect.minY)
        case .topRight:
            CGPoint(x: rect.maxX, y: rect.minY)
        case .bottomLeft:
            CGPoint(x: rect.minX, y: rect.maxY)
        case .bottomRight:
            CGPoint(x: rect.maxX, y: rect.maxY)
        }
    }
}

private struct CropHandleView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(.white)
            .frame(width: 14, height: 14)
            .shadow(color: .black.opacity(0.28), radius: 4, y: 1)
    }
}
