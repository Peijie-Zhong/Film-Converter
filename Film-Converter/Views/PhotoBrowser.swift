//
//  PhotoBrowser.swift
//  Film-Converter
//

import SwiftUI
import UniformTypeIdentifiers

struct PhotoBrowser: View {
    @Environment(\.appLanguage) private var language
    let roll: FilmRoll
    @Binding var selectedFrameIDs: Set<FilmFrame.ID>
    let transitionNamespace: Namespace.ID
    let onImportPhotos: () -> Void
    let onImportPhotoURLs: ([URL]) -> Void
    let onDeleteFrames: ([FilmFrame]) -> Void
    let onOpenFrame: (FilmFrame) -> Void
    @State private var frameRects: [FilmFrame.ID: CGRect] = [:]
    @State private var selectionRect: CGRect?

    private let columns = [
        GridItem(.adaptive(minimum: 142, maximum: 190), spacing: 16)
    ]

    var body: some View {
        VStack(spacing: 0) {
            PhotoToolbar(
                roll: roll,
                selectedFrameCount: selectedFrameIDs.count,
                onImportPhotos: onImportPhotos,
                onDeleteSelectedFrames: {
                    onDeleteFrames(selectedFrames())
                }
            )

            ScrollView {
                if roll.frames.isEmpty {
                    EmptyRollView(
                        onImportPhotos: onImportPhotos,
                        onImportPhotoURLs: onImportPhotoURLs
                    )
                    .frame(maxWidth: .infinity, minHeight: 420)
                } else {
                    ZStack(alignment: .topLeading) {
                        LazyVGrid(columns: columns, spacing: 18) {
                            ForEach(roll.frames) { frame in
                                FrameThumbnail(
                                    frame: frame,
                                    isSelected: selectedFrameIDs.contains(frame.id),
                                    transitionNamespace: transitionNamespace
                                )
                                .background {
                                    GeometryReader { proxy in
                                        Color.clear.preference(
                                            key: FrameRectPreferenceKey.self,
                                            value: [frame.id: proxy.frame(in: .named("photoGrid"))]
                                        )
                                    }
                                }
                                .onTapGesture(count: 2) {
                                    selectedFrameIDs = [frame.id]
                                    onOpenFrame(frame)
                                }
                                .onTapGesture {
                                    selectedFrameIDs = [frame.id]
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        let frames = selectedFrames(containing: frame)
                                        onDeleteFrames(frames)
                                    } label: {
                                        Label(deleteTitle(for: frame), systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(24)

                        if let selectionRect {
                            Rectangle()
                                .fill(Color.accentColor.opacity(0.12))
                                .overlay {
                                    Rectangle()
                                        .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 1.4, dash: [6, 4]))
                                }
                                .frame(width: selectionRect.width, height: selectionRect.height)
                                .offset(x: selectionRect.minX, y: selectionRect.minY)
                        }
                    }
                    .coordinateSpace(name: "photoGrid")
                    .onPreferenceChange(FrameRectPreferenceKey.self) { rects in
                        frameRects = rects
                    }
                    .gesture(selectionGesture)
                }
            }
            .background(Color(nsColor: .textBackgroundColor).opacity(0.55))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var selectionGesture: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .named("photoGrid"))
            .onChanged { value in
                let rect = CGRect(
                    x: min(value.startLocation.x, value.location.x),
                    y: min(value.startLocation.y, value.location.y),
                    width: abs(value.location.x - value.startLocation.x),
                    height: abs(value.location.y - value.startLocation.y)
                )

                selectionRect = rect
                selectedFrameIDs = Set(frameRects.compactMap { id, frameRect in
                    frameRect.intersects(rect) ? id : nil
                })
            }
            .onEnded { _ in
                selectionRect = nil
            }
    }

    private func selectedFrames(containing frame: FilmFrame) -> [FilmFrame] {
        let ids = selectedFrameIDs.contains(frame.id) ? selectedFrameIDs : [frame.id]
        return roll.frames.filter { ids.contains($0.id) }
    }

    private func selectedFrames() -> [FilmFrame] {
        roll.frames.filter { selectedFrameIDs.contains($0.id) }
    }

    private func deleteTitle(for frame: FilmFrame) -> String {
        let count = selectedFrames(containing: frame).count
        return count > 1 ? String(format: language.text("deletePhotosFormat"), count) : language.text("deletePhoto")
    }
}

private struct PhotoToolbar: View {
    @Environment(\.appLanguage) private var language
    let roll: FilmRoll
    let selectedFrameCount: Int
    let onImportPhotos: () -> Void
    let onDeleteSelectedFrames: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(roll.name)
                    .font(.system(size: 20, weight: .semibold))
                Text("\(roll.stock) · \(String(format: language.text("scannedFramesFormat"), roll.frameCount))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onImportPhotos) {
                Label(language.text("import"), systemImage: "square.and.arrow.down")
            }
            .help(language.text("importPhotosHelp"))

            Button(role: .destructive, action: onDeleteSelectedFrames) {
                Label(language.text("delete"), systemImage: "trash")
            }
            .disabled(selectedFrameCount == 0)
            .help(selectedFrameCount > 1 ? String(format: language.text("deleteSelectedPhotosFormat"), selectedFrameCount) : language.text("deleteSelectedPhoto"))

            Button {
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .help(language.text("export"))
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(.bar)
    }
}

private struct EmptyRollView: View {
    @Environment(\.appLanguage) private var language
    let onImportPhotos: () -> Void
    let onImportPhotoURLs: ([URL]) -> Void
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 12) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(.secondary)
                Text(language.text("dragPhotosHere"))
                    .font(.system(size: 15, weight: .semibold))
                Text(language.text("emptyRollMessage"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    onImportPhotos()
                } label: {
                    Label(language.text("uploadPhotos"), systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(34)
            .frame(width: 360)
            .background(Color(nsColor: .controlBackgroundColor).opacity(isDropTargeted ? 0.9 : 0.52))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        Color.accentColor.opacity(isDropTargeted ? 0.95 : 0.55),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .onDrop(
                of: [UTType.fileURL.identifier],
                isTargeted: $isDropTargeted,
                perform: handleDrop(providers:)
            )
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        let group = DispatchGroup()
        var urls: [URL] = []
        let lock = NSLock()

        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }

                let url: URL?
                if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else if let itemURL = item as? URL {
                    url = itemURL
                } else if let itemNSURL = item as? NSURL {
                    url = itemNSURL as URL
                } else {
                    url = nil
                }

                if let url {
                    lock.lock()
                    urls.append(url)
                    lock.unlock()
                }
            }
        }

        group.notify(queue: .main) {
            let imageURLs = PhotoImportService.imageURLs(from: urls)
            if !imageURLs.isEmpty {
                onImportPhotoURLs(imageURLs)
            }
        }

        return true
    }
}

private struct FrameRectPreferenceKey: PreferenceKey {
    static var defaultValue: [FilmFrame.ID: CGRect] = [:]

    static func reduce(value: inout [FilmFrame.ID: CGRect], nextValue: () -> [FilmFrame.ID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
