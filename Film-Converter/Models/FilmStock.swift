//
//  FilmStock.swift
//  Film-Converter
//

import SwiftUI

struct FilmStock: Identifiable, Hashable {
    var id: String { model }
    let model: String
    let maker: String
    let accent: Color
}

extension FilmStock {
    static let library: [FilmStock] = [
        FilmStock(model: "ADOX CHS 100 II", maker: "ADOX", accent: .gray),
        FilmStock(model: "Bergger Pancro 400", maker: "Bergger", accent: .brown),
        FilmStock(model: "Cinestill 50D", maker: "Cinestill", accent: .yellow),
        FilmStock(model: "Cinestill 400D", maker: "Cinestill", accent: .orange),
        FilmStock(model: "Cinestill 800T", maker: "Cinestill", accent: .blue),
        FilmStock(model: "Dubblefilm Apollo", maker: "Dubblefilm", accent: .purple),
        FilmStock(model: "Fomapan 100 Classic", maker: "Foma", accent: .gray),
        FilmStock(model: "Fomapan 400 Action", maker: "Foma", accent: .black),
        FilmStock(model: "Fujifilm C200", maker: "Fujifilm", accent: .green),
        FilmStock(model: "Fujifilm Pro 400H", maker: "Fujifilm", accent: .mint),
        FilmStock(model: "Ilford Delta 100", maker: "Ilford", accent: .gray),
        FilmStock(model: "Ilford HP5 Plus", maker: "Ilford", accent: .black),
        FilmStock(model: "Ilford XP2 Super", maker: "Ilford", accent: .indigo),
        FilmStock(model: "Kentmere Pan 400", maker: "Kentmere", accent: .gray),
        FilmStock(model: "Kodak ColorPlus 200", maker: "Kodak", accent: .yellow),
        FilmStock(model: "Kodak Ektachrome E100", maker: "Kodak", accent: .cyan),
        FilmStock(model: "Kodak Ektar 100", maker: "Kodak", accent: .red),
        FilmStock(model: "Kodak Gold 200", maker: "Kodak", accent: .yellow),
        FilmStock(model: "Kodak Portra 160", maker: "Kodak", accent: .orange),
        FilmStock(model: "Kodak Portra 400", maker: "Kodak", accent: .orange),
        FilmStock(model: "Kodak Portra 800", maker: "Kodak", accent: .pink),
        FilmStock(model: "Kodak Tri-X 400", maker: "Kodak", accent: .black),
        FilmStock(model: "Lomography Color Negative 400", maker: "Lomography", accent: .purple),
        FilmStock(model: "Lomography Metropolis", maker: "Lomography", accent: .brown),
        FilmStock(model: "ORWO Wolfen NC500", maker: "ORWO", accent: .red),
        FilmStock(model: "Rollei Retro 400S", maker: "Rollei", accent: .gray),
        FilmStock(model: "Shanghai GP3 100", maker: "Shanghai", accent: .black),
        FilmStock(model: "Silberra Color 100", maker: "Silberra", accent: .cyan),
        FilmStock(model: "Yodica Andromeda", maker: "Yodica", accent: .purple)
    ].sorted { $0.model.localizedStandardCompare($1.model) == .orderedAscending }
}
