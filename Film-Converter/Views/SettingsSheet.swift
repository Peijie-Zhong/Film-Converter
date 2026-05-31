//
//  SettingsSheet.swift
//  Film-Converter
//

import SwiftUI

struct SettingsSheet: View {
    @Binding var appearanceMode: AppAppearanceMode
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection = SettingsSection.appearance

    var body: some View {
        HStack(spacing: 0) {
            List(SettingsSection.allCases, selection: $selectedSection) { section in
                Label(section.title, systemImage: section.icon)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .frame(width: 190)

            Divider()

            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Text(selectedSection.title)
                        .font(.system(size: 22, weight: .semibold))
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.borderless)
                    .help("关闭")
                }

                switch selectedSection {
                case .appearance:
                    appearanceSettings
                case .processing:
                    placeholderSettings(
                        title: "图像处理",
                        message: "后续的默认去色罩、裁切和导出参数会放在这里。"
                    )
                case .library:
                    placeholderSettings(
                        title: "图库",
                        message: "后续的导入位置、缓存和胶卷库管理会放在这里。"
                    )
                }

                Spacer()
            }
            .padding(24)
            .frame(width: 420)
        }
        .frame(width: 610, height: 420)
    }

    private var appearanceSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("页面 UI")
                .font(.headline)

            Picker("外观", selection: $appearanceMode) {
                ForEach(AppAppearanceMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                Text(appearanceMode == .light ? "白底黑字，蓝色按钮。" : "黑底白字，橙色按钮。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Circle()
                        .fill(appearanceMode.accentColor)
                        .frame(width: 14, height: 14)
                    Text("当前强调色")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func placeholderSettings(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
    }
}

private enum SettingsSection: String, CaseIterable, Identifiable {
    case appearance
    case processing
    case library

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appearance:
            "外观"
        case .processing:
            "图像处理"
        case .library:
            "图库"
        }
    }

    var icon: String {
        switch self {
        case .appearance:
            "paintbrush"
        case .processing:
            "slider.horizontal.3"
        case .library:
            "photo.on.rectangle"
        }
    }
}

