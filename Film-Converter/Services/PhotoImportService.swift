//
//  PhotoImportService.swift
//  Film-Converter
//

import AppKit
import UniformTypeIdentifiers

enum PhotoImportService {
    static func choosePhotos() -> [URL] {
        let panel = NSOpenPanel()
        panel.title = "导入照片"
        panel.prompt = "导入"
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.image, .folder]

        guard panel.runModal() == .OK else {
            return []
        }

        return imageURLs(from: panel.urls)
    }

    private static func imageURLs(from urls: [URL]) -> [URL] {
        urls.flatMap { url in
            guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey]),
                  values.isDirectory == true else {
                return [url]
            }

            let children = (try? FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.contentTypeKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            )) ?? []

            return children.filter { childURL in
                guard let contentType = try? childURL.resourceValues(forKeys: [.contentTypeKey]).contentType else {
                    return false
                }

                return contentType.conforms(to: .image)
            }
        }
    }
}
