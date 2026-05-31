//
//  PhotoBrowser.swift
//  Film-Converter
//

import SwiftUI

struct PhotoBrowser: View {
    let roll: FilmRoll
    @Binding var selectedFrameID: FilmFrame.ID?
    let onImportPhotos: () -> Void
    let onDeleteFrame: (FilmFrame) -> Void
    let onOpenFrame: (FilmFrame) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 142, maximum: 190), spacing: 16)
    ]

    var body: some View {
        VStack(spacing: 0) {
            PhotoToolbar(roll: roll, onImportPhotos: onImportPhotos)

            ScrollView {
                if roll.frames.isEmpty {
                    EmptyRollView()
                        .frame(maxWidth: .infinity, minHeight: 420)
                } else {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(roll.frames) { frame in
                            FrameThumbnail(
                                frame: frame,
                                isSelected: frame.id == selectedFrameID
                            )
                            .onTapGesture(count: 2) {
                                selectedFrameID = frame.id
                                onOpenFrame(frame)
                            }
                            .onTapGesture {
                                selectedFrameID = frame.id
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    onDeleteFrame(frame)
                                } label: {
                                    Label("删除照片", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .background(Color(nsColor: .textBackgroundColor).opacity(0.55))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct PhotoToolbar: View {
    let roll: FilmRoll
    let onImportPhotos: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(roll.name)
                    .font(.system(size: 20, weight: .semibold))
                Text("\(roll.stock) · \(roll.frameCount) 张扫描底片")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onImportPhotos) {
                Label("导入", systemImage: "square.and.arrow.down")
            }
            .help("从文件夹导入照片")

            Button {
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .help("导出")
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(.bar)
    }
}

private struct EmptyRollView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(.secondary)
            Text("这卷胶卷还没有照片")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}
