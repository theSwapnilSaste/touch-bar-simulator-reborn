import Cocoa
import Defaults

final class TouchBarView: NSView {
	private var stream: CGDisplayStream?
	private let displayView = NSView()
	private let initialDFRStatus: Int32
	private let frameView = NSView()
	private let touchIdButton = NSButton()
	
	// Physical dimensions scaled to pixels (assuming 1mm = 1px for simplicity, adjust with scale)
	private var scaledInset: Double { Constants.touchBarInset * Defaults[.windowScale] }
	private var scaledTouchIdDiameter: Double { Constants.touchIdDiameter * Defaults[.windowScale] }
	private var scaledTouchIdMargin: Double { Constants.touchIdMargin * Defaults[.windowScale] }
	private var scaledCornerRadius: Double { Constants.cornerRadius * Defaults[.windowScale] }

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
		
		// Touch ID button
		touchIdButton.isBordered = false
		touchIdButton.bezelStyle = .circular
		touchIdButton.image = NSImage(systemSymbolName: "touchid", accessibilityDescription: "Touch ID")
		touchIdButton.imageScaling = .scaleProportionallyUpOrDown
		touchIdButton.target = self
		touchIdButton.action = #selector(touchIdClicked)
		frameView.addSubview(touchIdButton)
		
		start()
		setFrameSize(DFRGetScreenSize())
		updateLayout()
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
		let location = convert(event.locationInWindow, from: nil)
		DFRFoundationPostEventWithMouseActivity(event.type, location)
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
		
		// Display view inset from frame
		displayView.frame = NSRect(x: inset, y: inset, width: bounds.width - 2 * inset - scaledTouchIdDiameter - scaledTouchIdMargin, height: bounds.height - 2 * inset)
		
		// Touch ID button on the right
		let buttonSize = NSSize(width: scaledTouchIdDiameter, height: scaledTouchIdDiameter)
		let buttonOrigin = NSPoint(x: bounds.width - inset - scaledTouchIdDiameter, y: (bounds.height - scaledTouchIdDiameter) / 2)
		touchIdButton.frame = NSRect(origin: buttonOrigin, size: buttonSize)
	}
	
	override func setFrameSize(_ newSize: NSSize) {
		super.setFrameSize(newSize)
		updateLayout()
	}
}
