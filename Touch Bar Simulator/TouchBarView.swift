import Cocoa
import Defaults

final class TouchBarView: NSView {
	private var stream: CGDisplayStream?
	private let displayView = NSView()
	private let initialDFRStatus: Int32
	private let frameView = NSView()
	private let touchIdButton = NSButton()
	private let macSpecs = MacSpecifications.current()
	
	// Physical dimensions scaled to pixels (using adjustable defaults or Mac specs)
	private var scaledInset: Double {
		if Defaults[.usePhysicalModelMatching] {
			return Defaults[.touchBarInset] * Defaults[.windowScale]
		}
		return Defaults[.touchBarInset] * Defaults[.windowScale]
	}
	
	private var scaledTouchIdDiameter: Double {
		if Defaults[.usePhysicalModelMatching] {
			// Convert mm to points
			let dpi = MacModelDetector.screenDPI()
			let pointsPerMM = Constants.standardDPI / 25.4
			let scalingFactor = dpi / Constants.standardDPI
			return (macSpecs.touchIdDiameter * pointsPerMM) * (1.0 / scalingFactor) * Defaults[.windowScale]
		}
		return Defaults[.touchIdDiameter] * Defaults[.windowScale]
	}
	
	private var scaledTouchIdMargin: Double {
		if Defaults[.usePhysicalModelMatching] {
			let dpi = MacModelDetector.screenDPI()
			let pointsPerMM = Constants.standardDPI / 25.4
			let scalingFactor = dpi / Constants.standardDPI
			return (macSpecs.touchIdMargin * pointsPerMM) * (1.0 / scalingFactor) * Defaults[.windowScale]
		}
		return Defaults[.touchIdMargin] * Defaults[.windowScale]
	}
	
	private var scaledCornerRadius: Double {
		if Defaults[.usePhysicalModelMatching] {
			let dpi = MacModelDetector.screenDPI()
			let pointsPerMM = Constants.standardDPI / 25.4
			let scalingFactor = dpi / Constants.standardDPI
			return (macSpecs.cornerRadius * pointsPerMM) * (1.0 / scalingFactor) * Defaults[.windowScale]
		}
		return Defaults[.cornerRadius] * Defaults[.windowScale]
	}

	override init(frame: CGRect) {
		self.initialDFRStatus = DFRGetStatus()

		super.init(frame: .zero)

		wantsLayer = true
		layer?.contentsGravity = .resizeAspect
		layer?.needsDisplayOnBoundsChange = true
		
		// Frame view with rounded corners
		frameView.wantsLayer = true
		frameView.layer?.cornerRadius = scaledCornerRadius
		frameView.layer?.borderWidth = 1
		frameView.layer?.borderColor = NSColor.gray.cgColor
		frameView.layer?.backgroundColor = NSColor.black.cgColor
		addSubview(frameView)
		
		// Touch Bar display view
		displayView.wantsLayer = true
		displayView.layer?.contentsGravity = .resizeAspect
		frameView.addSubview(displayView)
		
		// Touch ID button (only on Macs with Touch ID)
		if macSpecs.hasPhysicalTouchID {
			touchIdButton.isBordered = false
			touchIdButton.bezelStyle = .circular
			touchIdButton.image = NSImage(systemSymbolName: "touchid", accessibilityDescription: "Touch ID")
			touchIdButton.imageScaling = .scaleProportionallyUpOrDown
			touchIdButton.target = self
			touchIdButton.action = #selector(touchIdClicked)
			frameView.addSubview(touchIdButton)
		}
		
		start()
		setFrameSize(DFRGetScreenSize())
		updateLayout()
		
		// Observe changes to physical dimensions
		Defaults.observe(.touchBarInset) { [weak self] _ in
			self?.updateLayout()
		}.tieToLifetime(of: self)
		
		Defaults.observe(.touchIdDiameter) { [weak self] _ in
			self?.updateLayout()
		}.tieToLifetime(of: self)
		
		Defaults.observe(.touchIdMargin) { [weak self] _ in
			self?.updateLayout()
		}.tieToLifetime(of: self)
		
		Defaults.observe(.cornerRadius) { [weak self] _ in
			self?.updateLayout()
		}.tieToLifetime(of: self)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		stop()
	}

	override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

	func start() {
		if (initialDFRStatus & 0x01) == 0 {
			DFRSetStatus(2)
		}

		stream = SLSDFRDisplayStreamCreate(0, .main) { [weak self] status, _, frameSurface, _ in
			guard
				let self = self,
				status == .frameComplete,
				let layer = self.displayView.layer
			else {
				return
			}

			layer.contents = frameSurface
		}.takeUnretainedValue()

		stream?.start()
	}

	func stop() {
		guard let stream = stream else {
			return
		}

		stream.stop()
		self.stream = nil
		DFRSetStatus(initialDFRStatus)
	}

	private func mouseEvent(_ event: NSEvent) {
		let locationInView = convert(event.locationInWindow, from: nil)
		
		// Check if the click is within the displayView (Touch Bar content area)
		let displayViewRect = displayView.frame
		
		// Only process clicks within the display view
		guard displayViewRect.contains(locationInView) else {
			return
		}
		
		// Convert to displayView coordinates
		let locationInDisplayView = NSPoint(
			x: locationInView.x - displayViewRect.origin.x,
			y: locationInView.y - displayViewRect.origin.y
		)
		
		// Get the actual Touch Bar dimensions (what the system expects)
		let actualTouchBarSize = getActualTouchBarSize()
		
		// Scale the coordinates back to the original Touch Bar coordinate system
		let scaledX = (locationInDisplayView.x / displayViewRect.width) * actualTouchBarSize.width
		// Flip Y coordinate if needed (Touch Bar might have Y=0 at top, macOS views have Y=0 at bottom)
		let scaledY = (1.0 - (locationInDisplayView.y / displayViewRect.height)) * actualTouchBarSize.height
		
		// Ensure coordinates are within valid bounds
		let clampedX = max(0, min(scaledX, actualTouchBarSize.width))
		let clampedY = max(0, min(scaledY, actualTouchBarSize.height))
		
		let touchBarLocation = NSPoint(x: clampedX, y: clampedY)
		
		// Send the correctly scaled coordinates to the system
		DFRFoundationPostEventWithMouseActivity(event.type, touchBarLocation)
	}

	/// Get the actual Touch Bar native resolution that the system expects
	private func getActualTouchBarSize() -> CGSize {
		// DFRGetScreenSize() returns the Touch Bar's native pixel dimensions
		// This is what the system expects for coordinate input
		return DFRGetScreenSize()
	}

	override func mouseDown(with event: NSEvent) {
		mouseEvent(event)
	}

	override func mouseUp(with event: NSEvent) {
		mouseEvent(event)
	}

	override func mouseDragged(with event: NSEvent) {
		mouseEvent(event)
	}
	
	@objc private func touchIdClicked() {
		// Animate the button
		let originalTransform = touchIdButton.layer?.transform ?? CATransform3DIdentity
		let scaleTransform = CATransform3DScale(originalTransform, 1.2, 1.2, 1.0)
		
		CATransaction.begin()
		CATransaction.setCompletionBlock {
			self.touchIdButton.layer?.transform = originalTransform
		}
		let animation = CABasicAnimation(keyPath: "transform")
		animation.fromValue = originalTransform
		animation.toValue = scaleTransform
		animation.duration = 0.1
		animation.autoreverses = true
		touchIdButton.layer?.add(animation, forKey: "pulse")
		CATransaction.commit()
		
		// Hide the window for the specified duration
		guard let window = self.window else { return }
		window.setIsVisible(false)
		DispatchQueue.main.asyncAfter(deadline: .now() + Defaults[.windowHideDuration]) {
			window.setIsVisible(true)
		}
	}
	
	func updateLayout() {
		let bounds = self.bounds
		let inset = scaledInset
		
		// Frame view fills the bounds
		frameView.frame = bounds
		
		// Calculate display view width based on whether Touch ID button exists
		let hasButton = touchIdButton.superview != nil
		let displayViewWidth = hasButton ? (bounds.width - 2 * inset - scaledTouchIdDiameter - scaledTouchIdMargin) : (bounds.width - 2 * inset)
		
		// Display view inset from frame
		displayView.frame = NSRect(x: inset, y: inset, width: displayViewWidth, height: bounds.height - 2 * inset)
		
		// Touch ID button on the right (if it exists on this Mac model)
		if hasButton {
			let buttonSize = NSSize(width: scaledTouchIdDiameter, height: scaledTouchIdDiameter)
			let buttonOrigin = NSPoint(x: bounds.width - inset - scaledTouchIdDiameter, y: (bounds.height - scaledTouchIdDiameter) / 2)
			touchIdButton.frame = NSRect(origin: buttonOrigin, size: buttonSize)
		}
	}
	
	override func setFrameSize(_ newSize: NSSize) {
		super.setFrameSize(newSize)
		updateLayout()
	}
}
