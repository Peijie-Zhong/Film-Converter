//
//  FilmStock.swift
//  Film-Converter
//

import SwiftUI

struct FilmStock: Identifiable, Hashable {
    var id: String { model }
    var model: String
    var maker: String
    var accentName: String

    var accent: Color {
        Self.color(named: accentName)
    }

    static func color(named name: String) -> Color {
        switch name {
        case "black":
            .black
        case "blue":
            .blue
        case "brown":
            .brown
        case "cyan":
            .cyan
        case "gray":
            .gray
        case "green":
            .green
        case "indigo":
            .indigo
        case "mint":
            .mint
        case "orange":
            .orange
        case "pink":
            .pink
        case "purple":
            .purple
        case "red":
            .red
        case "teal":
            .teal
        case "yellow":
            .yellow
        default:
            .accentColor
        }
    }
}
