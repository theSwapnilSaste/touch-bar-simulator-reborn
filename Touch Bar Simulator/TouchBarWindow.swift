import Cocoa
import Combine
import Defaults

final class TouchBarWindow: NSPanel {
	private var touchBarView: TouchBarView?
	private var baseTouchBarSize = CGSize.zero
	private var macSpecs = MacSpecifications.current()
	
	// Public accessor for TouchBarView
	var touchBarViewInstance: TouchBarView? {
		touchBarView
	}
	
	// TODO: Migrate this to not use `Codable`.
	enum Docking: String, Codable {
		case floating
		case dockedToTop
		case dockedToBottom

		func dock(window: TouchBarWindow, padding: Double) {
			switch self {
			case .floating:
				window.addTitlebar()
			case .dockedToTop:
				window.removeTitlebar()
			case .dockedToBottom:
				window.removeTitlebar()
			}

			reposition(window: window, padding: padding)
		}

		func reposition(window: NSWindow, padding: Double) {
			switch self {
			case .floating:
				if let prevPosition = Defaults[.lastFloatingPosition] {
					window.setFrameOrigin(prevPosition)
				}
			case .dockedToTop:
				window.moveTo(x: .center, y: .top)
				window.setFrameOrigin(CGPoint(x: window.frame.origin.x, y: window.frame.origin.y - padding))
			case .dockedToBottom:
				window.moveTo(x: .center, y: .bottom)
				window.setFrameOrigin(CGPoint(x: window.frame.origin.x, y: window.frame.origin.y + padding))
			}
		}
	}

	override var canBecomeMain: Bool { false }
	override var canBecomeKey: Bool { false }

	var docking: Docking = .floating {
		didSet {
			if oldValue == .floating, docking != .floating {
				Defaults[.lastFloatingPosition] = frame.origin
			}

			if docking == .floating {
				dockBehavior = false
			}

			// Prevent the Touch Bar from momentarily becoming visible.
			if docking == .floating || !dockBehavior {
				stopDockBehaviorTimer()
				docking.dock(window: self, padding: Defaults[.windowPadding])
				setIsVisible(true)
				orderFront(nil)
				return
			}

			// When docking is set to `dockedToTop` or `dockedToBottom` dockBehavior should start.
			if dockBehavior {
				setIsVisible(false)
				docking.dock(window: self, padding: Defaults[.windowPadding])
				startDockBehaviorTimer()
			}
		}
	}

	var showOnAllDesktops = false {
		didSet {
			if showOnAllDesktops {
				collectionBehavior = .canJoinAllSpaces
			} else {
				collectionBehavior = .moveToActiveSpace
			}
		}
	}

	var dockBehaviorTimer = Timer()
	var showTouchBarTimer = Timer()

	func startDockBehaviorTimer() {
		stopDockBehaviorTimer()

		dockBehaviorTimer = Timer.scheduledTimer(
			timeInterval: 0.1,
			target: self,
			selector: #selector(handleDockBehavior),
			userInfo: nil,
			repeats: true
		)
	}

	func stopDockBehaviorTimer() {
		dockBehaviorTimer.invalidate()
		dockBehaviorTimer = Timer()
	}

	var dockBehavior: Bool = Defaults[.dockBehavior] {
		didSet {
			Defaults[.dockBehavior] = dockBehavior
			if docking == .dockedToBottom || docking == .dockedToTop {
				Defaults[.lastWindowDockingWithDockBehavior] = docking
			}

			if dockBehavior {
				if docking == .dockedToBottom || docking == .dockedToTop {
					docking = Defaults[.lastWindowDockingWithDockBehavior]
					startDockBehaviorTimer()
				} else if docking == .floating {
					Defaults[.windowDocking] = Defaults[.lastWindowDockingWithDockBehavior]
				}
			} else {
				stopDockBehaviorTimer()
				setIsVisible(true)
			}
		}
	}

	@objc
	func activeSpaceDidChange() {
		// When not showing on all desktops, ensure window moves to active space
		if !showOnAllDesktops {
			orderFront(nil)
		}
	}

	@objc
	func handleDockBehavior() {
		guard
			let visibleFrame = NSScreen.main?.visibleFrame,
			let screenFrame = NSScreen.main?.frame
		else {
			return
		}

		var detectionRect = CGRect.zero
		if docking == .dockedToBottom {
			if isVisible {
				detectionRect = CGRect(
					x: 0,
					y: 0,
					width: visibleFrame.width,
					height: frame.height + (screenFrame.height - visibleFrame.height - NSStatusBar.system.thickness + Defaults[.windowPadding])
				)
			} else {
				detectionRect = CGRect(x: 0, y: 0, width: visibleFrame.width, height: 1)
			}
		} else if docking == .dockedToTop {
			if isVisible {
				detectionRect = CGRect(
					x: 0,
					// Without `+ 1`, the Touch Bar would glitch (toggling rapidly).
					y: screenFrame.height - frame.height - NSStatusBar.system.thickness - Defaults[.windowPadding] + 1.0,
					width: visibleFrame.width,
					height: frame.height + NSStatusBar.system.thickness + Defaults[.windowPadding]
				)
			} else {
				detectionRect = CGRect(
					x: 0,
					y: screenFrame.height,
					width: visibleFrame.width,
					height: 1
				)
			}
		}

		let mouseLocation = NSEvent.mouseLocation
		if detectionRect.contains(mouseLocation) {
			dismissAnimationDidRun = false

			guard
				!showTouchBarTimer.isValid,
				!showAnimationDidRun
			else {
				return
			}

			showTouchBarTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
				guard let self = self else {
					return
				}

				self.performActionWithAnimation(action: .show)
				self.showAnimationDidRun = true
			}
		} else {
			showTouchBarTimer.invalidate()
			showTouchBarTimer = Timer()
			showAnimationDidRun = false

			if isVisible, !dismissAnimationDidRun {
				performActionWithAnimation(action: .dismiss)
				dismissAnimationDidRun = true
			}
		}
	}

	var showAnimationDidRun = false
	var dismissAnimationDidRun = false

	func performActionWithAnimation(action: TouchBarAction) {
		guard
			docking == .dockedToTop ||
			docking == .dockedToBottom
		else {
			return
		}

		var endY: Double!

		if action == .show {
			docking.reposition(window: self, padding: -frame.height)
			setIsVisible(true)

			if docking == .dockedToTop {
				endY = frame.minY - frame.height - Defaults[.windowPadding]
			} else if docking == .dockedToBottom {
				endY = frame.minY + frame.height + Defaults[.windowPadding]
			}
		} else if action == .dismiss {
			if docking == .dockedToTop {
				endY = frame.minY + frame.height + NSStatusBar.system.thickness + Defaults[.windowPadding]
			} else if docking == .dockedToBottom {
				endY = 0 - frame.height
			}
		}

		var endFrame = frame
		endFrame.origin.y = endY

		NSAnimationContext.runAnimationGroup({ context in
			context.duration = TimeInterval(0.3)
			animator().setFrame(endFrame, display: false, animate: true)
		}, completionHandler: { [self] in
			if action == .show {
				docking.reposition(window: self, padding: Defaults[.windowPadding])
			} else if action == .dismiss {
				setIsVisible(false)
				docking.reposition(window: self, padding: 0)
			}
		})
	}

	enum TouchBarAction {
		case show
		case dismiss
	}

	func addTitlebar() {
		styleMask.insert(.titled)
		title = "Touch Bar Simulator Reborn"

		guard let toolbarView = toolbarView else {
			return
		}

		toolbarView.addSubviews(
			makeScreenshotButton(toolbarView),
			makeTransparencySlider(toolbarView)
		)
	}

	func removeTitlebar() {
		styleMask.remove(.titled)
	}

	func makeScreenshotButton(_ toolbarView: NSView) -> NSButton {
		let button = NSButton()
		button.image = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: "Capture screenshot of the Touch Bar")
		button.imageScaling = .scaleProportionallyDown
		button.isBordered = false
		button.bezelStyle = .shadowlessSquare
		button.frame = CGRect(x: toolbarView.frame.width - 19, y: 4, width: 16, height: 11)
		button.action = #selector(AppDelegate.captureScreenshot)
		return button
	}

	private var transparencySlider: ToolbarSlider?

	func makeTransparencySlider(_ parentView: NSView) -> ToolbarSlider {
		let slider = ToolbarSlider().alwaysRedisplayOnValueChanged().bindDoubleValue(to: .windowTransparency)
		slider.frame = CGRect(x: parentView.frame.width - 160, y: 1, width: 140, height: 11)
		slider.minValue = 0.5
		return slider
	}

	private var cancellable: AnyCancellable?

	func setUp() {
		let view = contentView!
		view.wantsLayer = true
		view.layer?.backgroundColor = NSColor.black.cgColor

		let touchBarView = TouchBarView()
		self.touchBarView = touchBarView
		
		// Set base size based on physical model matching preference
		if Defaults[.usePhysicalModelMatching] && Defaults[.maintainPhysicalSize] {
			baseTouchBarSize = getPhysicalTouchBarSize()
			// Store the detected model
			Defaults[.detectedMacModel] = macSpecs.displayName
		} else {
			baseTouchBarSize = touchBarView.bounds.size
		}

		let scaledSize = CGSize(
			width: baseTouchBarSize.width * Defaults[.windowScale],
			height: baseTouchBarSize.height * Defaults[.windowScale]
		)

		setContentSize(scaledSize)
		minSize = scaledSize
		view.addSubview(touchBarView)

		touchBarView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			touchBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			touchBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			touchBarView.topAnchor.constraint(equalTo: view.topAnchor),
			touchBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		])

		Defaults.tiedToLifetime(of: self) {
			Defaults.observe(.windowTransparency) { [weak self] change in
				self?.alphaValue = change.newValue
			}
			Defaults.observe(.windowDocking) { [weak self] change in
				self?.docking = change.newValue
			}
			Defaults.observe(.windowPadding) { [weak self] change in
				guard let self = self else {
					return
				}

				self.docking.reposition(window: self, padding: change.newValue)
			}
			Defaults.observe(.windowScale) { [weak self] _ in
				self?.applyWindowScale()
			}
			// TODO: We could maybe simplify this by creating another `Default` extension to bind a default to a KeyPath:
			// `defaults.bind(.showOnAllDesktops, to: \.showOnAllDesktops)`
			Defaults.observe(.showOnAllDesktops) { [weak self] change in
				self?.showOnAllDesktops = change.newValue
			}
			Defaults.observe(.dockBehavior) { [weak self] change in
				self?.dockBehavior = change.newValue
			}
		}

		center()
		setFrameOrigin(CGPoint(x: frame.origin.x, y: 100))

		setFrameUsingName(Constants.windowAutosaveName)
		setFrameAutosaveName(Constants.windowAutosaveName)

		// Observe space changes to ensure window appears on active desktop when not showing on all desktops
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(activeSpaceDidChange),
			name: NSWorkspace.activeSpaceDidChangeNotification,
			object: nil
		)

		// Prevent the Touch Bar from momentarily becoming visible.
		if !dockBehavior {
			orderFront(nil)
		}

		cancellable = NSScreen.publisher.sink { [weak self] in
			guard let self = self else {
				return
			}

			self.docking.reposition(window: self, padding: Defaults[.windowPadding])
		}
	}

	private func applyWindowScale() {
		guard let touchBarView = touchBarView else {
			return
		}

		let scaledSize = CGSize(
			width: baseTouchBarSize.width * Defaults[.windowScale],
			height: baseTouchBarSize.height * Defaults[.windowScale]
		)

		setContentSize(scaledSize)
		minSize = scaledSize
		touchBarView.needsLayout = true
		touchBarView.updateLayout()
		contentView?.layoutSubtreeIfNeeded()
		docking.reposition(window: self, padding: Defaults[.windowPadding])
	}


	convenience init() {
		self.init(
			contentRect: .zero,
			styleMask: [
				.titled,
				.closable,
				.resizable,
				.nonactivatingPanel,
				.hudWindow,
				.utilityWindow
			],
			backing: .buffered,
			defer: false
		)

		self.level = .assistiveTechHigh
		_setPreventsActivation(true)
		self.isRestorable = true
		self.hidesOnDeactivate = false
		self.worksWhenModal = true
		self.acceptsMouseMovedEvents = true
		self.isMovableByWindowBackground = false
	}

	// MARK: - Physical Dimension Helpers

	/// Convert millimeters to screen points accounting for DPI
	/// This ensures 1:1 physical size match regardless of display resolution
	private func millimetersToPoints(_ mm: Double) -> Double {
		// 1 inch = 25.4 mm
		// 1 inch = 72 points (macOS standard)
		let pointsPerMM = Constants.standardDPI / 25.4
		let scalingFactor = MacModelDetector.screenDPI() / Constants.standardDPI
		return (mm * pointsPerMM) * (1.0 / scalingFactor)
	}

	/// Get the physical size of the Touch Bar for the current Mac model
	/// Returns size in screen points that displays at 1:1 physical size
	private func getPhysicalTouchBarSize() -> CGSize {
		if !Defaults[.usePhysicalModelMatching] {
			// Use custom dimensions if physical matching is disabled
			let width = millimetersToPoints(Constants.touchBarPhysicalWidth / 7.8) // ~278mm effective width
			let height = millimetersToPoints(Defaults[.touchBarHeightMM])
			return CGSize(width: width, height: height)
		}

		let specs = macSpecs
		let width = millimetersToPoints(specs.touchBarWidthMM)
		let height = millimetersToPoints(specs.touchBarHeightMM)
		
		return CGSize(width: width, height: height)
	}

	/// Get information about the current Mac model
	func getCurrentMacInfo() -> (model: String, width: Double, height: Double, escapeKey: Bool, specs: MacSpecifications) {
		let specs = macSpecs
		let size = getPhysicalTouchBarSize()
		return (specs.displayName, size.width, size.height, specs.hasPhysicalEscapeKey, specs)
	}
}
