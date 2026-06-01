//
//  FilmDatabase.swift
//  Film-Converter
//

import Foundation
import SQLite3
import SwiftUI

enum FilmDatabase {
    private static let filmStockColumns = """
        model TEXT PRIMARY KEY,
        maker TEXT NOT NULL,
        accent_name TEXT NOT NULL,
        display_order INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
    """

    private static let cameraModelColumns = """
        name TEXT PRIMARY KEY,
        display_order INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
    """

    private static let filmFormatColumns = """
        name TEXT PRIMARY KEY,
        display_order INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
    """

    private static let frameSizeColumns = """
        name TEXT PRIMARY KEY,
        format_name TEXT,
        display_order INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
    """

    private static let rollColumns = """
        id TEXT PRIMARY KEY,
        display_order INTEGER NOT NULL,
        name TEXT NOT NULL,
        stock TEXT NOT NULL,
        frame_count INTEGER NOT NULL,
        date_text TEXT NOT NULL,
        camera_model TEXT,
        format TEXT NOT NULL,
        frame_size TEXT NOT NULL,
        iso INTEGER,
        notes TEXT NOT NULL
    """

    private static let frameColumns = """
        id TEXT PRIMARY KEY,
        roll_id TEXT NOT NULL,
        display_order INTEGER NOT NULL,
        number INTEGER NOT NULL,
        title TEXT NOT NULL,
        exposure TEXT NOT NULL,
        image_url TEXT,
        processed_image_url TEXT,
        iso TEXT NOT NULL,
        aperture TEXT NOT NULL,
        shutter_speed TEXT NOT NULL,
        exposure_compensation TEXT NOT NULL,
        focal_length TEXT NOT NULL,
        captured_at TEXT NOT NULL,
        location TEXT NOT NULL,
        location_latitude REAL,
        location_longitude REAL,
        notes TEXT NOT NULL,
        is_inverted INTEGER NOT NULL,
        crop_aspect_ratio TEXT NOT NULL,
        crop_x REAL NOT NULL,
        crop_y REAL NOT NULL,
        crop_width REAL NOT NULL,
        crop_height REAL NOT NULL,
        flip_h INTEGER NOT NULL,
        flip_v INTEGER NOT NULL,
        rotation_degrees INTEGER NOT NULL,
        mask_has_estimated_white_balance INTEGER NOT NULL,
        mask_base_temperature REAL NOT NULL,
        mask_base_tint REAL NOT NULL,
        mask_temperature REAL NOT NULL,
        mask_tint REAL NOT NULL,
        mask_exposure REAL NOT NULL,
        mask_contrast REAL NOT NULL,
        mask_highlights REAL NOT NULL,
        mask_shadows REAL NOT NULL,
        mask_white_level REAL NOT NULL,
        mask_black_level REAL NOT NULL,
        mask_vibrance REAL NOT NULL,
        mask_saturation REAL NOT NULL,
        mask_last_error TEXT,
        FOREIGN KEY(roll_id) REFERENCES film_rolls(id) ON DELETE CASCADE
    """

    static func load() -> [FilmRoll] {
        withDatabase { database in
            createSchema(in: database)
            let rolls = fetchRolls(from: database)
            let framesByRollID = fetchFrames(from: database)
            return rolls.map { roll in
                var updatedRoll = roll
                updatedRoll.frames = framesByRollID[roll.id] ?? []
                updatedRoll.frameCount = updatedRoll.frames.count
                return updatedRoll
            }
        } ?? []
    }

    static func loadCatalog() -> FilmCatalog {
        withDatabase { database in
            createSchema(in: database)
            return FilmCatalog(
                stocks: fetchFilmStocks(from: database),
                cameraModels: fetchCameraModels(from: database),
                formats: fetchFilmFormats(from: database),
                frameSizes: fetchFrameSizes(from: database)
            )
        } ?? .empty
    }

    static func replaceAll(with rolls: [FilmRoll]) {
        withDatabase { database in
            createSchema(in: database)
            execute("BEGIN IMMEDIATE TRANSACTION", in: database)
            execute("DELETE FROM film_frames", in: database)
            execute("DELETE FROM film_rolls", in: database)

            for (index, roll) in rolls.enumerated() {
                insert(roll: roll, order: index, into: database)
                for (frameIndex, frame) in roll.frames.enumerated() {
                    insert(frame: frame, rollID: roll.id, order: frameIndex, into: database)
                }
            }

            execute("COMMIT", in: database)
            return ()
        }
    }

    private static func createSchema(in database: OpaquePointer?) {
        execute("PRAGMA foreign_keys = ON", in: database)
        execute("CREATE TABLE IF NOT EXISTS film_stocks (\(filmStockColumns))", in: database)
        execute("CREATE TABLE IF NOT EXISTS camera_models (\(cameraModelColumns))", in: database)
        execute("CREATE TABLE IF NOT EXISTS film_formats (\(filmFormatColumns))", in: database)
        execute("CREATE TABLE IF NOT EXISTS frame_sizes (\(frameSizeColumns))", in: database)
        execute("CREATE TABLE IF NOT EXISTS film_rolls (\(rollColumns))", in: database)
        execute("CREATE TABLE IF NOT EXISTS film_frames (\(frameColumns))", in: database)
        execute("ALTER TABLE film_frames ADD COLUMN location_latitude REAL", in: database)
        execute("ALTER TABLE film_frames ADD COLUMN location_longitude REAL", in: database)
        seedCatalogIfNeeded(in: database)
    }

    private static func fetchRolls(from database: OpaquePointer?) -> [FilmRoll] {
        let sql = """
            SELECT id, name, stock, frame_count, date_text, camera_model, format, frame_size, iso, notes
            FROM film_rolls
            ORDER BY display_order ASC
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            return []
        }
        defer { sqlite3_finalize(statement) }

        var rolls: [FilmRoll] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let stock = text(statement, 2)
            rolls.append(
                FilmRoll(
                    id: UUID(uuidString: text(statement, 0)) ?? UUID(),
                    name: text(statement, 1),
                    stock: stock,
                    frameCount: int(statement, 3),
                    date: text(statement, 4),
                    accent: accent(for: stock, in: database),
                    frames: [],
                    cameraModel: optionalText(statement, 5),
                    format: text(statement, 6),
                    frameSize: text(statement, 7),
                    iso: optionalInt(statement, 8),
                    notes: text(statement, 9)
                )
            )
        }
        return rolls
    }

    private static func fetchFrames(from database: OpaquePointer?) -> [UUID: [FilmFrame]] {
        let sql = """
            SELECT id, roll_id, number, title, exposure, image_url, processed_image_url,
                   iso, aperture, shutter_speed, exposure_compensation, focal_length,
                   captured_at, location, location_latitude, location_longitude, notes,
                   is_inverted, crop_aspect_ratio, crop_x,
                   crop_y, crop_width, crop_height, flip_h, flip_v, rotation_degrees,
                   mask_has_estimated_white_balance, mask_base_temperature, mask_base_tint,
                   mask_temperature, mask_tint, mask_exposure, mask_contrast,
                   mask_highlights, mask_shadows, mask_white_level, mask_black_level,
                   mask_vibrance, mask_saturation, mask_last_error
            FROM film_frames
            ORDER BY display_order ASC
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            return [:]
        }
        defer { sqlite3_finalize(statement) }

        var framesByRollID: [UUID: [FilmFrame]] = [:]
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let rollID = UUID(uuidString: text(statement, 1)) else {
                continue
            }

            var frame = FilmFrame(
                id: UUID(uuidString: text(statement, 0)) ?? UUID(),
                number: int(statement, 2),
                title: text(statement, 3),
                exposure: text(statement, 4),
                palette: [.gray, .black, .white],
                imageURL: optionalText(statement, 5).flatMap(URL.init(string:)),
                captureInfo: PhotoCaptureInfo(
                    iso: text(statement, 7),
                    aperture: text(statement, 8),
                    shutterSpeed: text(statement, 9),
                    exposureCompensation: text(statement, 10),
                    focalLength: text(statement, 11),
                    capturedAt: text(statement, 12),
                    location: text(statement, 13),
                    locationLatitude: optionalDouble(statement, 14),
                    locationLongitude: optionalDouble(statement, 15),
                    notes: text(statement, 16)
                )
            )

            frame.editSettings.maskRemoval.processedImageURL = optionalText(statement, 6).flatMap(URL.init(string:))
            frame.editSettings.isInverted = bool(statement, 17)
            frame.editSettings.crop.aspectRatio = CropAspectRatio(rawValue: text(statement, 18)) ?? .original
            frame.editSettings.crop.selection = NormalizedCropRect(
                x: double(statement, 19),
                y: double(statement, 20),
                width: double(statement, 21),
                height: double(statement, 22)
            )
            frame.editSettings.crop.isFlippedHorizontally = bool(statement, 23)
            frame.editSettings.crop.isFlippedVertically = bool(statement, 24)
            frame.editSettings.crop.rotationDegrees = int(statement, 25)
            frame.editSettings.maskRemoval.hasEstimatedWhiteBalance = bool(statement, 26)
            frame.editSettings.maskRemoval.baseTemperature = double(statement, 27)
            frame.editSettings.maskRemoval.baseTint = double(statement, 28)
            frame.editSettings.maskRemoval.temperature = double(statement, 29)
            frame.editSettings.maskRemoval.tint = double(statement, 30)
            frame.editSettings.maskRemoval.exposure = double(statement, 31)
            frame.editSettings.maskRemoval.contrast = double(statement, 32)
            frame.editSettings.maskRemoval.highlights = double(statement, 33)
            frame.editSettings.maskRemoval.shadows = double(statement, 34)
            frame.editSettings.maskRemoval.whiteLevel = double(statement, 35)
            frame.editSettings.maskRemoval.blackLevel = double(statement, 36)
            frame.editSettings.maskRemoval.vibrance = double(statement, 37)
            frame.editSettings.maskRemoval.saturation = double(statement, 38)
            frame.editSettings.maskRemoval.lastError = optionalText(statement, 39)
            framesByRollID[rollID, default: []].append(frame)
        }
        return framesByRollID
    }

    private static func insert(roll: FilmRoll, order: Int, into database: OpaquePointer?) {
        let sql = """
            INSERT INTO film_rolls
            (id, display_order, name, stock, frame_count, date_text, camera_model, format, frame_size, iso, notes)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        withPreparedStatement(sql, in: database) { statement in
            bind(roll.id.uuidString, to: statement, at: 1)
            bind(order, to: statement, at: 2)
            bind(roll.name, to: statement, at: 3)
            bind(roll.stock, to: statement, at: 4)
            bind(roll.frameCount, to: statement, at: 5)
            bind(roll.date, to: statement, at: 6)
            bind(roll.cameraModel, to: statement, at: 7)
            bind(roll.format, to: statement, at: 8)
            bind(roll.frameSize, to: statement, at: 9)
            bind(roll.iso, to: statement, at: 10)
            bind(roll.notes, to: statement, at: 11)
            sqlite3_step(statement)
        }
    }

    private static func insert(frame: FilmFrame, rollID: UUID, order: Int, into database: OpaquePointer?) {
        let sql = """
            INSERT INTO film_frames
            (id, roll_id, display_order, number, title, exposure, image_url, processed_image_url,
             iso, aperture, shutter_speed, exposure_compensation, focal_length, captured_at,
             location, location_latitude, location_longitude, notes, is_inverted, crop_aspect_ratio, crop_x, crop_y, crop_width,
             crop_height, flip_h, flip_v, rotation_degrees, mask_has_estimated_white_balance,
             mask_base_temperature, mask_base_tint, mask_temperature, mask_tint, mask_exposure,
             mask_contrast, mask_highlights, mask_shadows, mask_white_level, mask_black_level,
             mask_vibrance, mask_saturation, mask_last_error)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        withPreparedStatement(sql, in: database) { statement in
            bind(frame.id.uuidString, to: statement, at: 1)
            bind(rollID.uuidString, to: statement, at: 2)
            bind(order, to: statement, at: 3)
            bind(frame.number, to: statement, at: 4)
            bind(frame.title, to: statement, at: 5)
            bind(frame.exposure, to: statement, at: 6)
            bind(frame.imageURL?.absoluteString, to: statement, at: 7)
            bind(frame.editSettings.maskRemoval.processedImageURL?.absoluteString, to: statement, at: 8)
            bind(frame.captureInfo.iso, to: statement, at: 9)
            bind(frame.captureInfo.aperture, to: statement, at: 10)
            bind(frame.captureInfo.shutterSpeed, to: statement, at: 11)
            bind(frame.captureInfo.exposureCompensation, to: statement, at: 12)
            bind(frame.captureInfo.focalLength, to: statement, at: 13)
            bind(frame.captureInfo.capturedAt, to: statement, at: 14)
            bind(frame.captureInfo.location, to: statement, at: 15)
            bind(frame.captureInfo.locationLatitude, to: statement, at: 16)
            bind(frame.captureInfo.locationLongitude, to: statement, at: 17)
            bind(frame.captureInfo.notes, to: statement, at: 18)
            bind(frame.editSettings.isInverted, to: statement, at: 19)
            bind(frame.editSettings.crop.aspectRatio.rawValue, to: statement, at: 20)
            bind(frame.editSettings.crop.selection.x, to: statement, at: 21)
            bind(frame.editSettings.crop.selection.y, to: statement, at: 22)
            bind(frame.editSettings.crop.selection.width, to: statement, at: 23)
            bind(frame.editSettings.crop.selection.height, to: statement, at: 24)
            bind(frame.editSettings.crop.isFlippedHorizontally, to: statement, at: 25)
            bind(frame.editSettings.crop.isFlippedVertically, to: statement, at: 26)
            bind(frame.editSettings.crop.rotationDegrees, to: statement, at: 27)
            bind(frame.editSettings.maskRemoval.hasEstimatedWhiteBalance, to: statement, at: 28)
            bind(frame.editSettings.maskRemoval.baseTemperature, to: statement, at: 29)
            bind(frame.editSettings.maskRemoval.baseTint, to: statement, at: 30)
            bind(frame.editSettings.maskRemoval.temperature, to: statement, at: 31)
            bind(frame.editSettings.maskRemoval.tint, to: statement, at: 32)
            bind(frame.editSettings.maskRemoval.exposure, to: statement, at: 33)
            bind(frame.editSettings.maskRemoval.contrast, to: statement, at: 34)
            bind(frame.editSettings.maskRemoval.highlights, to: statement, at: 35)
            bind(frame.editSettings.maskRemoval.shadows, to: statement, at: 36)
            bind(frame.editSettings.maskRemoval.whiteLevel, to: statement, at: 37)
            bind(frame.editSettings.maskRemoval.blackLevel, to: statement, at: 38)
            bind(frame.editSettings.maskRemoval.vibrance, to: statement, at: 39)
            bind(frame.editSettings.maskRemoval.saturation, to: statement, at: 40)
            bind(frame.editSettings.maskRemoval.lastError, to: statement, at: 41)
            sqlite3_step(statement)
        }
    }

    private static func fetchFilmStocks(from database: OpaquePointer?) -> [FilmStock] {
        let sql = """
            SELECT model, maker, accent_name
            FROM film_stocks
            WHERE is_active = 1
            ORDER BY model COLLATE NOCASE ASC
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            return []
        }
        defer { sqlite3_finalize(statement) }

        var stocks: [FilmStock] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            stocks.append(
                FilmStock(
                    model: text(statement, 0),
                    maker: text(statement, 1),
                    accentName: text(statement, 2)
                )
            )
        }
        return stocks
    }

    private static func fetchCameraModels(from database: OpaquePointer?) -> [CameraModelOption] {
        let sql = """
            SELECT name
            FROM camera_models
            WHERE is_active = 1
            ORDER BY display_order ASC, name COLLATE NOCASE ASC
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            return []
        }
        defer { sqlite3_finalize(statement) }

        var models: [CameraModelOption] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            models.append(CameraModelOption(name: text(statement, 0)))
        }
        return models
    }

    private static func fetchFilmFormats(from database: OpaquePointer?) -> [FilmFormatOption] {
        let sql = """
            SELECT name
            FROM film_formats
            WHERE is_active = 1
            ORDER BY display_order ASC, name COLLATE NOCASE ASC
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            return []
        }
        defer { sqlite3_finalize(statement) }

        var formats: [FilmFormatOption] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            formats.append(FilmFormatOption(name: text(statement, 0)))
        }
        return formats
    }

    private static func fetchFrameSizes(from database: OpaquePointer?) -> [FilmFrameSizeOption] {
        let sql = """
            SELECT name, format_name
            FROM frame_sizes
            WHERE is_active = 1
            ORDER BY display_order ASC, name COLLATE NOCASE ASC
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            return []
        }
        defer { sqlite3_finalize(statement) }

        var sizes: [FilmFrameSizeOption] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            sizes.append(
                FilmFrameSizeOption(
                    name: text(statement, 0),
                    formatName: optionalText(statement, 1)
                )
            )
        }
        return sizes
    }

    private static func seedCatalogIfNeeded(in database: OpaquePointer?) {
        if tableCount("film_stocks", in: database) == 0 {
            for (index, seed) in seedFilmStocks.enumerated() {
                let sql = """
                    INSERT OR IGNORE INTO film_stocks
                    (model, maker, accent_name, display_order, is_active)
                    VALUES (?, ?, ?, ?, 1)
                """
                withPreparedStatement(sql, in: database) { statement in
                    bind(seed.model, to: statement, at: 1)
                    bind(seed.maker, to: statement, at: 2)
                    bind(seed.accentName, to: statement, at: 3)
                    bind(index, to: statement, at: 4)
                    sqlite3_step(statement)
                }
            }
        }

        if tableCount("camera_models", in: database) == 0 {
            for (index, name) in seedCameraModels.enumerated() {
                let sql = """
                    INSERT OR IGNORE INTO camera_models
                    (name, display_order, is_active)
                    VALUES (?, ?, 1)
                """
                withPreparedStatement(sql, in: database) { statement in
                    bind(name, to: statement, at: 1)
                    bind(index, to: statement, at: 2)
                    sqlite3_step(statement)
                }
            }
        }

        if tableCount("film_formats", in: database) == 0 {
            for (index, name) in seedFilmFormats.enumerated() {
                let sql = """
                    INSERT OR IGNORE INTO film_formats
                    (name, display_order, is_active)
                    VALUES (?, ?, 1)
                """
                withPreparedStatement(sql, in: database) { statement in
                    bind(name, to: statement, at: 1)
                    bind(index, to: statement, at: 2)
                    sqlite3_step(statement)
                }
            }
        }

        if tableCount("frame_sizes", in: database) == 0 {
            for (index, seed) in seedFrameSizes.enumerated() {
                let sql = """
                    INSERT OR IGNORE INTO frame_sizes
                    (name, format_name, display_order, is_active)
                    VALUES (?, ?, ?, 1)
                """
                withPreparedStatement(sql, in: database) { statement in
                    bind(seed.name, to: statement, at: 1)
                    bind(seed.formatName, to: statement, at: 2)
                    bind(index, to: statement, at: 3)
                    sqlite3_step(statement)
                }
            }
        }
    }

    private static func tableCount(_ table: String, in database: OpaquePointer?) -> Int {
        let sql = "SELECT COUNT(*) FROM \(table)"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            return 0
        }
        defer { sqlite3_finalize(statement) }

        return sqlite3_step(statement) == SQLITE_ROW ? int(statement, 0) : 0
    }

    private static func withDatabase<Result>(_ work: (OpaquePointer?) -> Result) -> Result? {
        try? FileManager.default.createDirectory(
            at: databaseURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        var database: OpaquePointer?
        guard sqlite3_open(databaseURL.path(percentEncoded: false), &database) == SQLITE_OK else {
            return nil
        }
        defer { sqlite3_close(database) }
        return work(database)
    }

    private static var databaseURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL
            .appending(path: "Film-Converter", directoryHint: .isDirectory)
            .appending(path: "FilmLibrary.sqlite")
    }

    private static func withPreparedStatement(_ sql: String, in database: OpaquePointer?, _ work: (OpaquePointer?) -> Void) {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            return
        }
        defer { sqlite3_finalize(statement) }
        work(statement)
    }

    private static func execute(_ sql: String, in database: OpaquePointer?) {
        sqlite3_exec(database, sql, nil, nil, nil)
    }

    private static func bind(_ value: String?, to statement: OpaquePointer?, at index: Int32) {
        guard let value else {
            sqlite3_bind_null(statement, index)
            return
        }
        sqlite3_bind_text(statement, index, value, -1, SQLITE_TRANSIENT)
    }

    private static func bind(_ value: Int?, to statement: OpaquePointer?, at index: Int32) {
        guard let value else {
            sqlite3_bind_null(statement, index)
            return
        }
        sqlite3_bind_int(statement, index, Int32(value))
    }

    private static func bind(_ value: Int, to statement: OpaquePointer?, at index: Int32) {
        sqlite3_bind_int(statement, index, Int32(value))
    }

    private static func bind(_ value: Double, to statement: OpaquePointer?, at index: Int32) {
        sqlite3_bind_double(statement, index, value)
    }

    private static func bind(_ value: Double?, to statement: OpaquePointer?, at index: Int32) {
        guard let value else {
            sqlite3_bind_null(statement, index)
            return
        }
        sqlite3_bind_double(statement, index, value)
    }

    private static func bind(_ value: Bool, to statement: OpaquePointer?, at index: Int32) {
        sqlite3_bind_int(statement, index, value ? 1 : 0)
    }

    private static func text(_ statement: OpaquePointer?, _ index: Int32) -> String {
        guard let cString = sqlite3_column_text(statement, index) else {
            return ""
        }
        return String(cString: cString)
    }

    private static func optionalText(_ statement: OpaquePointer?, _ index: Int32) -> String? {
        sqlite3_column_type(statement, index) == SQLITE_NULL ? nil : text(statement, index)
    }

    private static func int(_ statement: OpaquePointer?, _ index: Int32) -> Int {
        Int(sqlite3_column_int(statement, index))
    }

    private static func optionalInt(_ statement: OpaquePointer?, _ index: Int32) -> Int? {
        sqlite3_column_type(statement, index) == SQLITE_NULL ? nil : int(statement, index)
    }

    private static func double(_ statement: OpaquePointer?, _ index: Int32) -> Double {
        sqlite3_column_double(statement, index)
    }

    private static func optionalDouble(_ statement: OpaquePointer?, _ index: Int32) -> Double? {
        sqlite3_column_type(statement, index) == SQLITE_NULL ? nil : double(statement, index)
    }

    private static func bool(_ statement: OpaquePointer?, _ index: Int32) -> Bool {
        sqlite3_column_int(statement, index) == 1
    }

    private static func accent(for stock: String, in database: OpaquePointer?) -> Color {
        let sql = "SELECT accent_name FROM film_stocks WHERE model = ? LIMIT 1"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            return .accentColor
        }
        defer { sqlite3_finalize(statement) }

        bind(stock, to: statement, at: 1)
        if sqlite3_step(statement) == SQLITE_ROW {
            return FilmStock.color(named: text(statement, 0))
        }

        return .accentColor
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

private let seedFilmStocks: [(model: String, maker: String, accentName: String)] = [
    ("ADOX CHS 100 II", "ADOX", "gray"),
    ("Bergger Pancro 400", "Bergger", "brown"),
    ("Cinestill 50D", "Cinestill", "yellow"),
    ("Cinestill 400D", "Cinestill", "orange"),
    ("Cinestill 800T", "Cinestill", "blue"),
    ("Dubblefilm Apollo", "Dubblefilm", "purple"),
    ("Fomapan 100 Classic", "Foma", "gray"),
    ("Fomapan 400 Action", "Foma", "black"),
    ("Fujifilm C200", "Fujifilm", "green"),
    ("Fujifilm Pro 400H", "Fujifilm", "mint"),
    ("Ilford Delta 100", "Ilford", "gray"),
    ("Ilford HP5 Plus", "Ilford", "black"),
    ("Ilford XP2 Super", "Ilford", "indigo"),
    ("Kentmere Pan 400", "Kentmere", "gray"),
    ("Kodak ColorPlus 200", "Kodak", "yellow"),
    ("Kodak Ektachrome E100", "Kodak", "cyan"),
    ("Kodak Ektar 100", "Kodak", "red"),
    ("Kodak Gold 200", "Kodak", "yellow"),
    ("Kodak Portra 160", "Kodak", "orange"),
    ("Kodak Portra 400", "Kodak", "orange"),
    ("Kodak Portra 800", "Kodak", "pink"),
    ("Kodak Tri-X 400", "Kodak", "black"),
    ("Lomography Color Negative 400", "Lomography", "purple"),
    ("Lomography Metropolis", "Lomography", "brown"),
    ("ORWO Wolfen NC500", "ORWO", "red"),
    ("Rollei Retro 400S", "Rollei", "gray"),
    ("Shanghai GP3 100", "Shanghai", "black"),
    ("Silberra Color 100", "Silberra", "cyan"),
    ("Yodica Andromeda", "Yodica", "purple")
]

private let seedCameraModels = [
    "Hasselblad 501CM",
    "Hasselblad 500CM",
    "Mamiya RB67",
    "Mamiya 7",
    "Pentax 67",
    "Leica M6",
    "Nikon F3",
    "Canon AE-1"
]

private let seedFilmFormats = [
    "35mm",
    "120mm"
]

private let seedFrameSizes: [(name: String, formatName: String?)] = [
    ("35mm", "35mm"),
    ("Half Frame", "35mm"),
    ("XPan / Panoramic", "35mm"),
    ("120mm", "120mm"),
    ("6x4.5", "120mm"),
    ("6x6", "120mm"),
    ("6x7", "120mm"),
    ("6x8", "120mm"),
    ("6x9", "120mm"),
    ("6x12", "120mm"),
    ("6x17", "120mm")
]
