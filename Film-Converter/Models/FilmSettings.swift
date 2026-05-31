//
//  FilmSettings.swift
//  Film-Converter
//

enum FilmFormat: String, CaseIterable, Identifiable {
    case thirtyFiveMillimeter = "35mm"
    case oneTwenty = "120mm"

    var id: String { rawValue }
}

enum FilmFrameSize: String, CaseIterable, Identifiable {
    case fullFrame35mm = "35mm"
    case halfFrame35mm = "Half Frame"
    case panoramic35mm = "XPan / Panoramic"
    case oneTwenty = "120mm"
    case sixByFourFive = "6x4.5"
    case sixBySix = "6x6"
    case sixBySeven = "6x7"
    case sixByEight = "6x8"
    case sixByNine = "6x9"
    case sixByTwelve = "6x12"
    case sixBySeventeen = "6x17"

    var id: String { rawValue }
}

struct NewFilmRollForm {
    var stock = FilmStock.library[0]
    var format = FilmFormat.thirtyFiveMillimeter
    var frameSize = FilmFrameSize.fullFrame35mm
    var isoText = "400"
    var notes = ""

    var isoValue: Int? {
        Int(isoText)
    }
}
