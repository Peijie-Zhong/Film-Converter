//
//  FilmRoll.swift
//  Film-Converter
//

import Foundation
import SwiftUI

struct FilmRoll: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var stock: String
    var frameCount: Int
    var date: String
    var accent: Color
    var frames: [FilmFrame]
    var format: FilmFormat = .thirtyFiveMillimeter
    var frameSize: FilmFrameSize = .fullFrame35mm
    var iso: Int?
    var notes: String = ""
}

extension FilmRoll {
    static func created(from form: NewFilmRollForm) -> FilmRoll {
        FilmRoll(
            name: form.stock.model,
            stock: form.stock.model,
            frameCount: 0,
            date: DateFormatter.filmRollMonth.string(from: Date()),
            accent: form.stock.accent,
            frames: [],
            format: form.format,
            frameSize: form.frameSize,
            iso: form.isoValue,
            notes: form.notes
        )
    }

    static let samples: [FilmRoll] = [
        FilmRoll(
            name: "东京夜行",
            stock: "Kodak Portra 400",
            frameCount: 12,
            date: "2026年5月",
            accent: .orange,
            frames: FilmFrame.makeSet(
                count: 12,
                prefix: "Tokyo",
                colors: [.orange, .pink, .purple, .blue]
            ),
            format: .thirtyFiveMillimeter,
            frameSize: .fullFrame35mm,
            iso: 400
        ),
        FilmRoll(
            name: "海边试卷",
            stock: "Fujifilm C200",
            frameCount: 10,
            date: "2026年4月",
            accent: .teal,
            frames: FilmFrame.makeSet(
                count: 10,
                prefix: "Coast",
                colors: [.cyan, .mint, .yellow, .indigo]
            ),
            format: .thirtyFiveMillimeter,
            frameSize: .fullFrame35mm,
            iso: 200
        ),
        FilmRoll(
            name: "室内灯光",
            stock: "Cinestill 800T",
            frameCount: 8,
            date: "2026年3月",
            accent: .blue,
            frames: FilmFrame.makeSet(
                count: 8,
                prefix: "Room",
                colors: [.blue, .purple, .red, .orange]
            ),
            format: .thirtyFiveMillimeter,
            frameSize: .fullFrame35mm,
            iso: 800
        )
    ]
}

private extension DateFormatter {
    static let filmRollMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()
}
