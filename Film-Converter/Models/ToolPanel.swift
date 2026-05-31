//
//  ToolPanel.swift
//  Film-Converter
//

enum ToolPanel: String, Identifiable {
    case maskRemoval
    case crop
    case photoInfo

    var id: String { rawValue }
}
