//
//  FilmRoll.swift
//  Film-Converter
//

import Foundation
import SwiftUI

struct FilmRoll: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var stock: String
    var frameCount: Int
    var date: String
    var accent: Color
    var frames: [FilmFrame]
    var cameraModel: String?
    var format = "35mm"
    var frameSize = "35mm"
    var iso: Int?
    var notes: String = ""
}

extension FilmRoll {
    var usesMediumFormatBorder: Bool {
        format.localizedCaseInsensitiveContains("120")
    }

    static func created(from form: NewFilmRollForm, fallbackStock: FilmStock) -> FilmRoll {
        let stock = form.stock ?? fallbackStock
        return FilmRoll(
            name: stock.model,
            stock: stock.model,
            frameCount: 0,
            date: DateFormatter.filmRollMonth.string(from: Date()),
            accent: stock.accent,
            frames: [],
            cameraModel: form.cameraModel.isEmpty ? nil : form.cameraModel,
            format: form.format,
            frameSize: form.frameSize,
            iso: form.isoValue,
            notes: form.notes
        )
    }
}

private extension DateFormatter {
    static let filmRollMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()
}
