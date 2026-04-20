import Foundation
import Defaults
import KeyboardShortcuts

enum Constants {
	static let windowAutosaveName = "TouchBarWindow"
	
	// Physical Touch Bar dimensions (in mm, used for pixel calculations)
	static let touchBarPhysicalWidth: Double = 2170
	static let touchBarPhysicalHeight: Double = 30
	static let touchBarInset: Double = 2
	static let touchIdDiameter: Double = 10
	static let touchIdMargin: Double = 5
	static let cornerRadius: Double = 3
}

extension Defaults.Keys {
	static let windowTransparency = Key<Double>("windowTransparency", default: 0.75)
	static let windowDocking = Key<TouchBarWindow.Docking>("windowDocking", default: .dockedToBottom)
	static let windowPadding = Key<Double>("windowPadding", default: 0.0)
	static let windowScale = Key<Double>("windowScale", default: 1.0)
	static let windowHideDuration = Key<Double>("windowHideDuration", default: 5.0)
	static let showOnAllDesktops = Key<Bool>("showOnAllDesktops", default: false)
	static let lastFloatingPosition = Key<CGPoint?>("lastFloatingPosition")
	static let dockBehavior = Key<Bool>("dockBehavior", default: false)
	static let lastWindowDockingWithDockBehavior = Key<TouchBarWindow.Docking>("windowDockingWithDockBehavior", default: .dockedToBottom)
}

extension TouchBarWindow.Docking: Defaults.Serializable {}
extension CGPoint: Defaults.Serializable {}

extension KeyboardShortcuts.Name {
	static let toggleTouchBar = Self("toggleTouchBar")
}
