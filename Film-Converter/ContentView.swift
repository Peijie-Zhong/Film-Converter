//
//  ContentView.swift
//  Film-Converter
//
//  Created by Peijie Zhong on 31/05/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var filmRolls = FilmRoll.samples
    @State private var selectedRollID: FilmRoll.ID?
    @State private var selectedFrameID: FilmFrame.ID?
    @State private var openedFrameID: FilmFrame.ID?
    @State private var activeTool: ToolPanel?
    @State private var isAddingFilmRoll = false
    @State private var isShowingSettings = false
    @State private var appearanceMode = AppAppearanceMode.light

    private var selectedRoll: FilmRoll {
        filmRolls.first { $0.id == selectedRollID } ?? filmRolls[0]
    }

    private var selectedRollIndex: Int {
        filmRolls.firstIndex { $0.id == selectedRollID } ?? 0
    }

    private var openedFrame: FilmFrame? {
        guard let openedFrameID else { return nil }
        return selectedRoll.frames.first { $0.id == openedFrameID }
    }

    private var openedFrameBinding: Binding<FilmFrame>? {
        guard let openedFrameID,
              let rollIndex = filmRolls.firstIndex(where: { $0.id == selectedRollID }),
              let frameIndex = filmRolls[rollIndex].frames.firstIndex(where: { $0.id == openedFrameID }) else {
            return nil
        }

        return Binding(
            get: {
                filmRolls[rollIndex].frames[frameIndex]
            },
            set: { updatedFrame in
                if let currentRollIndex = filmRolls.firstIndex(where: { $0.id == selectedRollID }),
                   let currentFrameIndex = filmRolls[currentRollIndex].frames.firstIndex(where: { $0.id == openedFrameID }) {
                    filmRolls[currentRollIndex].frames[currentFrameIndex] = updatedFrame
                }
            }
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            RollSidebar(
                filmRolls: filmRolls,
                selectedRollID: selectedRollID,
                appearanceMode: appearanceMode,
                onAddRoll: {
                    isAddingFilmRoll = true
                },
                onOpenSettings: {
                    isShowingSettings = true
                },
                onToggleAppearance: {
                    appearanceMode.toggle()
                },
                onSelectRoll: selectRoll
            )

            Divider()

            if let openedFrameBinding {
                SinglePhotoView(
                    roll: selectedRoll,
                    frame: openedFrameBinding,
                    activeTool: $activeTool
                ) {
                    openedFrameID = nil
                    activeTool = nil
                }

                Divider()

                ToolInspector(
                    activeTool: $activeTool,
                    frame: openedFrameBinding
                )
            } else {
                PhotoBrowser(
                    roll: selectedRoll,
                    selectedFrameID: $selectedFrameID,
                    onImportPhotos: importPhotos,
                    onDeleteFrame: deleteFrame
                ) { frame in
                    selectedFrameID = frame.id
                    openedFrameID = frame.id
                }
            }
        }
        .frame(minWidth: 1080, minHeight: 680)
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(appearanceMode.colorScheme)
        .tint(appearanceMode.accentColor)
        .sheet(isPresented: $isAddingFilmRoll) {
            AddFilmRollSheet { roll in
                filmRolls.append(roll)
                selectRoll(roll)
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsSheet(appearanceMode: $appearanceMode)
                .preferredColorScheme(appearanceMode.colorScheme)
                .tint(appearanceMode.accentColor)
        }
        .onAppear {
            if selectedRollID == nil {
                selectedRollID = filmRolls.first?.id
            }
            if selectedFrameID == nil {
                selectedFrameID = filmRolls.first?.frames.first?.id
            }
        }
    }

    private func selectRoll(_ roll: FilmRoll) {
        selectedRollID = roll.id
        selectedFrameID = roll.frames.first?.id
        openedFrameID = nil
        activeTool = nil
    }

    private func importPhotos() {
        let urls = PhotoImportService.choosePhotos()

        guard !urls.isEmpty else {
            return
        }

        let rollIndex = selectedRollIndex
        let startNumber = filmRolls[rollIndex].frames.count + 1
        let frames = FilmFrame.imported(from: urls, startingAt: startNumber)
        filmRolls[rollIndex].frames.append(contentsOf: frames)
        filmRolls[rollIndex].frameCount = filmRolls[rollIndex].frames.count
        selectedFrameID = frames.first?.id
    }

    private func deleteFrame(_ frame: FilmFrame) {
        let rollIndex = selectedRollIndex
        filmRolls[rollIndex].frames.removeAll { $0.id == frame.id }
        filmRolls[rollIndex].frames = filmRolls[rollIndex].frames.enumerated().map { index, frame in
            var updatedFrame = frame
            updatedFrame.number = index + 1
            return updatedFrame
        }
        filmRolls[rollIndex].frameCount = filmRolls[rollIndex].frames.count

        if selectedFrameID == frame.id {
            selectedFrameID = filmRolls[rollIndex].frames.first?.id
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
