//
//  PhotoInfoPanel.swift
//  Film-Converter
//

import SwiftUI
import MapKit
import CoreLocation

struct PhotoInfoPanel: View {
    @Environment(\.appLanguage) private var language
    @Binding var frame: FilmFrame
    @State private var isLocationSearchPresented = false

    private var isoBinding: Binding<String> {
        Binding(
            get: { frame.captureInfo.iso },
            set: { frame.captureInfo.iso = $0.filter(\.isNumber) }
        )
    }

    private var capturedAtBinding: Binding<Date> {
        Binding(
            get: {
                Self.captureDateFormatter.date(from: frame.captureInfo.capturedAt)
                    ?? Self.legacyCaptureDateFormatter.date(from: frame.captureInfo.capturedAt)
                    ?? Date()
            },
            set: { date in
                frame.captureInfo.capturedAt = Self.captureDateFormatter.string(from: date)
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(language.text("photoInfo"))
                        .font(.system(size: 16, weight: .semibold))
                    Text(frame.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                InfoField(title: "ISO", text: isoBinding, prompt: "400")
                InfoField(title: language.text("aperture"), text: $frame.captureInfo.aperture, prompt: "f/2.8")
                InfoField(title: language.text("shutterSpeed"), text: $frame.captureInfo.shutterSpeed, prompt: "1/125")
                InfoField(title: language.text("exposureCompensation"), text: $frame.captureInfo.exposureCompensation, prompt: "+0.3 EV")
                InfoField(title: language.text("focalLength"), text: $frame.captureInfo.focalLength, prompt: "80mm")

                VStack(alignment: .leading, spacing: 6) {
                    Text(language.text("capturedAt"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    DatePicker(
                        "",
                        selection: capturedAtBinding,
                        displayedComponents: [.date]
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                }

                LocationPickerField(
                    title: language.text("location"),
                    text: frame.captureInfo.location,
                    placeholder: language.text("choosePhotoLocation"),
                    coordinate: locationCoordinate
                ) {
                    isLocationSearchPresented = true
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(language.text("notes"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextEditor(text: $frame.captureInfo.notes)
                        .font(.system(size: 13))
                        .scrollContentBackground(.hidden)
                        .padding(6)
                        .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 7))
                        .overlay {
                            RoundedRectangle(cornerRadius: 7)
                                .strokeBorder(.quaternary, lineWidth: 1)
                        }
                        .frame(minHeight: 92)
                }
            }

            Spacer()
        }
        .padding(18)
        .frame(width: 268)
        .sheet(isPresented: $isLocationSearchPresented) {
            LocationSelectionSheet(captureInfo: $frame.captureInfo)
        }
    }

    private var locationCoordinate: CLLocationCoordinate2D? {
        guard let latitude = frame.captureInfo.locationLatitude,
              let longitude = frame.captureInfo.locationLongitude else {
            return nil
        }

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private static let captureDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let legacyCaptureDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
}

private struct InfoField: View {
    let title: String
    @Binding var text: String
    let prompt: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField(prompt, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

private struct LocationPickerField: View {
    let title: String
    let text: String
    let placeholder: String
    let coordinate: CLLocationCoordinate2D?
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let coordinate {
                Button(action: action) {
                    LocationMapPreview(
                        title: text.isEmpty ? placeholder : text,
                        coordinate: coordinate
                    )
                }
                .buttonStyle(.plain)
            } else {
                Button(action: action) {
                    HStack(spacing: 8) {
                        Text(text.isEmpty ? placeholder : text)
                            .foregroundStyle(text.isEmpty ? .secondary : .primary)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "map")
                            .foregroundStyle(.secondary)
                    }
                    .font(.system(size: 13))
                    .padding(.horizontal, 8)
                    .frame(height: 24)
                    .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(.quaternary, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct LocationMapPreview: View {
    let title: String
    let coordinate: CLLocationCoordinate2D

    private var mapPosition: Binding<MapCameraPosition> {
        .constant(
            .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
                )
            )
        )
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Map(position: mapPosition) {
                Marker(title, coordinate: coordinate)
                    .tint(.black)
            }
            .mapStyle(.standard(elevation: .flat))
            .allowsHitTesting(false)

            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .padding(10)
        }
        .frame(height: 118)
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .strokeBorder(.quaternary, lineWidth: 1)
        }
    }
}

private struct LocationSelectionSheet: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.dismiss) private var dismiss
    @Binding var captureInfo: PhotoCaptureInfo
    @State private var position: MapCameraPosition
    @State private var selectedCoordinate: CLLocationCoordinate2D
    @State private var cameraCenter: CLLocationCoordinate2D
    @State private var selectedLocationName: String
    @State private var query: String
    @State private var results: [LocationSearchResult] = []
    @State private var isSearching = false
    @State private var isResolvingLocation = false
    @State private var errorMessage: String?

    init(captureInfo: Binding<PhotoCaptureInfo>) {
        _captureInfo = captureInfo
        let initialCoordinate = CLLocationCoordinate2D(
            latitude: captureInfo.wrappedValue.locationLatitude ?? 51.5074,
            longitude: captureInfo.wrappedValue.locationLongitude ?? -0.1278
        )
        _position = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: initialCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.035, longitudeDelta: 0.035)
                )
            )
        )
        _selectedCoordinate = State(initialValue: initialCoordinate)
        _cameraCenter = State(initialValue: initialCoordinate)
        _selectedLocationName = State(initialValue: captureInfo.wrappedValue.location)
        _query = State(initialValue: captureInfo.wrappedValue.location)
    }

    var body: some View {
        ZStack {
            Map(position: $position) {
                Marker(
                    selectedLocationName.isEmpty ? language.text("selectedLocation") : selectedLocationName,
                    coordinate: selectedCoordinate
                )
                .tint(.black)
            }
            .mapStyle(.standard(elevation: .flat))
            .onMapCameraChange(frequency: .continuous) { context in
                cameraCenter = context.region.center
            }

            Circle()
                .fill(.black)
                .stroke(.white, lineWidth: 4)
                .frame(width: 24, height: 24)
                .shadow(radius: 5, y: 2)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(width: 48, height: 48)
                            .background(.regularMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)

                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField(language.text("searchLocationPlaceholder"), text: $query)
                            .textFieldStyle(.plain)
                        if isSearching {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)
                    .frame(height: 46)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                    } else if !results.isEmpty {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(results) { result in
                                    Button {
                                        selectSearchResult(result)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(result.title)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundStyle(.primary)
                                            if !result.subtitle.isEmpty {
                                                Text(result.subtitle)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 9)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)

                                    if result.id != results.last?.id {
                                        Divider()
                                            .padding(.leading, 14)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 190)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 58)
                .padding(.top, 92)

                Spacer()

                VStack(spacing: 18) {
                    Text(locationStatusText)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity)

                    Button {
                        Task {
                            await commitSelectedLocation()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if isResolvingLocation {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                            }
                            Text(language.text("shotHere"))
                                .font(.system(size: 20, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 68)
                        .background(.black, in: RoundedRectangle(cornerRadius: 28))
                    }
                    .buttonStyle(.plain)
                    .disabled(isResolvingLocation)

                    Button(language.text("clearLocation")) {
                        captureInfo.location = ""
                        captureInfo.locationLatitude = nil
                        captureInfo.locationLongitude = nil
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .disabled(!captureInfo.hasLocationCoordinate && captureInfo.location.isEmpty)
                }
                .padding(26)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30))
                .padding(.horizontal, 58)
                .padding(.bottom, 34)
            }
        }
        .frame(width: 650, height: 760)
        .task(id: query) {
            await searchLocations(for: query)
        }
    }

    private var locationStatusText: String {
        if isResolvingLocation {
            return language.text("gettingLocation")
        }

        if !selectedLocationName.isEmpty {
            return selectedLocationName
        }

        return language.text("mapCenterLocation")
    }

    private func selectSearchResult(_ result: LocationSearchResult) {
        selectedLocationName = result.displayName
        selectedCoordinate = result.coordinate
        cameraCenter = result.coordinate
        results = []
        query = result.displayName

        withAnimation(.snappy(duration: 0.35)) {
            position = .region(
                MKCoordinateRegion(
                    center: result.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
                )
            )
        }
    }

    private func commitSelectedLocation() async {
        isResolvingLocation = true
        let coordinate = cameraCenter
        let resolvedName = await reverseGeocode(coordinate)
        captureInfo.location = resolvedName ?? selectedLocationName.ifEmpty(coordinate.locationLabel)
        captureInfo.locationLatitude = coordinate.latitude
        captureInfo.locationLongitude = coordinate.longitude
        isResolvingLocation = false
        dismiss()
    }

    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async -> String? {
        do {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let placemark = try await CLGeocoder().reverseGeocodeLocation(location).first
            return LocationSearchResult.displayName(
                name: placemark?.name,
                locality: placemark?.locality,
                administrativeArea: placemark?.administrativeArea,
                country: placemark?.country
            )
        } catch {
            return nil
        }
    }

    private func searchLocations(for query: String) async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            results = []
            errorMessage = nil
            isSearching = false
            return
        }

        do {
            isSearching = true
            errorMessage = nil
            try await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = trimmedQuery
            let response = try await MKLocalSearch(request: request).start()
            guard !Task.isCancelled else { return }

            results = response.mapItems.prefix(12).map(LocationSearchResult.init)
            isSearching = false
        } catch is CancellationError {
            isSearching = false
        } catch {
            results = []
            errorMessage = error.localizedDescription
            isSearching = false
        }
    }
}

private struct LocationSearchResult: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D

    var displayName: String {
        subtitle.isEmpty ? title : "\(title), \(subtitle)"
    }

    init(mapItem: MKMapItem) {
        title = mapItem.name ?? ""
        coordinate = mapItem.placemark.coordinate
        subtitle = Self.displayName(
            name: nil,
            locality: mapItem.placemark.locality,
            administrativeArea: mapItem.placemark.administrativeArea,
            country: mapItem.placemark.country
        )
    }

    static func displayName(
        name: String?,
        locality: String?,
        administrativeArea: String?,
        country: String?
    ) -> String {
        [
            name,
            locality,
            administrativeArea,
            country
        ]
        .compactMap { value in
            let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedValue?.isEmpty == false ? trimmedValue : nil
        }
        .reduce(into: [String]()) { uniqueValues, value in
            if !uniqueValues.contains(value) {
                uniqueValues.append(value)
            }
        }
        .joined(separator: ", ")
    }
}

private extension CLLocationCoordinate2D {
    var locationLabel: String {
        String(format: "%.5f, %.5f", latitude, longitude)
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
