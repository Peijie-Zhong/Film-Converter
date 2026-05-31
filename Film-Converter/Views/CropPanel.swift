//
//  CropPanel.swift
//  Film-Converter
//

import SwiftUI

struct CropPanel: View {
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
                Text("裁切")
                    .font(.system(size: 18, weight: .semibold))
                Text("调整照片比例、裁切范围和画面位置")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("比例")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: gridColumns, spacing: 8) {
                    ForEach(CropAspectRatio.allCases) { ratio in
                        Button {
                            withAnimation(.snappy(duration: 0.16)) {
                                crop.setAspectRatio(ratio, in: canvasAspectRatio)
                            }
                        } label: {
                            Text(ratio.title)
                                .font(.system(size: 13, weight: .medium))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 8)
                        .background {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(crop.aspectRatio == ratio ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                        }
                        .foregroundStyle(crop.aspectRatio == ratio ? .white : .primary)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("变换")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: gridColumns, spacing: 8) {
                    CropActionButton(
                        title: "左右镜像",
                        systemName: "arrow.left.and.right",
                        isActive: crop.isFlippedHorizontally
                    ) {
                        crop.isFlippedHorizontally.toggle()
                    }

                    CropActionButton(
                        title: "上下镜像",
                        systemName: "arrow.up.and.down",
                        isActive: crop.isFlippedVertically
                    ) {
                        crop.isFlippedVertically.toggle()
                    }

                    CropActionButton(
                        title: "逆时针 90",
                        systemName: "rotate.left",
                        isActive: false
                    ) {
                        crop.rotateCounterclockwise(imageAspectRatio: imageAspectRatio)
                    }

                    CropActionButton(
                        title: "顺时针 90",
                        systemName: "rotate.right",
                        isActive: false
                    ) {
                        crop.rotateClockwise(imageAspectRatio: imageAspectRatio)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("回车确认裁切")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("拖动照片上的白色框选择保留范围，框外灰色区域会被裁掉。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                withAnimation(.snappy(duration: 0.18)) {
                    crop = CropSettings()
                }
            } label: {
                Label("重置裁切", systemImage: "arrow.counterclockwise")
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
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 7)
                .fill(isActive ? Color.accentColor.opacity(0.16) : Color(nsColor: .controlBackgroundColor))
        }
        .foregroundStyle(isActive ? Color.accentColor : .primary)
    }
}
