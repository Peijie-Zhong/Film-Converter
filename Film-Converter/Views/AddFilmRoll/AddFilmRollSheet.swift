//
//  AddFilmRollSheet.swift
//  Film-Converter
//

import SwiftUI

struct AddFilmRollSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var form = NewFilmRollForm()

    let onAdd: (FilmRoll) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("添加胶卷")
                .font(.system(size: 22, weight: .semibold))
                .padding(.horizontal, 24)
                .padding(.top, 22)
                .padding(.bottom, 16)

            Divider()

            HStack(spacing: 0) {
                FilmStockPickerList(selectedStock: $form.stock)
                    .frame(width: 350)

                Divider()

                FilmRollParameterForm(form: $form)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()

            HStack {
                Spacer()
                Button("取消") {
                    dismiss()
                }
                Button("添加") {
                    onAdd(FilmRoll.created(from: form))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(form.isoText.isEmpty)
            }
            .padding(18)
        }
        .frame(width: 860, height: 560)
    }
}

private struct FilmStockPickerList: View {
    @Binding var selectedStock: FilmStock

    private var groupedStocks: [(letter: String, stocks: [FilmStock])] {
        let groups = Dictionary(grouping: FilmStock.library) { stock in
            String(stock.model.prefix(1)).uppercased()
        }

        return groups
            .map { (letter: $0.key, stocks: $0.value) }
            .sorted { $0.letter < $1.letter }
    }

    private var availableLetters: Set<String> {
        Set(groupedStocks.map(\.letter))
    }

    private var alphabet: [String] {
        (65...90).compactMap { UnicodeScalar($0).map { String($0) } }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .trailing) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(groupedStocks, id: \.letter) { section in
                            Text(section.letter)
                                .id(section.letter)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 18)
                                .padding(.top, 14)
                                .padding(.bottom, 6)

                            ForEach(section.stocks) { stock in
                                FilmStockRow(
                                    stock: stock,
                                    isSelected: stock == selectedStock
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedStock = stock
                                }
                            }
                        }
                    }
                    .padding(.trailing, 28)
                    .padding(.bottom, 14)
                }

                VStack(spacing: 1) {
                    ForEach(alphabet, id: \.self) { letter in
                        Button {
                            withAnimation(.snappy(duration: 0.2)) {
                                proxy.scrollTo(letter, anchor: .top)
                            }
                        } label: {
                            Text(letter)
                                .font(.system(size: 9, weight: .semibold))
                                .frame(width: 16, height: 15)
                                .foregroundStyle(
                                    availableLetters.contains(letter)
                                    ? Color.accentColor
                                    : Color.secondary.opacity(0.35)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!availableLetters.contains(letter))
                    }
                }
                .padding(.trailing, 7)
            }
        }
    }
}

private struct FilmStockRow: View {
    let stock: FilmStock
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 4)
                .fill(stock.accent.gradient)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(stock.model)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(stock.maker)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.accentColor.opacity(0.16))
                    .padding(.horizontal, 8)
            }
        }
    }
}

private struct FilmRollParameterForm: View {
    @Binding var form: NewFilmRollForm

    private var isoBinding: Binding<String> {
        Binding(
            get: { form.isoText },
            set: { form.isoText = $0.filter(\.isNumber) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            FormSection(title: "基本参数") {
                LabeledContent("胶卷型号") {
                    Text(form.stock.model)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.secondary)
                }

                Picker("Format", selection: $form.format) {
                    ForEach(FilmFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }

                Picker("尺寸", selection: $form.frameSize) {
                    ForEach(FilmFrameSize.allCases) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
            }

            FormSection(title: "拍摄信息") {
                LabeledContent("使用的 ISO") {
                    TextField("400", text: isoBinding)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextEditor(text: $form.notes)
                        .font(.system(size: 13))
                        .scrollContentBackground(.hidden)
                        .padding(6)
                        .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 7))
                        .overlay {
                            RoundedRectangle(cornerRadius: 7)
                                .strokeBorder(.quaternary, lineWidth: 1)
                        }
                        .frame(minHeight: 126)
                }
            }

            Spacer()
        }
        .padding(24)
    }
}

private struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
        }
    }
}
