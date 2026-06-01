//
//  AppSettings.swift
//  Film-Converter
//

import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case zhHans
    case en

    var id: String { rawValue }

    var title: String {
        switch self {
        case .zhHans:
            "中文"
        case .en:
            "English"
        }
    }

    func text(_ key: String) -> String {
        Self.translations[rawValue]?[key] ?? Self.translations[Self.zhHans.rawValue]?[key] ?? key
    }

    private static let translations: [String: [String: String]] = [
        "zhHans": [
            "settings": "设置",
            "close": "关闭",
            "cancel": "取消",
            "delete": "删除",
            "done": "完成",
            "ok": "好",
            "add": "添加",
            "appearance": "外观",
            "processing": "图像处理",
            "library": "图库",
            "pageUI": "页面 UI",
            "appearanceMode": "外观",
            "language": "语言",
            "lightMode": "白天模式",
            "darkMode": "夜间模式",
            "lightDescription": "白底黑字，蓝色按钮。",
            "darkDescription": "黑底白字，橙色按钮。",
            "currentAccentColor": "当前强调色",
            "processingPlaceholderTitle": "图像处理",
            "processingPlaceholderMessage": "后续的默认去色罩、裁切和导出参数会放在这里。",
            "libraryPlaceholderTitle": "图库",
            "libraryPlaceholderMessage": "后续的导入位置、缓存和胶卷库管理会放在这里。",
            "deleteRollTitle": "删除胶卷？",
            "deleteRollMessage": "这会删除这卷胶卷和其中的照片记录。",
            "addRoll": "添加胶卷",
            "editRoll": "编辑胶卷",
            "deleteRoll": "删除胶卷",
            "rolls": "胶卷",
            "emptyLibraryMessage": "还没有胶卷。点击左侧加号新建一卷胶卷。",
            "toggleAppearance": "切换白天/夜间模式",
            "basicParameters": "基本参数",
            "filmModel": "胶卷型号",
            "cameraModel": "相机型号",
            "notSelected": "未选择",
            "frameSize": "尺寸",
            "shootingInfo": "拍摄信息",
            "usedISO": "使用的 ISO",
            "notes": "备注",
            "photoInfo": "照片信息",
            "aperture": "光圈",
            "shutterSpeed": "快门速度",
            "exposureCompensation": "曝光补偿",
            "focalLength": "焦距",
            "capturedAt": "拍摄时间",
            "location": "拍摄地点",
            "backHome": "返回首页",
            "import": "导入",
            "importPhotos": "导入照片",
            "deletePhoto": "删除照片",
            "deletePhotosFormat": "删除 %d 张照片",
            "deleteSelectedPhoto": "删除已选照片",
            "deleteSelectedPhotosFormat": "删除 %d 张已选照片",
            "importPhotosHelp": "从文件夹导入照片",
            "export": "导出",
            "scannedFramesFormat": "%d 张扫描底片",
            "framesCountFormat": "%d 张",
            "dragPhotosHere": "拖动照片到这里",
            "emptyRollMessage": "支持 1 张或多张照片，也可以点击下方按钮选择文件。",
            "uploadPhotos": "上传照片",
            "crop": "裁切",
            "invert": "反转",
            "cropSubtitle": "调整照片比例、裁切范围和画面位置",
            "ratio": "比例",
            "transform": "变换",
            "flipHorizontal": "左右镜像",
            "flipVertical": "上下镜像",
            "rotateLeft90": "逆时针 90",
            "rotateRight90": "顺时针 90",
            "confirmCrop": "回车确认裁切",
            "cropHint": "拖动照片上的白色框选择保留范围，框外灰色区域会被裁掉。",
            "resetCrop": "重置裁切",
            "maskRemoval": "去色罩",
            "maskRemovalSubtitle": "反转负片并校正胶片底色",
            "processingState": "处理中",
            "runMaskRemoval": "执行去色罩",
            "temperature": "色温",
            "tint": "色调",
            "exposure": "曝光度",
            "contrast": "对比度",
            "highlights": "高光",
            "shadows": "阴影",
            "whiteLevel": "白色色阶",
            "blackLevel": "黑色色阶",
            "vibrance": "鲜艳度",
            "saturation": "饱和度",
            "colorAdjust": "调色",
            "exportPhoto": "导出照片",
            "exportFailed": "导出失败",
            "file": "文件",
            "fileName": "文件名",
            "format": "格式",
            "chooseExportLocation": "选择导出位置",
            "choose": "选择",
            "noExportLocation": "未选择导出位置",
            "chooseLocation": "选择位置",
            "choosePhotoLocation": "选择拍摄地点",
            "searchLocation": "搜索地点",
            "searchLocationPlaceholder": "搜索城市、地点或地址",
            "searchLocationDescription": "使用 Apple 地图搜索并选择照片的拍摄地点。",
            "noLocationResults": "没有找到地点",
            "locationSearchFailed": "地点搜索失败",
            "clearLocation": "清除地点",
            "selectedLocation": "选定地点",
            "mapCenterLocation": "拖动地图选择拍摄地点",
            "gettingLocation": "正在获取位置...",
            "shotHere": "在这里拍摄",
            "image": "图像",
            "includeEdits": "包含当前裁切、旋转和调色",
            "addFilmBorder": "添加胶片框框",
            "addPhotoInfo": "添加相片信息",
            "quality": "质量",
            "jpegQualityFormat": "JPEG 质量：%d",
            "preview": "预览",
            "filmBaseStyleFormat": "%@ 片基样式",
            "photoOnly": "仅导出照片",
            "renderExportFailed": "无法渲染导出的照片。"
        ],
        "en": [
            "settings": "Settings",
            "close": "Close",
            "cancel": "Cancel",
            "delete": "Delete",
            "done": "Done",
            "ok": "OK",
            "add": "Add",
            "appearance": "Appearance",
            "processing": "Image Processing",
            "library": "Library",
            "pageUI": "Page UI",
            "appearanceMode": "Appearance",
            "language": "Language",
            "lightMode": "Light Mode",
            "darkMode": "Dark Mode",
            "lightDescription": "White background, black text, blue buttons.",
            "darkDescription": "Black background, white text, orange buttons.",
            "currentAccentColor": "Current accent color",
            "processingPlaceholderTitle": "Image Processing",
            "processingPlaceholderMessage": "Default mask removal, crop, and export settings will live here.",
            "libraryPlaceholderTitle": "Library",
            "libraryPlaceholderMessage": "Import locations, cache settings, and film library management will live here.",
            "deleteRollTitle": "Delete Roll?",
            "deleteRollMessage": "This deletes the roll and its photo records.",
            "addRoll": "Add Roll",
            "editRoll": "Edit Roll",
            "deleteRoll": "Delete Roll",
            "rolls": "Rolls",
            "emptyLibraryMessage": "No rolls yet. Use the plus button in the sidebar to add a roll.",
            "toggleAppearance": "Toggle light/dark mode",
            "basicParameters": "Basic Parameters",
            "filmModel": "Film Stock",
            "cameraModel": "Camera Model",
            "notSelected": "Not Selected",
            "frameSize": "Size",
            "shootingInfo": "Shooting Info",
            "usedISO": "ISO Used",
            "notes": "Notes",
            "photoInfo": "Photo Info",
            "aperture": "Aperture",
            "shutterSpeed": "Shutter Speed",
            "exposureCompensation": "Exposure Compensation",
            "focalLength": "Focal Length",
            "capturedAt": "Capture Time",
            "location": "Location",
            "backHome": "Back to Home",
            "import": "Import",
            "importPhotos": "Import Photos",
            "deletePhoto": "Delete Photo",
            "deletePhotosFormat": "Delete %d Photos",
            "deleteSelectedPhoto": "Delete Selected Photo",
            "deleteSelectedPhotosFormat": "Delete %d Selected Photos",
            "importPhotosHelp": "Import photos from a folder",
            "export": "Export",
            "scannedFramesFormat": "%d scanned frames",
            "framesCountFormat": "%d frames",
            "dragPhotosHere": "Drag Photos Here",
            "emptyRollMessage": "Drop one or more photos, or use the button below to choose files.",
            "uploadPhotos": "Upload Photos",
            "crop": "Crop",
            "invert": "Invert",
            "cropSubtitle": "Adjust aspect ratio, crop area, and image position",
            "ratio": "Ratio",
            "transform": "Transform",
            "flipHorizontal": "Flip Horizontal",
            "flipVertical": "Flip Vertical",
            "rotateLeft90": "Rotate Left 90",
            "rotateRight90": "Rotate Right 90",
            "confirmCrop": "Press Return to confirm crop",
            "cropHint": "Drag the white box over the photo to choose the kept area. The gray area will be cropped out.",
            "resetCrop": "Reset Crop",
            "maskRemoval": "Remove Mask",
            "maskRemovalSubtitle": "Invert the negative and correct the film base color",
            "processingState": "Processing",
            "runMaskRemoval": "Run Mask Removal",
            "temperature": "Temperature",
            "tint": "Tint",
            "exposure": "Exposure",
            "contrast": "Contrast",
            "highlights": "Highlights",
            "shadows": "Shadows",
            "whiteLevel": "Whites",
            "blackLevel": "Blacks",
            "vibrance": "Vibrance",
            "saturation": "Saturation",
            "colorAdjust": "Color",
            "exportPhoto": "Export Photo",
            "exportFailed": "Export Failed",
            "file": "File",
            "fileName": "File Name",
            "format": "Format",
            "chooseExportLocation": "Choose Export Location",
            "choose": "Choose",
            "noExportLocation": "No export location selected",
            "chooseLocation": "Choose Location",
            "choosePhotoLocation": "Choose Capture Location",
            "searchLocation": "Search Location",
            "searchLocationPlaceholder": "Search cities, places, or addresses",
            "searchLocationDescription": "Search Apple Maps and choose the photo capture location.",
            "noLocationResults": "No locations found",
            "locationSearchFailed": "Location Search Failed",
            "clearLocation": "Clear Location",
            "selectedLocation": "Selected Location",
            "mapCenterLocation": "Move the map to choose the capture location",
            "gettingLocation": "Getting location...",
            "shotHere": "Shot Here",
            "image": "Image",
            "includeEdits": "Include current crop, rotation, and color edits",
            "addFilmBorder": "Add Film Border",
            "addPhotoInfo": "Add Photo Info",
            "quality": "Quality",
            "jpegQualityFormat": "JPEG quality: %d",
            "preview": "Preview",
            "filmBaseStyleFormat": "%@ film base style",
            "photoOnly": "Photo only",
            "renderExportFailed": "Could not render the exported photo."
        ]
    ]
}

private struct AppLanguageEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppLanguage.zhHans
}

extension EnvironmentValues {
    var appLanguage: AppLanguage {
        get { self[AppLanguageEnvironmentKey.self] }
        set { self[AppLanguageEnvironmentKey.self] = newValue }
    }
}

enum AppAppearanceMode: String, CaseIterable, Identifiable {
    case light
    case dark

    var id: String { rawValue }

    func title(language: AppLanguage) -> String {
        switch self {
        case .light:
            language.text("lightMode")
        case .dark:
            language.text("darkMode")
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .light:
            .light
        case .dark:
            .dark
        }
    }

    var accentColor: Color {
        switch self {
        case .light:
            .blue
        case .dark:
            .orange
        }
    }

    var surfaceColor: Color {
        switch self {
        case .light:
            .white
        case .dark:
            .black
        }
    }

    var toggleIcon: String {
        switch self {
        case .light:
            "moon.fill"
        case .dark:
            "sun.max.fill"
        }
    }

    var toggled: AppAppearanceMode {
        self == .light ? .dark : .light
    }

    mutating func toggle() {
        self = toggled
    }
}
