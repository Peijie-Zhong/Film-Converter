//
//  FilmSettings.swift
//  Film-Converter
//

struct FilmCatalog: Hashable {
    var stocks: [FilmStock] = []
    var cameraModels: [CameraModelOption] = []
    var formats: [FilmFormatOption] = []
    var frameSizes: [FilmFrameSizeOption] = []

    static let empty = FilmCatalog()

    var defaultStock: FilmStock? {
        stocks.first
    }

    var defaultFormat: String {
        formats.first?.name ?? "35mm"
    }

    var defaultFrameSize: String {
        frameSizes.first?.name ?? "35mm"
    }

    func stock(named model: String) -> FilmStock? {
        stocks.first { $0.model == model }
    }
}

struct CameraModelOption: Identifiable, Hashable {
    var id: String { name }
    var name: String
}

struct FilmFormatOption: Identifiable, Hashable {
    var id: String { name }
    var name: String
}

struct FilmFrameSizeOption: Identifiable, Hashable {
    var id: String { name }
    var name: String
    var formatName: String?
}

struct NewFilmRollForm {
    var stock: FilmStock?
    var cameraModel = ""
    var format = ""
    var frameSize = ""
    var isoText = "400"
    var notes = ""

    init(catalog: FilmCatalog = .empty) {
        stock = catalog.defaultStock
        format = catalog.defaultFormat
        frameSize = catalog.defaultFrameSize
    }

    var isoValue: Int? {
        Int(isoText)
    }
}
