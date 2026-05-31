//
//  PhotoInfoPanel.swift
//  Film-Converter
//

import SwiftUI

struct PhotoInfoPanel: View {
    @Binding var frame: FilmFrame

    private var isoBinding: Binding<String> {
        Binding(
            get: { frame.captureInfo.iso },
            set: { frame.captureInfo.iso = $0.filter(\.isNumber) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("照片信息")
                        .font(.system(size: 16, weight: .semibold))
                    Text(frame.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                InfoField(title: "ISO", text: isoBinding, prompt: "400")
                InfoField(title: "光圈", text: $frame.captureInfo.aperture, prompt: "f/2.8")
                InfoField(title: "快门速度", text: $frame.captureInfo.shutterSpeed, prompt: "1/125")
                InfoField(title: "拍摄时间", text: $frame.captureInfo.capturedAt, prompt: "2026-05-31 18:30")
                InfoField(title: "拍摄地点", text: $frame.captureInfo.location, prompt: "Tokyo, Japan")

                VStack(alignment: .leading, spacing: 8) {
                    Text("备注")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextEditor(text: $frame.captureInfo.notes)
                        .font(.system(size: 13))
                        .scrollContentBackground(.hidden)
                        .padding(6)
                        .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 7))
                        .overlay {
                            RoundedRectangle(cornerRadius: 7)
                                .strokeBorder(.quaternary, lineWidth: 1)
                        }
                        .frame(minHeight: 92)
                }
            }

            Spacer()
        }
        .padding(18)
        .frame(width: 268)
    }
}

private struct InfoField: View {
    let title: String
    @Binding var text: String
    let prompt: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField(prompt, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}
