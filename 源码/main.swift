import AppKit
import CoreGraphics

let minuteInterval: TimeInterval = 30 * 60
let testing = CommandLine.arguments.contains("--self-test")

func tint(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: r, green: g, blue: b, alpha: a)
}

let ink = tint(0.08, 0.23, 0.23)

final class Backdrop: NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSGradient(starting: tint(0.96, 0.98, 0.94), ending: tint(0.81, 0.91, 0.88))!.draw(in: bounds, angle: -65)
    }
}

final class Glass: NSView {
    override var intrinsicContentSize: NSSize { NSSize(width: 216, height: 168) }
    override func draw(_ dirtyRect: NSRect) {
        let ripple = NSBezierPath(ovalIn: NSRect(x: 22, y: 6, width: 172, height: 19))
        tint(0.20, 0.48, 0.43, 0.08).setFill()
        ripple.fill()
        let body = NSBezierPath()
        body.move(to: NSPoint(x: 52, y: 142))
        body.curve(to: NSPoint(x: 164, y: 142), controlPoint1: NSPoint(x: 52, y: 158), controlPoint2: NSPoint(x: 164, y: 158))
        body.line(to: NSPoint(x: 151, y: 24))
        body.curve(to: NSPoint(x: 65, y: 24), controlPoint1: NSPoint(x: 149, y: 10), controlPoint2: NSPoint(x: 67, y: 10))
        body.close()
        NSGraphicsContext.saveGraphicsState()
        body.addClip()
        NSGradient(starting: tint(0.98, 1, 0.99, 0.8), ending: tint(0.65, 0.84, 0.81, 0.6))!.draw(in: bounds, angle: 0)
        let water = NSBezierPath()
        water.move(to: NSPoint(x: 48, y: 90))
        water.curve(to: NSPoint(x: 170, y: 92), controlPoint1: NSPoint(x: 87, y: 112), controlPoint2: NSPoint(x: 124, y: 73))
        water.line(to: NSPoint(x: 170, y: 10))
        water.line(to: NSPoint(x: 48, y: 10))
        water.close()
        NSGradient(starting: tint(0.16, 0.59, 0.55), ending: tint(0.60, 0.87, 0.76))!.draw(in: water, angle: 74)
        for (x, y, d) in [(83, 47, 4), (88, 57, 2), (130, 75, 3)] {
            tint(0.95, 1, 0.94, 0.7).setFill()
            NSBezierPath(ovalIn: NSRect(x: x, y: y, width: d, height: d)).fill()
        }
        let glint = NSBezierPath()
        glint.move(to: NSPoint(x: 62, y: 128))
        glint.line(to: NSPoint(x: 70, y: 52))
        glint.lineWidth = 4
        glint.lineCapStyle = .round
        NSColor.white.withAlphaComponent(0.7).setStroke()
        glint.stroke()
        NSGraphicsContext.restoreGraphicsState()
        tint(0.34, 0.57, 0.54, 0.55).setStroke()
        body.lineWidth = 1.4
        body.stroke()
        NSBezierPath(ovalIn: NSRect(x: 52, y: 134, width: 112, height: 19)).stroke()
    }
}

final class DrinkButton: NSButton {
    override var intrinsicContentSize: NSSize { NSSize(width: 204, height: 48) }
    override func draw(_ dirtyRect: NSRect) {
        (isHighlighted ? tint(0.13, 0.36, 0.34) : ink).setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 24, yRadius: 24).fill()
        let label = NSAttributedString(string: title, attributes: [.foregroundColor: NSColor.white,
            .font: NSFont.systemFont(ofSize: 16, weight: .medium)])
        let size = label.size()
        label.draw(at: NSPoint(x: (bounds.width - size.width)/2, y: (bounds.height - size.height)/2))
    }
}

final class ReminderPanel: NSPanel {
    let drink = DrinkButton()
    override var canBecomeKey: Bool { true }
    override func cancelOperation(_ sender: Any?) { drink.performClick(nil) }

    init(screen: NSScreen, target: AnyObject, action: Selector) {
        super.init(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        hasShadow = false
        setFrame(screen.frame, display: false)
        let canvas = Backdrop()
        contentView = canvas
        func label(_ title: String, _ size: CGFloat, _ weight: NSFont.Weight, _ color: NSColor) -> NSTextField {
            let field = NSTextField(labelWithString: title)
            field.font = .systemFont(ofSize: size, weight: weight)
            field.textColor = color
            field.alignment = .center
            return field
        }
        let glass = Glass()
        let title = label("该喝水了", 44, .semibold, ink)
        let subtitle = label("放下手头的事，慢慢喝几口水。", 17, .regular, tint(0.23, 0.37, 0.35))
        drink.title = "喝好了，继续"
        drink.isBordered = false
        drink.target = target
        drink.action = action
        drink.keyEquivalent = "\r"
        let hint = label("下次提醒在 30 分钟后", 13, .regular, tint(0.29, 0.41, 0.39))
        let stack = NSStackView(views: [glass, title, subtitle, drink, hint])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.setCustomSpacing(28, after: glass)
        stack.setCustomSpacing(30, after: subtitle)
        stack.translatesAutoresizingMaskIntoConstraints = false
        canvas.addSubview(stack)
        NSLayoutConstraint.activate([stack.centerXAnchor.constraint(equalTo: canvas.centerXAnchor),
                                     stack.centerYAnchor.constraint(equalTo: canvas.centerYAnchor)])
    }
}

final class Reminder: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let interval: TimeInterval = testing ? 2 : minuteInterval
    var deadline: Date?
    var timer: Timer?
    var panels = [ReminderPanel]()
    var status: NSStatusItem!
    let nextItem = NSMenuItem()
    var presentations = 0
    var testStep = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let drop = NSImage(systemSymbolName: "drop.fill", accessibilityDescription: "喝水提醒")
        drop?.isTemplate = true
        status.button?.image = drop
        if drop == nil { status.button?.title = "水" }
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(nextItem)
        menu.addItem(.separator())
        let now = menu.addItem(withTitle: "现在提醒我", action: #selector(showReminder), keyEquivalent: "")
        now.target = self
        menu.addItem(withTitle: "退出喝水提醒", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        status.menu = menu
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(checkTime), name: NSWorkspace.didWakeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screensChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        schedule()
        if testing { after(2.7) { self.checkPresentation() } }
    }

    func schedule() {
        deadline = Date().addingTimeInterval(interval)
        updateStatus()
        armTimer()
    }
    func armTimer() {
        timer?.invalidate()
        guard let deadline else { return }
        let next = Timer(fireAt: deadline, interval: 0, target: self, selector: #selector(checkTime), userInfo: nil, repeats: false)
        RunLoop.main.add(next, forMode: .common)
        timer = next
    }
    @objc func checkTime() {
        guard let deadline else { return }
        if deadline <= Date() { showReminder() } else { armTimer() }
    }
    func updateStatus() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let message = deadline.map { "下次喝水提醒  " + formatter.string(from: $0) } ?? "该喝水了"
        nextItem.title = message
        status.button?.toolTip = message
    }
    func menuWillOpen(_ menu: NSMenu) { updateStatus() }

    @objc func showReminder() {
        guard panels.isEmpty else { return }
        guard !NSScreen.screens.isEmpty else {
            deadline = Date().addingTimeInterval(5)
            armTimer()
            return
        }
        timer?.invalidate()
        timer = nil
        deadline = nil
        updateStatus()
        presentations += 1
        displayPanels()
    }
    func displayPanels() {
        let current = NSScreen.main
        panels = NSScreen.screens.map { ReminderPanel(screen: $0, target: self, action: #selector(dismiss)) }
        NSApp.activate(ignoringOtherApps: true)
        for panel in panels { panel.orderFrontRegardless() }
        (panels.first { $0.screen == current } ?? panels.first)?.makeKeyAndOrderFront(nil)
    }
    func clearPanels() {
        for panel in panels { panel.close() }
        panels.removeAll()
    }
    @objc func screensChanged() {
        guard deadline == nil else { return }
        clearPanels()
        displayPanels()
    }
    @objc func dismiss() {
        guard !panels.isEmpty else { return }
        clearPanels()
        NSApp.hide(nil)
        schedule()
    }

    func after(_ delay: TimeInterval, _ work: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
    func checkPresentation() {
        testStep += 1
        let screens = NSScreen.screens
        let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        let visible = Set(windows.compactMap { $0[kCGWindowNumber as String] as? Int })
        guard !panels.isEmpty, panels.count == screens.count, presentations == testStep,
              panels.allSatisfy({ p in p.isVisible && visible.contains(p.windowNumber) && screens.contains(where: { $0.frame == p.frame }) }),
              let first = panels.first else { print("FAIL: fullscreen presentation"); exit(1) }
        print("PASS cycle \(testStep): WindowServer confirms \(panels.count) visible fullscreen panel(s), frame \(first.frame)")
        first.drink.performClick(nil)
        guard panels.isEmpty, timer?.isValid == true, (deadline?.timeIntervalSinceNow ?? 0) > 0 else {
            print("FAIL: dismissal or rearming"); exit(1)
        }
        print("PASS cycle \(testStep): button dismissed reminder and armed next timer")
        if testStep == 2 { NSApp.terminate(nil) }
        else { after(interval + 0.7) { self.checkPresentation() } }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let reminder = Reminder()
app.delegate = reminder
app.run()
