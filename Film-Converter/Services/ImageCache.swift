//
//  ImageCache.swift
//  Film-Converter
//

import AppKit

enum ImageCache {
    private static let cache = NSCache<NSURL, NSImage>()

    static func image(for url: URL) -> NSImage? {
        let key = url as NSURL

        if let cachedImage = cache.object(forKey: key) {
            return cachedImage
        }

        guard let image = NSImage(contentsOf: url) else {
            return nil
        }

        cache.setObject(image, forKey: key)
        return image
    }
}

