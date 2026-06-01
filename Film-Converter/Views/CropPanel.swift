//
//  CropPanel.swift
//  Film-Converter
//

import SwiftUI

struct CropPanel: View {
    @Environment(\.appLanguage) private var language
    @Binding var crop: CropSettings
    let imageAspectRatio: CGFloat

    private let gridColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    private var canvasAspectRatio: CGFloat {
        crop.canvasAspectRatio(for: imageAspectRatio)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text(language.text("crop"))
                    .font(.system(size: 18, weight: .semibold))
                Text(language.text("cropSubtitle"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(language.text("ratio"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: gridColumns, spacing: 8) {
                    ForEach(CropAspectRatio.allCases) { ratio in
                        Button {
                            withAnimation(.snappy(duration: 0.16)) {
                                crop.setAspectRatio(ratio, in: canvasAspectRatio)
                            }
                        } label: {
                            Text(ratio.title(language: language))
                                .font(.system(size: 13, weight: .medium))
                                .frame(maxWidth: .infinity, minHeight: 34)
                                .background {
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(crop.aspectRatio == ratio ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                                }
                                .contentShape(RoundedRectangle(cornerRadius: 7))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(crop.aspectRatio == ratio ? .white : .primary)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(language.text("transform"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: gridColumns, spacing: 8) {
                    CropActionButton(
                        title: language.text("flipHorizontal"),
                        systemName: "arrow.left.and.right",
                        isActive: crop.isFlippedHorizontally
                    ) {
                        withAnimation(.snappy(duration: 0.18)) {
                            crop.isFlippedHorizontally.toggle()
                        }
                    }

                    CropActionButton(
                        title: language.text("flipVertical"),
                        systemName: "arrow.up.and.down",
                        isActive: crop.isFlippedVertically
                    ) {
                        withAnimation(.snappy(duration: 0.18)) {
                            crop.isFlippedVertically.toggle()
                        }
                    }

                    CropActionButton(
                        title: language.text("rotateLeft90"),
                        systemName: "rotate.left",
                        isActive: false
                    ) {
                        withAnimation(.snappy(duration: 0.24)) {
                            crop.rotateCounterclockwise()
                        }
                    }

                    CropActionButton(
                        title: language.text("rotateRight90"),
                        systemName: "rotate.right",
                        isActive: false
                    ) {
                        withAnimation(.snappy(duration: 0.24)) {
                            crop.rotateClockwise()
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(language.text("confirmCrop"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(language.text("cropHint"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                withAnimation(.snappy(duration: 0.18)) {
                    crop = CropSettings()
                }
            } label: {
                Label(language.text("resetCrop"), systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding(18)
        .frame(width: 268)
    }
}

private struct CropActionButton: View {
    let title: String
    let systemName: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 54)
            .background {
                RoundedRectangle(cornerRadius: 7)
                    .fill(isActive ? Color.accentColor.opacity(0.16) : Color(nsColor: .controlBackgroundColor))
            }
            .contentShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .foregroundStyle(isActive ? Color.accentColor : .primary)
    }
}
