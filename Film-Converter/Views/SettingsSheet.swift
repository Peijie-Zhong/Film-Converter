//
//  SettingsSheet.swift
//  Film-Converter
//

import SwiftUI

struct SettingsSheet: View {
    @Binding var appearanceMode: AppAppearanceMode
    @Binding var appLanguage: AppLanguage
    @Environment(\.appLanguage) private var language
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection = SettingsSection.appearance

    var body: some View {
        HStack(spacing: 0) {
            List(SettingsSection.allCases, selection: $selectedSection) { section in
                Label(section.title(language: language), systemImage: section.icon)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .frame(width: 190)

            Divider()

            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Text(selectedSection.title(language: language))
                        .font(.system(size: 22, weight: .semibold))
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.borderless)
                    .help(language.text("close"))
                }

                switch selectedSection {
                case .appearance:
                    appearanceSettings
                case .processing:
                    placeholderSettings(
                        title: language.text("processingPlaceholderTitle"),
                        message: language.text("processingPlaceholderMessage")
                    )
                case .library:
                    placeholderSettings(
                        title: language.text("libraryPlaceholderTitle"),
                        message: language.text("libraryPlaceholderMessage")
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
            Text(language.text("pageUI"))
                .font(.headline)

            Picker(language.text("appearanceMode"), selection: $appearanceMode) {
                ForEach(AppAppearanceMode.allCases) { mode in
                    Text(mode.title(language: language)).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Picker(language.text("language"), selection: $appLanguage) {
                ForEach(AppLanguage.allCases) { appLanguage in
                    Text(appLanguage.title).tag(appLanguage)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                Text(appearanceMode == .light ? language.text("lightDescription") : language.text("darkDescription"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Circle()
                        .fill(appearanceMode.accentColor)
                        .frame(width: 14, height: 14)
                    Text(language.text("currentAccentColor"))
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
        title(language: .zhHans)
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .appearance:
            language.text("appearance")
        case .processing:
            language.text("processing")
        case .library:
            language.text("library")
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
