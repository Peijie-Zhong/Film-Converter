//
//  ContentView.swift
//  Film-Converter
//
//  Created by Peijie Zhong on 31/05/2026.
//

import AppKit
import SwiftUI

struct ContentView: View {
    @Namespace private var photoTransitionNamespace
    @AppStorage("appLanguage") private var appLanguageRawValue = AppLanguage.zhHans.rawValue
    @State private var filmRolls: [FilmRoll] = []
    @State private var filmCatalog = FilmCatalog.empty
    @State private var selectedRollID: FilmRoll.ID?
    @State private var selectedFrameIDs: Set<FilmFrame.ID> = []
    @State private var openedFrameID: FilmFrame.ID?
    @State private var activeTool: ToolPanel?
    @State private var isAddingFilmRoll = false
    @State private var isShowingSettings = false
    @State private var appearanceMode = AppAppearanceMode.light
    @State private var appearanceTransition: AppearanceTransition?
    @State private var editingRollID: FilmRoll.ID?
    @State private var rollPendingDeletion: FilmRoll?
    @State private var hasLoadedDatabase = false

    private var selectedRoll: FilmRoll? {
        filmRolls.first { $0.id == selectedRollID } ?? filmRolls.first
    }

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .zhHans
    }

    private var appLanguageBinding: Binding<AppLanguage> {
        Binding(
            get: { appLanguage },
            set: { appLanguageRawValue = $0.rawValue }
        )
    }

    private var openedFrame: FilmFrame? {
        guard let openedFrameID else { return nil }
        return selectedRoll?.frames.first { $0.id == openedFrameID }
    }

    private var editingRollBinding: Binding<FilmRoll>? {
        guard let editingRollID,
              let rollIndex = filmRolls.firstIndex(where: { $0.id == editingRollID }) else {
            return nil
        }

        return Binding(
            get: {
                filmRolls[rollIndex]
            },
            set: { updatedRoll in
                if let currentIndex = filmRolls.firstIndex(where: { $0.id == editingRollID }) {
                    filmRolls[currentIndex] = updatedRoll
                }
            }
        )
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
        ZStack {
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
                        setAppearance(appearanceMode.toggled)
                    },
                    onSelectRoll: selectRoll,
                    onEditRoll: { roll in
                        editingRollID = roll.id
                    },
                    onRequestDeleteRoll: { roll in
                        rollPendingDeletion = roll
                    }
                )

                Divider()

                if let selectedRoll, let openedFrameBinding {
                    SinglePhotoView(
                        roll: selectedRoll,
                        frame: openedFrameBinding,
                        transitionNamespace: photoTransitionNamespace,
                        activeTool: $activeTool
                    ) {
                        closeOpenedFrame()
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.96).combined(with: .opacity),
                        removal: .scale(scale: 1.02).combined(with: .opacity)
                    ))

                    Divider()

                    ToolInspector(
                        activeTool: $activeTool,
                        frame: openedFrameBinding,
                        roll: selectedRoll
                    )
                } else if let selectedRoll {
                    PhotoBrowser(
                        roll: selectedRoll,
                        selectedFrameIDs: $selectedFrameIDs,
                        transitionNamespace: photoTransitionNamespace,
                        onImportPhotos: importPhotos,
                        onImportPhotoURLs: importPhotoURLs,
                        onDeleteFrames: deleteFrames
                    ) { frame in
                        selectedFrameIDs = [frame.id]
                        openFrame(frame)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
                } else {
                    ContentUnavailableView(
                        appLanguage.text("addRoll"),
                        systemImage: "film.stack",
                        description: Text(appLanguage.text("emptyLibraryMessage"))
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            if let appearanceTransition {
                AppearanceTransitionOverlay(transition: appearanceTransition)
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .frame(minWidth: 1080, minHeight: 680)
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(appearanceMode.colorScheme)
        .tint(appearanceMode.accentColor)
        .environment(\.appLanguage, appLanguage)
        .animation(.smooth(duration: 0.42), value: openedFrameID)
        .animation(.easeInOut(duration: 0.72), value: appearanceMode)
        .sheet(isPresented: $isAddingFilmRoll) {
            AddFilmRollSheet(catalog: filmCatalog) { roll in
                filmRolls.append(roll)
                selectRoll(roll)
            }
        }
        .sheet(isPresented: editingRollSheetBinding) {
            if let editingRollBinding {
                EditFilmRollSheet(roll: editingRollBinding, catalog: filmCatalog)
                    .preferredColorScheme(appearanceMode.colorScheme)
                    .tint(appearanceMode.accentColor)
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsSheet(
                appearanceMode: appearanceBinding,
                appLanguage: appLanguageBinding
            )
                .preferredColorScheme(appearanceMode.colorScheme)
                .tint(appearanceMode.accentColor)
                .environment(\.appLanguage, appLanguage)
        }
        .alert(appLanguage.text("deleteRollTitle"), isPresented: deleteRollAlertBinding) {
            Button(appLanguage.text("cancel"), role: .cancel) {
                rollPendingDeletion = nil
            }
            Button(appLanguage.text("delete"), role: .destructive) {
                deletePendingRoll()
            }
        } message: {
            Text(appLanguage.text("deleteRollMessage"))
        }
        .onAppear {
            loadFilmLibraryIfNeeded()
        }
        .onChange(of: filmRolls) { _, rolls in
            guard hasLoadedDatabase else {
                return
            }

            FilmDatabase.replaceAll(with: rolls)
        }
    }

    private var deleteRollAlertBinding: Binding<Bool> {
        Binding(
            get: { rollPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    rollPendingDeletion = nil
                }
            }
        )
    }

    private var editingRollSheetBinding: Binding<Bool> {
        Binding(
            get: { editingRollID != nil },
            set: { isPresented in
                if !isPresented {
                    editingRollID = nil
                }
            }
        )
    }

    private var appearanceBinding: Binding<AppAppearanceMode> {
        Binding(
            get: { appearanceMode },
            set: { setAppearance($0) }
        )
    }

    private func setAppearance(_ nextMode: AppAppearanceMode) {
        guard nextMode != appearanceMode else {
            return
        }

        let transition = AppearanceTransition(snapshot: NSApp.keyWindow?.contentView?.snapshotImage())
        appearanceTransition = transition

        withAnimation(.easeInOut(duration: 0.46)) {
            appearanceMode = nextMode
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(540))
            if appearanceTransition?.id == transition.id {
                appearanceTransition = nil
            }
        }
    }

    private func loadFilmLibraryIfNeeded() {
        guard !hasLoadedDatabase else {
            return
        }

        filmCatalog = FilmDatabase.loadCatalog()
        filmRolls = FilmDatabase.load()

        if selectedRollID == nil || !filmRolls.contains(where: { $0.id == selectedRollID }) {
            selectedRollID = filmRolls.first?.id
        }
        if selectedFrameIDs.isEmpty, let firstFrameID = filmRolls.first?.frames.first?.id {
            selectedFrameIDs = [firstFrameID]
        }
        hasLoadedDatabase = true
    }

    private func selectRoll(_ roll: FilmRoll) {
        selectedRollID = roll.id
        selectedFrameIDs = Set(roll.frames.first.map { [$0.id] } ?? [])
        openedFrameID = nil
        activeTool = nil
    }

    private func openFrame(_ frame: FilmFrame) {
        withAnimation(.smooth(duration: 0.42)) {
            openedFrameID = frame.id
        }
    }

    private func closeOpenedFrame() {
        withAnimation(.smooth(duration: 0.38)) {
            openedFrameID = nil
            activeTool = nil
        }
    }

    private func importPhotos() {
        let urls = PhotoImportService.choosePhotos(language: appLanguage)

        importPhotoURLs(urls)
    }

    private func importPhotoURLs(_ urls: [URL]) {
        guard !urls.isEmpty else {
            return
        }
        guard let rollIndex = filmRolls.firstIndex(where: { $0.id == selectedRollID }) ?? filmRolls.indices.first else {
            return
        }

        let startNumber = filmRolls[rollIndex].frames.count + 1
        let frames = FilmFrame.imported(from: urls, startingAt: startNumber)
        filmRolls[rollIndex].frames.append(contentsOf: frames)
        filmRolls[rollIndex].frameCount = filmRolls[rollIndex].frames.count
        selectedFrameIDs = Set(frames.map(\.id))
    }

    private func deleteFrames(_ frames: [FilmFrame]) {
        guard let rollIndex = filmRolls.firstIndex(where: { $0.id == selectedRollID }) else {
            return
        }
        let ids = Set(frames.map(\.id))
        filmRolls[rollIndex].frames.removeAll { ids.contains($0.id) }
        filmRolls[rollIndex].frames = filmRolls[rollIndex].frames.enumerated().map { index, frame in
            var updatedFrame = frame
            updatedFrame.number = index + 1
            return updatedFrame
        }
        filmRolls[rollIndex].frameCount = filmRolls[rollIndex].frames.count

        selectedFrameIDs.subtract(ids)

        if selectedFrameIDs.isEmpty, let firstFrameID = filmRolls[rollIndex].frames.first?.id {
            selectedFrameIDs = [firstFrameID]
        }
    }

    private func deletePendingRoll() {
        guard let roll = rollPendingDeletion,
              let rollIndex = filmRolls.firstIndex(where: { $0.id == roll.id }) else {
            rollPendingDeletion = nil
            return
        }

        filmRolls.remove(at: rollIndex)

        if selectedRollID == roll.id {
            if filmRolls.isEmpty {
                selectedRollID = nil
                selectedFrameIDs = []
                openedFrameID = nil
            } else {
                let nextIndex = min(rollIndex, filmRolls.count - 1)
                selectRoll(filmRolls[nextIndex])
            }
        }

        rollPendingDeletion = nil
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

private struct AppearanceTransition: Identifiable, Equatable {
    let id = UUID()
    let snapshot: NSImage?

    static func == (lhs: AppearanceTransition, rhs: AppearanceTransition) -> Bool {
        lhs.id == rhs.id
    }
}

private struct AppearanceTransitionOverlay: View {
    let transition: AppearanceTransition
    @State private var opacity = 1.0

    var body: some View {
        GeometryReader { proxy in
            if let snapshot = transition.snapshot {
                Image(nsImage: snapshot)
                    .resizable()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .opacity(opacity)
            } else {
                Color.black.opacity(opacity * 0.1)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            opacity = 1
            withAnimation(.easeInOut(duration: 0.48)) {
                opacity = 0
            }
        }
    }
}

private extension NSView {
    func snapshotImage() -> NSImage? {
        let bounds = bounds
        guard bounds.width > 0, bounds.height > 0,
              let bitmap = bitmapImageRepForCachingDisplay(in: bounds) else {
            return nil
        }

        cacheDisplay(in: bounds, to: bitmap)

        let image = NSImage(size: bounds.size)
        image.addRepresentation(bitmap)
        return image
    }
}
