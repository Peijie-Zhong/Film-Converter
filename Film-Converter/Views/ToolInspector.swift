//
//  ToolInspector.swift
//  Film-Converter
//

import SwiftUI

struct ToolInspector: View {
    @Environment(\.appLanguage) private var language
    @Binding var activeTool: ToolPanel?
    @Binding var frame: FilmFrame
    let roll: FilmRoll
    @State private var isShowingExportSettings = false

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 10) {
                ToolButton(
                    systemName: "square.and.arrow.up",
                    title: language.text("export"),
                    isActive: isShowingExportSettings
                ) {
                    isShowingExportSettings = true
                }

                Divider()
                    .padding(.vertical, 4)

                ToolButton(
                    systemName: "wand.and.stars.inverse",
                    title: language.text("maskRemoval"),
                    isActive: activeTool == .maskRemoval
                ) {
                    withAnimation(.snappy(duration: 0.22)) {
                        activeTool = activeTool == .maskRemoval ? nil : .maskRemoval
                    }
                }

                Divider()
                    .padding(.vertical, 4)

                ToolButton(
                    systemName: "circle.lefthalf.filled",
                    title: language.text("invert"),
                    isActive: frame.editSettings.isInverted
                ) {
                    withAnimation(.snappy(duration: 0.16)) {
                        frame.editSettings.isInverted.toggle()
                    }
                }

                ToolButton(
                    systemName: "crop",
                    title: language.text("crop"),
                    isActive: activeTool == .crop
                ) {
                    withAnimation(.snappy(duration: 0.22)) {
                        activeTool = activeTool == .crop ? nil : .crop
                    }
                }
                ToolButton(systemName: "slider.horizontal.3", title: language.text("colorAdjust"), isActive: false) {}
                    .disabled(true)

                Spacer()

                ToolButton(
                    systemName: "info.circle",
                    title: language.text("photoInfo"),
                    isActive: activeTool == .photoInfo
                ) {
                    withAnimation(.snappy(duration: 0.22)) {
                        activeTool = activeTool == .photoInfo ? nil : .photoInfo
                    }
                }
            }
            .padding(.vertical, 14)
            .frame(width: 62)
            .background(.regularMaterial)

            if let activeTool {
                Divider()

                switch activeTool {
                case .maskRemoval:
                    MaskRemovalPanel(frame: $frame)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                case .crop:
                    CropPanel(
                        crop: $frame.editSettings.crop,
                        imageAspectRatio: frame.imageAspectRatio
                    )
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                case .photoInfo:
                    PhotoInfoPanel(frame: $frame)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .frame(width: activeTool == nil ? 62 : 330)
        .animation(.snappy(duration: 0.22), value: activeTool)
        .background(.regularMaterial)
        .sheet(isPresented: $isShowingExportSettings) {
            ExportPhotoSheet(frame: frame, roll: roll)
        }
    }
}

private struct ToolButton: View {
    let systemName: String
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(isActive ? .white : .primary)
                .frame(width: 38, height: 38)
                .background {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isActive ? Color.accentColor : Color.clear)
                }
        }
        .buttonStyle(.plain)
        .help(title)
    }
}
