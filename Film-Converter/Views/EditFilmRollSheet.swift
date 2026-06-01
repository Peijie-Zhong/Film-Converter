//
//  EditFilmRollSheet.swift
//  Film-Converter
//

import SwiftUI

struct EditFilmRollSheet: View {
    @Environment(\.appLanguage) private var language
    @Binding var roll: FilmRoll
    let catalog: FilmCatalog
    @Environment(\.dismiss) private var dismiss

    private var selectedStock: Binding<String> {
        Binding(
            get: { roll.stock },
            set: { model in
                roll.stock = model
                roll.name = model

                if let stock = catalog.stock(named: model) {
                    roll.accent = stock.accent
                }
            }
        )
    }

    private var isoText: Binding<String> {
        Binding(
            get: { roll.iso.map(String.init) ?? "" },
            set: { text in
                let digits = text.filter(\.isNumber)
                roll.iso = digits.isEmpty ? nil : Int(digits)
            }
        )
    }

    private var selectedCameraModel: Binding<String> {
        Binding(
            get: { roll.cameraModel ?? "" },
            set: { model in
                roll.cameraModel = model.isEmpty ? nil : model
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(language.text("editRoll"))
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
            .padding(.horizontal, 24)
            .padding(.top, 22)
            .padding(.bottom, 16)

            Divider()

            Form {
                Section(language.text("basicParameters")) {
                    Picker(language.text("filmModel"), selection: selectedStock) {
                        ForEach(catalog.stocks) { stock in
                            Text(stock.model).tag(stock.model)
                        }
                    }

                    Picker(language.text("cameraModel"), selection: selectedCameraModel) {
                        Text(language.text("notSelected")).tag("")
                        ForEach(catalog.cameraModels) { camera in
                            Text(camera.name).tag(camera.name)
                        }
                    }

                    Picker("Format", selection: $roll.format) {
                        ForEach(catalog.formats) { format in
                            Text(format.name).tag(format.name)
                        }
                    }

                    Picker(language.text("frameSize"), selection: $roll.frameSize) {
                        ForEach(catalog.frameSizes) { size in
                            Text(size.name).tag(size.name)
                        }
                    }
                }

                Section(language.text("shootingInfo")) {
                    TextField("ISO", text: isoText)
                    TextEditor(text: $roll.notes)
                        .frame(minHeight: 120)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button(language.text("done")) {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(18)
        }
        .frame(width: 520, height: 460)
    }
}
