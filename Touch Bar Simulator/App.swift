import SwiftUI
import Sparkle
import Defaults
import LaunchAtLogin
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
	private(set) lazy var window: TouchBarWindow = {
		let window = TouchBarWindow()
		window.alphaValue = Defaults[.windowTransparency]
		window.setUp()
		return window
	}()

	private(set) lazy var statusItem: NSStatusItem = {
		let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
		let menu = NSMenu()
		menu.delegate = self
		item.menu = menu
		item.button!.image = .menuBarIcon
		item.button!.toolTip = "Right-click or option-click for menu"
		item.button!.preventsHighlight = true
		return item
	}()

	private lazy var updateController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

	func applicationWillFinishLaunching(_ notification: Notification) {
		UserDefaults.standard.register(defaults: [
			"NSApplicationCrashOnExceptions": true
		])
	}

	func applicationDidFinishLaunching(_ notification: Notification) {
		checkAccessibilityPermission()
		_ = updateController
		_ = window
		_ = statusItem

		KeyboardShortcuts.onKeyUp(for: .toggleTouchBar) { [self] in
			toggleView()
		}
	}

	func checkAccessibilityPermission() {
		// We intentionally don't use the system prompt as our dialog explains it better.
		let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false] as CFDictionary
		if AXIsProcessTrustedWithOptions(options) {
			return
		}

		"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility".openUrl()

		let alert = NSAlert()
		alert.messageText = "Touch Bar Simulator Reborn needs accessibility access."
		alert.informativeText = "In the System Preferences window that just opened, find “Touch Bar Simulator Reborn” in the list and check its checkbox. Then click the “Continue” button here."
		alert.addButton(withTitle: "Continue")
		alert.addButton(withTitle: "Quit")

		guard alert.runModal() == .alertFirstButtonReturn else {
			SSApp.quit()
			return
		}

		SSApp.relaunch()
	}

	@objc
	func captureScreenshot() {
		let KEY_6: CGKeyCode = 0x58
		pressKey(keyCode: KEY_6, flags: [.maskShift, .maskCommand])
	}

	func toggleView() {
		window.setIsVisible(!window.isVisible)
	}
}

extension AppDelegate: NSMenuDelegate {
	private func update(menu: NSMenu) {
		menu.removeAllItems()

		guard statusItemShouldShowMenu() else {
			return
		}

		menu.addItem(NSMenuItem(title: "Docking", action: nil, keyEquivalent: ""))
		var statusMenuDockingItems: [NSMenuItem] = []
		statusMenuDockingItems.append(NSMenuItem("Floating").bindChecked(to: .windowDocking, value: .floating))
		statusMenuDockingItems.append(NSMenuItem("Docked to Top").bindChecked(to: .windowDocking, value: .dockedToTop))
		statusMenuDockingItems.append(NSMenuItem("Docked to Bottom").bindChecked(to: .windowDocking, value: .dockedToBottom))
		for item in statusMenuDockingItems {
			item.indentationLevel = 1
		}
		menu.items.append(contentsOf: statusMenuDockingItems)

		func sliderMenuItem(_ title: String, boundTo key: Defaults.Key<Double>, min: Double, max: Double, format: String = "%.2f") -> NSMenuItem {
			let menuItem = NSMenuItem(title)
			let sliderView = MenuSliderView(key: key, min: min, max: max, format: format)
			menuItem.view = sliderView
			return menuItem
		}

		if Defaults[.windowDocking] != .floating {
			menu.addItem(NSMenuItem("Padding"))
			menu.addItem(sliderMenuItem("Padding", boundTo: .windowPadding, min: 0.0, max: 120.0, format: "%.1f"))
		}

		menu.addItem(NSMenuItem("Scale"))
		menu.addItem(sliderMenuItem("Scale", boundTo: .windowScale, min: 0.5, max: 2.0, format: "%.2f"))

		menu.addItem(NSMenuItem.separator())

		// Mac Model Information
		let macInfo = window.getCurrentMacInfo()
		let modelInfoItem = NSMenuItem("Mac Model")
		let modelLabel = NSTextField(labelWithString: "Detected: \(macInfo.model)")
		modelLabel.font = NSFont.systemFont(ofSize: 11)
		modelLabel.alignment = NSTextAlignment.left
		modelInfoItem.view = modelLabel
		menu.addItem(modelInfoItem)

		let physicalMatchingItem = NSMenuItem("Match Physical Size").bindState(to: .usePhysicalModelMatching)
		menu.addItem(physicalMatchingItem)

		let maintainPhysicalItem = NSMenuItem("Maintain Size on Resolution Change").bindState(to: .maintainPhysicalSize)
		menu.addItem(maintainPhysicalItem)

		menu.addItem(NSMenuItem.separator())

		menu.addItem(NSMenuItem("Opacity"))
		menu.addItem(sliderMenuItem("Opacity", boundTo: .windowTransparency, min: 0.5, max: 1.0, format: "%.2f"))

		menu.addItem(NSMenuItem("Hide duration"))
		menu.addItem(sliderMenuItem("Hide duration", boundTo: .windowHideDuration, min: 1.0, max: 30.0, format: "%.1f"))

		menu.addItem(NSMenuItem("Physical Dimensions"))
		menu.addItem(sliderMenuItem("Frame Inset", boundTo: .touchBarInset, min: 0.0, max: 10.0, format: "%.1f"))
		menu.addItem(sliderMenuItem("Touch ID Diameter", boundTo: .touchIdDiameter, min: 5.0, max: 20.0, format: "%.1f"))
		menu.addItem(sliderMenuItem("Touch ID Margin", boundTo: .touchIdMargin, min: 0.0, max: 15.0, format: "%.1f"))
		menu.addItem(sliderMenuItem("Corner Radius", boundTo: .cornerRadius, min: 0.0, max: 10.0, format: "%.1f"))

		menu.addItem(NSMenuItem.separator())

		menu.addItem(NSMenuItem("Capture Screenshot", keyEquivalent: "6", keyModifiers: [.shift, .command]) { [self] _ in
			captureScreenshot()
		})

		menu.addItem(NSMenuItem.separator())

		menu.addItem(NSMenuItem("Show on All Desktops").bindState(to: .showOnAllDesktops))

		menu.addItem(NSMenuItem("Hide and Show Automatically").bindState(to: .dockBehavior))

		menu.addItem(NSMenuItem("Launch at Login", isChecked: LaunchAtLogin.isEnabled) { item in
			item.isChecked.toggle()
			LaunchAtLogin.isEnabled = item.isChecked
		})

		menu.addItem(NSMenuItem("Keyboard Shortcuts…") { [self] _ in
			guard let button = statusItem.button else {
				return
			}
			let popover = NSPopover()
			popover.contentViewController = NSHostingController(rootView: KeyboardShortcutsView())
			popover.behavior = .transient
			popover.show(relativeTo: button.frame, of: button, preferredEdge: .maxY)
		})

		menu.addItem(NSMenuItem("Relaunch Touch Bar Simulator Reborn") { _ in
			SSApp.relaunch()
		})

		menu.addItem(NSMenuItem.separator())

		menu.addItem(NSMenuItem("Quit Touch Bar Simulator Reborn", keyEquivalent: "q") { _ in
			NSApp.terminate(nil)
		})
	}

	private func statusItemShouldShowMenu() -> Bool {
		!NSApp.isLeftMouseDown || NSApp.isOptionKeyDown
	}

	func menuNeedsUpdate(_ menu: NSMenu) {
		update(menu: menu)
	}

	func menuWillOpen(_ menu: NSMenu) {
		let shouldShowMenu = statusItemShouldShowMenu()

		statusItem.button!.preventsHighlight = !shouldShowMenu
		if !shouldShowMenu {
			statusItemButtonClicked()
		}
	}

	private func statusItemButtonClicked() {
		// When the user explicitly wants the Touch Bar to appear then `dockBahavior` should be disabled.
		// This is also how the macOS Dock behaves.
		Defaults[.dockBehavior] = false

		toggleView()

		if window.isVisible {
			window.orderFront(self)
		}
	}
}

private final class MenuSliderView: NSView {
	private let slider: MenubarSlider
	private let valueField: NSTextField
	private let key: Defaults.Key<Double>
	private let format: String

	init(key: Defaults.Key<Double>, min: Double, max: Double, format: String = "%.2f") {
		self.slider = MenubarSlider().alwaysRedisplayOnValueChanged()
		self.valueField = NSTextField(frame: .zero)
		self.key = key
		self.format = format

		super.init(frame: CGRect(x: 0, y: 0, width: 260, height: 24))

		slider.minValue = min
		slider.maxValue = max
		slider.bindDoubleValue(to: key)
		slider.addAction { [weak self] sender in
			guard let self = self
				else { return }
			self.valueField.stringValue = String(format: self.format, sender.doubleValue)
		}

		valueField.font = .systemFont(ofSize: 11)
		valueField.alignment = .right
		valueField.isBezeled = true
		valueField.isEditable = true
		valueField.isBordered = true
		valueField.wantsLayer = true
		valueField.layer?.cornerRadius = 4
		valueField.target = self
		valueField.action = #selector(Self.valueFieldChanged(_:))
		valueField.stringValue = String(format: format, Defaults[key])

		Defaults.observe(key) { [weak self] change in
			guard let self = self
				else { return }
			self.slider.doubleValue = change.newValue
			self.valueField.stringValue = String(format: self.format, change.newValue)
		}
		.tieToLifetime(of: self)

		addSubview(slider)
		addSubview(valueField)

		slider.translatesAutoresizingMaskIntoConstraints = false
		valueField.translatesAutoresizingMaskIntoConstraints = false

		NSLayoutConstraint.activate([
			slider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
			slider.centerYAnchor.constraint(equalTo: centerYAnchor),
			slider.trailingAnchor.constraint(equalTo: valueField.leadingAnchor, constant: -8),
			slider.heightAnchor.constraint(equalToConstant: 12),

			valueField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
			valueField.centerYAnchor.constraint(equalTo: centerYAnchor),
			valueField.widthAnchor.constraint(equalToConstant: 46),
			valueField.heightAnchor.constraint(equalToConstant: 18)
		])
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	@objc private func valueFieldChanged(_ sender: NSTextField) {
		let parsed = Double(sender.stringValue) ?? slider.doubleValue
		let normalized = min(max(parsed, slider.minValue), slider.maxValue)
		Defaults[key] = normalized
		slider.doubleValue = normalized
		sender.stringValue = String(format: format, normalized)
	}
}
