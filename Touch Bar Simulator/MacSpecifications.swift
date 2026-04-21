import Foundation

/// Physical specifications for different Mac models
struct MacSpecifications {
	let modelIdentifier: String
	let displayName: String
	let screenSize: Double // in inches
	let topPanelWidthMM: Double // actual width of top bezel where Touch Bar sits
	let touchBarWidthMM: Double // usable width for Touch Bar content
	let touchBarHeightMM: Double
	let hasPhysicalEscapeKey: Bool
	let hasPhysicalTouchID: Bool
	let speakerLeftMarginMM: Double // from left edge
	let speakerRightMarginMM: Double // from right edge
	let notchWidthMM: Double // width of notch/camera housing if present
	let notchLeftOffsetMM: Double // distance from left edge

	// All dimensions in millimeters
	static let all: [MacSpecifications] = [
		// M3/M4 MacBook Pro 14" - Physical Escape, Touch ID
		MacSpecifications(
			modelIdentifier: "MacBookPro18,1", // 14" M1 Pro/Max
			displayName: "MacBook Pro 14\" (M1 Pro/Max)",
			screenSize: 14,
			topPanelWidthMM: 304, // 14" is ~304mm wide
			touchBarWidthMM: 280, // Account for margins and notch
			touchBarHeightMM: 30,
			hasPhysicalEscapeKey: false,
			hasPhysicalTouchID: true,
			speakerLeftMarginMM: 20,
			speakerRightMarginMM: 20,
			notchWidthMM: 32,
			notchLeftOffsetMM: 136
		),
		MacSpecifications(
			modelIdentifier: "MacBookPro19,1", // 14" M2 Pro/Max
			displayName: "MacBook Pro 14\" (M2 Pro/Max)",
			screenSize: 14,
			topPanelWidthMM: 304,
			touchBarWidthMM: 280,
			touchBarHeightMM: 30,
			hasPhysicalEscapeKey: false,
			hasPhysicalTouchID: true,
			speakerLeftMarginMM: 20,
			speakerRightMarginMM: 20,
			notchWidthMM: 32,
			notchLeftOffsetMM: 136
		),
		MacSpecifications(
			modelIdentifier: "MacBookPro20,1", // 14" M3 Pro/Max
			displayName: "MacBook Pro 14\" (M3 Pro/Max)",
			screenSize: 14,
			topPanelWidthMM: 304,
			touchBarWidthMM: 280,
			touchBarHeightMM: 30,
			hasPhysicalEscapeKey: true, // M3 removed Touch Bar, has physical Escape
			hasPhysicalTouchID: true,
			speakerLeftMarginMM: 20,
			speakerRightMarginMM: 20,
			notchWidthMM: 32,
			notchLeftOffsetMM: 136
		),

		// M3/M4 MacBook Pro 16" - Physical Escape, Touch ID
		MacSpecifications(
			modelIdentifier: "MacBookPro18,2", // 16" M1 Pro/Max
			displayName: "MacBook Pro 16\" (M1 Pro/Max)",
			screenSize: 16,
			topPanelWidthMM: 348, // 16" is ~348mm wide
			touchBarWidthMM: 324, // Wider top panel
			touchBarHeightMM: 30,
			hasPhysicalEscapeKey: false,
			hasPhysicalTouchID: true,
			speakerLeftMarginMM: 28,
			speakerRightMarginMM: 28,
			notchWidthMM: 32,
			notchLeftOffsetMM: 158
		),
		MacSpecifications(
			modelIdentifier: "MacBookPro19,2", // 16" M2 Pro/Max
			displayName: "MacBook Pro 16\" (M2 Pro/Max)",
			screenSize: 16,
			topPanelWidthMM: 348,
			touchBarWidthMM: 324,
			touchBarHeightMM: 30,
			hasPhysicalEscapeKey: false,
			hasPhysicalTouchID: true,
			speakerLeftMarginMM: 28,
			speakerRightMarginMM: 28,
			notchWidthMM: 32,
			notchLeftOffsetMM: 158
		),
		MacSpecifications(
			modelIdentifier: "MacBookPro20,2", // 16" M3 Pro/Max
			displayName: "MacBook Pro 16\" (M3 Pro/Max)",
			screenSize: 16,
			topPanelWidthMM: 348,
			touchBarWidthMM: 324,
			touchBarHeightMM: 30,
			hasPhysicalEscapeKey: true, // M3 has physical Escape
			hasPhysicalTouchID: true,
			speakerLeftMarginMM: 28,
			speakerRightMarginMM: 28,
			notchWidthMM: 32,
			notchLeftOffsetMM: 158
		),
		MacSpecifications(
			modelIdentifier: "MacBookPro21,1", // 14" M4 Pro/Max
			displayName: "MacBook Pro 14\" (M4 Pro/Max)",
			screenSize: 14,
			topPanelWidthMM: 304,
			touchBarWidthMM: 280,
			touchBarHeightMM: 30,
			hasPhysicalEscapeKey: true,
			hasPhysicalTouchID: true,
			speakerLeftMarginMM: 20,
			speakerRightMarginMM: 20,
			notchWidthMM: 32,
			notchLeftOffsetMM: 136
		),
		MacSpecifications(
			modelIdentifier: "MacBookPro21,2", // 16" M4 Pro/Max
			displayName: "MacBook Pro 16\" (M4 Pro/Max)",
			screenSize: 16,
			topPanelWidthMM: 348,
			touchBarWidthMM: 324,
			touchBarHeightMM: 30,
			hasPhysicalEscapeKey: true,
			hasPhysicalTouchID: true,
			speakerLeftMarginMM: 28,
			speakerRightMarginMM: 28,
			notchWidthMM: 32,
			notchLeftOffsetMM: 158
		),

		// MacBook Air 13" and 15" (M2/M3) - Physical Escape, Touch ID
		MacSpecifications(
			modelIdentifier: "MacBookAir10,1", // 13" M2
			displayName: "MacBook Air 13\" (M2)",
			screenSize: 13,
			topPanelWidthMM: 284, // 13" is ~284mm wide
			touchBarWidthMM: 264,
			touchBarHeightMM: 30,
			hasPhysicalEscapeKey: true,
			hasPhysicalTouchID: true,
			speakerLeftMarginMM: 18,
			speakerRightMarginMM: 18,
			notchWidthMM: 32,
			notchLeftOffsetMM: 126
		),
		MacSpecifications(
			modelIdentifier: "MacBookAir11,1", // 13" M3
			displayName: "MacBook Air 13\" (M3)",
			screenSize: 13,
			topPanelWidthMM: 284,
			touchBarWidthMM: 264,
			touchBarHeightMM: 30,
			hasPhysicalEscapeKey: true,
			hasPhysicalTouchID: true,
			speakerLeftMarginMM: 18,
			speakerRightMarginMM: 18,
			notchWidthMM: 32,
			notchLeftOffsetMM: 126
		),
		MacSpecifications(
			modelIdentifier: "MacBookAir10,2", // 15" M2
			displayName: "MacBook Air 15\" (M2)",
			screenSize: 15,
			topPanelWidthMM: 328, // 15" is ~328mm wide
			touchBarWidthMM: 304,
			touchBarHeightMM: 30,
			hasPhysicalEscapeKey: true,
			hasPhysicalTouchID: true,
			speakerLeftMarginMM: 24,
			speakerRightMarginMM: 24,
			notchWidthMM: 32,
			notchLeftOffsetMM: 148
		),
		MacSpecifications(
			modelIdentifier: "MacBookAir11,2", // 15" M3
			displayName: "MacBook Air 15\" (M3)",
			screenSize: 15,
			topPanelWidthMM: 328,
			touchBarWidthMM: 304,
			touchBarHeightMM: 30,
			hasPhysicalEscapeKey: true,
			hasPhysicalTouchID: true,
			speakerLeftMarginMM: 24,
			speakerRightMarginMM: 24,
			notchWidthMM: 32,
			notchLeftOffsetMM: 148
		),

		// Intel MacBook Pro (old Touch Bar models)
		MacSpecifications(
			modelIdentifier: "MacBookPro15,1", // 15" 2019 Intel
			displayName: "MacBook Pro 15\" (2019 Intel)",
			screenSize: 15,
			topPanelWidthMM: 328,
			touchBarWidthMM: 2170 / 7.8, // Original Touch Bar width ~278mm
			touchBarHeightMM: 30,
			hasPhysicalEscapeKey: false,
			hasPhysicalTouchID: true,
			speakerLeftMarginMM: 24,
			speakerRightMarginMM: 24,
			notchWidthMM: 0,
			notchLeftOffsetMM: 0
		),
		MacSpecifications(
			modelIdentifier: "MacBookPro16,1", // 16" 2019 Intel
			displayName: "MacBook Pro 16\" (2019 Intel)",
			screenSize: 16,
			topPanelWidthMM: 348,
			touchBarWidthMM: 2170 / 7.8,
			touchBarHeightMM: 30,
			hasPhysicalEscapeKey: false,
			hasPhysicalTouchID: true,
			speakerLeftMarginMM: 28,
			speakerRightMarginMM: 28,
			notchWidthMM: 0,
			notchLeftOffsetMM: 0
		),

		// Default fallback
		MacSpecifications(
			modelIdentifier: "unknown",
			displayName: "Unknown Mac Model",
			screenSize: 14,
			topPanelWidthMM: 304,
			touchBarWidthMM: 280,
			touchBarHeightMM: 30,
			hasPhysicalEscapeKey: true,
			hasPhysicalTouchID: true,
			speakerLeftMarginMM: 20,
			speakerRightMarginMM: 20,
			notchWidthMM: 32,
			notchLeftOffsetMM: 136
		)
	]

	static func current() -> MacSpecifications {
		let modelId = MacModelDetector.modelIdentifier()
		
		// Try exact match first
		if let spec = all.first(where: { $0.modelIdentifier == modelId }) {
			return spec
		}
		
		// Try partial match (e.g., "MacBookPro20" matches "MacBookPro20,1" and "MacBookPro20,2")
		if let spec = all.first(where: { modelId.hasPrefix($0.modelIdentifier.components(separatedBy: ",")[0]) }) {
			return spec
		}
		
		// Return fallback
		return all.last!
	}
}

/// Utility for detecting Mac model information
struct MacModelDetector {
	static func modelIdentifier() -> String {
		var size: Int = 0
		sysctlbyname("hw.model", nil, &size, nil, 0)
		var model = [CChar](repeating: 0, count: size)
		sysctlbyname("hw.model", &model, &size, nil, 0)
		return String(cString: model)
	}

	static func screenResolution() -> CGSize {
		NSScreen.main?.frame.size ?? CGSize(width: 2560, height: 1600)
	}

	static func screenDPI() -> Double {
		let screens = NSScreen.screens
		guard let mainScreen = screens.first else { return 96 }
		
		// Calculate DPI from screen properties
		let resolution = mainScreen.frame.size
		let deviceDescription = mainScreen.deviceDescription
		
		// Try to get actual screen DPI
		if let screenNumber = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
			let displayID = CGDirectDisplayID(screenNumber.uint32Value)
			let width = CGDisplayScreenSize(displayID).width
			let horizontalPixels = resolution.width
			
			if width > 0 {
				// DPI = pixels / inches
				return (horizontalPixels / width) * 25.4
			}
		}
		
		// Default Retina DPI
		return 220
	}

	/// Get scaling factor to display exact physical size
	/// 1 point = 1/72 inch on macOS standard, but Retina has 2 points = 1 pixel
	static func physicalScalingFactor() -> Double {
		let dpi = screenDPI()
		// 72 DPI is standard macOS, Retina is 144 DPI (2x)
		let pointsPerInch: Double = 72
		return dpi / pointsPerInch
	}
}
