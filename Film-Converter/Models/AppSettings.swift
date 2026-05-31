//
//  AppSettings.swift
//  Film-Converter
//

import SwiftUI

enum AppAppearanceMode: String, CaseIterable, Identifiable {
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light:
            "白天模式"
        case .dark:
            "夜间模式"
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .light:
            .light
        case .dark:
            .dark
        }
    }

    var accentColor: Color {
        switch self {
        case .light:
            .blue
        case .dark:
            .orange
        }
    }

    var toggleIcon: String {
        switch self {
        case .light:
            "moon.fill"
        case .dark:
            "sun.max.fill"
        }
    }

    mutating func toggle() {
        self = self == .light ? .dark : .light
    }
}

