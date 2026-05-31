//
//  RollSidebar.swift
//  Film-Converter
//

import SwiftUI

struct RollSidebar: View {
    let filmRolls: [FilmRoll]
    let selectedRollID: FilmRoll.ID?
    let appearanceMode: AppAppearanceMode
    let onAddRoll: () -> Void
    let onOpenSettings: () -> Void
    let onToggleAppearance: () -> Void
    let onSelectRoll: (FilmRoll) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 18, weight: .semibold))
                Text("Film Converter")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Button(action: onAddRoll) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("添加胶卷")
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Text("胶卷")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)

            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(filmRolls) { roll in
                        RollRow(
                            roll: roll,
                            isSelected: roll.id == selectedRollID
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelectRoll(roll)
                        }
                    }
                }
                .padding(.horizontal, 10)
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
                .help("设置")

                Button(action: onToggleAppearance) {
                    Image(systemName: appearanceMode.toggleIcon)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
                .help("切换白天/夜间模式")

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .frame(width: 244)
        .background(.regularMaterial)
    }
}

private struct RollRow: View {
    let roll: FilmRoll
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(roll.accent.gradient)
                Image(systemName: "film.stack")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.92))
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(roll.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("\(roll.stock) · \(roll.frameCount) 张")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(roll.date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)
        }
        .padding(8)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.accentColor.opacity(0.18))
            }
        }
    }
}
