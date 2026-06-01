//
//  FrameThumbnail.swift
//  Film-Converter
//

import SwiftUI

struct FrameThumbnail: View {
    let frame: FilmFrame
    let isSelected: Bool
    let transitionNamespace: Namespace.ID

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    FrameArtwork(frame: frame, showsFrameNumber: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .matchedGeometryEffect(id: frame.id, in: transitionNamespace)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.accentColor, lineWidth: 3)
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(frame.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(frame.exposure)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(6)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.08))
            }
        }
    }
}
