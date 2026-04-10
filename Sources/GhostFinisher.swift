import Cocoa
import ApplicationServices
import ServiceManagement

// MARK: - Dictionary
var ghostDictionary: [String] = [
    "Illustrator", "Photoshop", "InDesign", "Blender", "Figma",
    "Saikiran", "Typography", "Animation", "Mechanism", "Notchly",
    "Graphic", "Because", "Definitely", "Necessary", "Separate",
    "Portfolio", "Presentation", "Background", "Resolution", "Thumbnail",
    "Template", "Interface", "Gradient", "Transform", "Perspective",
    "Accessibility", "Application", "Development", "Environment",
    "Opportunity", "Immediately", "Particularly", "Specifically"
]

// MARK: - State
var wordBuffer = ""
var isEnabled  = true
var eventTap: CFMachPort?

// MARK: - Match Result
// Tells the UI which display mode to use
enum MatchKind {
    case prefix(tail: String)   // "fin" → tail = "al"  → show inline ghost text
    case fuzzy(word: String)    // "ilu" → word = "Illustrator" → show badge
}

func bestMatch(for input: String) -> MatchKind? {
    guard input.count >= 2 else { return nil }
    let lower = input.lowercased()

    // Prefix first — inline ghost text makes sense here
    if let hit = ghostDictionary.first(where: { $0.lowercased().hasPrefix(lower) }) {
        let tail = String(hit.dropFirst(input.count))
        return tail.isEmpty ? nil : .prefix(tail: tail)
    }

    // Fuzzy — letters appear in order anywhere
    if let hit = ghostDictionary.first(where: { word in
        var idx = word.lowercased().startIndex
        for ch in lower {
            guard let found = word.lowercased()[idx...].firstIndex(of: ch) else { return false }
            idx = word.lowercased().index(after: found)
        }
        return true
    }) {
        return .fuzzy(word: hit)
    }
    return nil
}

// MARK: - Cursor Position via Accessibility API
// Returns the screen rect of the text cursor in the focused text field.
// Falls back to mouse position for apps that don't expose accessibility info (Adobe etc).
func caretRect() -> CGRect? {
    let sysEl = AXUIElementCreateSystemWide()
    var focusedRaw: AnyObject?
    guard AXUIElementCopyAttributeValue(sysEl, kAXFocusedUIElementAttribute as CFString, &focusedRaw) == .success else { return nil }
    let element = focusedRaw as! AXUIElement

    var rangeRaw: AnyObject?
    guard AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &rangeRaw) == .success,
          let rangeVal = rangeRaw else { return nil }

    var boundsRaw: AnyObject?
    guard AXUIElementCopyParameterizedAttributeValue(
        element,
        kAXBoundsForRangeParameterizedAttribute as CFString,
        rangeVal,
        &boundsRaw
    ) == .success, let boundsVal = boundsRaw else { return nil }

    var rect = CGRect.zero
    guard AXValueGetValue(boundsVal as! AXValue, .cgRect, &rect), rect != .zero else { return nil }
    return rect
}

// Tries to read the font size from the focused element for better alignment.
func caretFontSize() -> CGFloat {
    let sysEl = AXUIElementCreateSystemWide()
    var focusedRaw: AnyObject?
    guard AXUIElementCopyAttributeValue(sysEl, kAXFocusedUIElementAttribute as CFString, &focusedRaw) == .success else { return 14 }
    let element = focusedRaw as! AXUIElement
    var fontRaw: AnyObject?
    // kAXFontAttribute string literal — the constant is not bridged in Swift 6
    guard AXUIElementCopyAttributeValue(element, "AXFont" as CFString, &fontRaw) == .success,
          let fontDict = fontRaw as? [String: Any],
          let size = fontDict["AXFontSize"] as? CGFloat else { return 14 }
    return max(11, min(size, 36))
}

// Convert a CGRect from screen coordinates (top-left origin, Quartz)
// to NSPoint in AppKit coordinates (bottom-left origin).
func nsPoint(from cgRect: CGRect) -> (origin: NSPoint, height: CGFloat) {
    let screen = NSScreen.screens.first(where: {
        $0.frame.contains(NSPoint(x: cgRect.midX, y: cgRect.midY))
    }) ?? NSScreen.main!
    let flippedY = screen.frame.height - cgRect.origin.y - cgRect.height
    return (NSPoint(x: cgRect.maxX, y: flippedY), cgRect.height)
}

// MARK: - Ghost Text Window
// Two visual modes:
//   .inline  — zero-background, just ghost grey text right at the caret
//   .badge   — small rounded pill for fuzzy matches where inline doesn't apply
class GhostWindow: NSPanel {
    private let label = NSTextField(labelWithString: "")

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level              = .floating
        backgroundColor    = .clear
        isOpaque           = false
        hasShadow          = false
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        isMovable          = false

        contentView?.wantsLayer = true

        label.isBezeled       = false
        label.isEditable      = false
        label.drawsBackground = false
        contentView?.addSubview(label)
    }

    // MARK: Inline mode — ghost text sits right at the caret
    func showInline(tail: String, caret: CGRect) {
        contentView?.layer?.backgroundColor = .none
        contentView?.layer?.cornerRadius    = 0
        hasShadow = false

        let (origin, lineH) = nsPoint(from: caret)
        let fontSize = caretFontSize()
        let font = NSFont.systemFont(ofSize: fontSize, weight: .regular)

        // Ghost text = completion tail + hint
        let str = NSMutableAttributedString()
        let ghostColor = NSColor(white: 0.55, alpha: 0.75)
        str.append(NSAttributedString(string: tail, attributes: [
            .foregroundColor: ghostColor,
            .font: font
        ]))
        str.append(NSAttributedString(string: "  ⇥", attributes: [
            .foregroundColor: NSColor(white: 0.55, alpha: 0.45),
            .font: NSFont.systemFont(ofSize: fontSize * 0.8, weight: .light)
        ]))

        label.attributedStringValue = str
        label.sizeToFit()

        let w = label.frame.width + 2
        let h = max(lineH, fontSize + 4)
        setContentSize(NSSize(width: w, height: h))
        // Align baseline: place window so text baseline matches the caret
        let baseline = origin.y + (h - fontSize) * 0.5
        setFrameOrigin(NSPoint(x: origin.x, y: baseline))
        label.frame = NSRect(x: 0, y: 0, width: w, height: h)
        orderFront(nil)
    }

    // MARK: Badge mode — small rounded pill for fuzzy matches
    func showBadge(word: String, typed: String) {
        hasShadow = true
        contentView?.layer?.cornerRadius    = 6
        contentView?.layer?.backgroundColor = NSColor(white: 0.12, alpha: 0.88).cgColor

        let str = NSMutableAttributedString()
        str.append(NSAttributedString(string: "⇥ ", attributes: [
            .foregroundColor: NSColor(white: 1, alpha: 0.45),
            .font: NSFont.systemFont(ofSize: 12, weight: .light)
        ]))
        // Highlight the letters the user typed inside the suggestion
        let lower = typed.lowercased()
        var usedIndices = IndexSet()
        var searchIdx = word.lowercased().startIndex
        for ch in lower {
            if let found = word.lowercased()[searchIdx...].firstIndex(of: ch) {
                usedIndices.insert(word.lowercased().distance(from: word.lowercased().startIndex, to: found))
                searchIdx = word.lowercased().index(after: found)
            }
        }
        for (i, ch) in word.enumerated() {
            let color = usedIndices.contains(i)
                ? NSColor.white
                : NSColor(white: 1, alpha: 0.5)
            str.append(NSAttributedString(string: String(ch), attributes: [
                .foregroundColor: color,
                .font: NSFont.systemFont(ofSize: 13, weight: usedIndices.contains(i) ? .semibold : .regular)
            ]))
        }

        label.attributedStringValue = str
        label.sizeToFit()
        let w = label.frame.width + 16
        let h: CGFloat = 26
        setContentSize(NSSize(width: w, height: h))
        label.frame = NSRect(x: 8, y: (h - label.frame.height) / 2, width: label.frame.width, height: label.frame.height)

        // Position near mouse as fallback (badge doesn't need exact cursor)
        let mouse = NSEvent.mouseLocation
        setFrameOrigin(NSPoint(x: mouse.x + 14, y: mouse.y - 32))
        orderFront(nil)
    }

    func hide() { orderOut(nil) }
}

let ghost = GhostWindow()

// MARK: - Inject Text
func injectCompletion(word: String, deleteCount: Int) {
    for _ in 0..<deleteCount { postKey(keyCode: 51, shift: false) }
    Thread.sleep(forTimeInterval: 0.015)
    let keyMap: [Character: CGKeyCode] = [
        "a":0,"s":1,"d":2,"f":3,"h":4,"g":5,"z":6,"x":7,"c":8,"v":9,
        "b":11,"q":12,"w":13,"e":14,"r":15,"y":16,"t":17,"o":31,"u":32,
        "i":34,"p":35,"l":37,"j":38,"k":40,"n":45,"m":46," ":49
    ]
    for ch in word {
        if let code = keyMap[Character(ch.lowercased())] {
            postKey(keyCode: code, shift: ch.isUppercase)
        }
    }
}

func postKey(keyCode: CGKeyCode, shift: Bool) {
    if shift { CGEvent(keyboardEventSource: nil, virtualKey: 56, keyDown: true)?.post(tap: .cghidEventTap) }
    CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)?.post(tap: .cghidEventTap)
    CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)?.post(tap: .cghidEventTap)
    if shift { CGEvent(keyboardEventSource: nil, virtualKey: 56, keyDown: false)?.post(tap: .cghidEventTap) }
}

// MARK: - Show suggestion (called on main thread)
func showSuggestion(match: MatchKind, typed: String) {
    switch match {
    case .prefix(let tail):
        // Try to get real caret position for inline rendering
        if let rect = caretRect() {
            ghost.showInline(tail: tail, caret: rect)
        } else {
            // Fallback: badge mode (Adobe apps, apps without AX support)
            if let fullWord = ghostDictionary.first(where: { $0.lowercased().hasPrefix(typed.lowercased()) }) {
                ghost.showBadge(word: fullWord, typed: typed)
            }
        }
    case .fuzzy(let word):
        ghost.showBadge(word: word, typed: typed)
    }
}

// MARK: - Menu Bar
class MenuBarController: NSObject {
    private var item: NSStatusItem!

    override init() {
        super.init()
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateIcon()

        let menu = NSMenu()
        let toggle = NSMenuItem(title: "Pause Ghost Finisher", action: #selector(toggleEnabled), keyEquivalent: "g")
        toggle.keyEquivalentModifierMask = [.command, .shift]
        toggle.target = self
        menu.addItem(toggle)
        menu.addItem(.separator())

        let addWord = NSMenuItem(title: "Add clipboard word to dictionary", action: #selector(addClipboardWord), keyEquivalent: "")
        addWord.target = self
        menu.addItem(addWord)
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Ghost Finisher", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
        item.menu = menu
    }

    func updateIcon() {
        item.button?.title   = isEnabled ? "👻" : "💤"
        item.button?.toolTip = isEnabled
            ? "Ghost Finisher active — ⌘⇧G to pause"
            : "Ghost Finisher paused — ⌘⇧G to resume"
        if let toggle = item.menu?.items.first {
            toggle.title = isEnabled ? "Pause Ghost Finisher" : "Resume Ghost Finisher"
        }
    }

    @objc func toggleEnabled() {
        isEnabled.toggle()
        wordBuffer = ""
        ghost.hide()
        updateIcon()
    }

    @objc func addClipboardWord() {
        guard let word = NSPasteboard.general.string(forType: .string)?
                            .trimmingCharacters(in: .whitespacesAndNewlines),
              !word.isEmpty, word.count < 40,
              word.allSatisfy({ $0.isLetter }),
              !ghostDictionary.contains(word) else { return }
        ghostDictionary.append(word)
        let alert = NSAlert()
        alert.messageText     = "Added to dictionary"
        alert.informativeText = "\"\(word)\" will now be suggested."
        alert.runModal()
    }
}

// MARK: - Event Tap
let callback: CGEventTapCallBack = { _, type, event, _ in
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
        return Unmanaged.passRetained(event)
    }
    guard type == .keyDown else { return Unmanaged.passRetained(event) }

    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let flags   = event.flags

    // ── ⌘⇧G — global toggle ────────────────────────────────────────────
    if keyCode == 5, flags.contains(.maskCommand), flags.contains(.maskShift) {
        DispatchQueue.main.async {
            (NSApp.delegate as? AppDelegate)?.menuBar.toggleEnabled()
        }
        return nil
    }

    guard isEnabled else { return Unmanaged.passRetained(event) }

    // ── Tab — accept ────────────────────────────────────────────────────
    if keyCode == 48, !wordBuffer.isEmpty, let match = bestMatch(for: wordBuffer) {
        let count  = wordBuffer.count
        let buffer = wordBuffer
        wordBuffer = ""
        DispatchQueue.main.async { ghost.hide() }
        DispatchQueue.global(qos: .userInteractive).async {
            switch match {
            case .prefix:
                // Only inject the tail — caret is already after the typed prefix
                // BUT we nuke+retype because the typed chars might be misspelled (ilu ≠ Ill)
                if let word = ghostDictionary.first(where: { $0.lowercased().hasPrefix(buffer.lowercased()) }) {
                    injectCompletion(word: word, deleteCount: count)
                }
            case .fuzzy(let word):
                injectCompletion(word: word, deleteCount: count)
            }
        }
        return nil
    }

    // ── Escape — dismiss ────────────────────────────────────────────────
    if keyCode == 53 {
        wordBuffer = ""
        DispatchQueue.main.async { ghost.hide() }
        return Unmanaged.passRetained(event)
    }

    // ── Backspace ───────────────────────────────────────────────────────
    if keyCode == 51 {
        if !wordBuffer.isEmpty { wordBuffer.removeLast() }
        if wordBuffer.isEmpty {
            DispatchQueue.main.async { ghost.hide() }
        } else if let match = bestMatch(for: wordBuffer) {
            let snap = wordBuffer
            DispatchQueue.main.async { showSuggestion(match: match, typed: snap) }
        } else {
            DispatchQueue.main.async { ghost.hide() }
        }
        return Unmanaged.passRetained(event)
    }

    // ── Block modifier shortcuts from building the buffer ───────────────
    if flags.contains(.maskCommand) || flags.contains(.maskControl) {
        wordBuffer = ""
        DispatchQueue.main.async { ghost.hide() }
        return Unmanaged.passRetained(event)
    }

    // ── Letter key ──────────────────────────────────────────────────────
    var uLen: Int = 0
    var uBuf = [UniChar](repeating: 0, count: 4)
    event.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &uLen, unicodeString: &uBuf)
    let chars = String(uBuf.prefix(uLen).compactMap { UnicodeScalar($0).map(Character.init) })

    if chars.count == 1, let ch = chars.first, ch.isLetter {
        wordBuffer.append(ch)
        if let match = bestMatch(for: wordBuffer) {
            let snap = wordBuffer
            DispatchQueue.main.async { showSuggestion(match: match, typed: snap) }
        } else {
            DispatchQueue.main.async { ghost.hide() }
        }
        return Unmanaged.passRetained(event)
    }

    // ── Word boundary — space, punctuation, arrows ───────────────────────
    wordBuffer = ""
    DispatchQueue.main.async { ghost.hide() }
    return Unmanaged.passRetained(event)
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBar: MenuBarController!

    func applicationDidFinishLaunching(_ note: Notification) {
        menuBar = MenuBarController()
        checkAccessibilityPermission()
        startEventTap()
        if #available(macOS 13.0, *) { try? SMAppService.mainApp.register() }
    }

    func checkAccessibilityPermission() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if !AXIsProcessTrustedWithOptions(opts) {
            // macOS will show its own prompt. We just wait — cursor positioning
            // degrades gracefully to badge mode until permission is granted.
        }
    }

    func startEventTap() {
        let mask: CGEventMask = 1 << CGEventType.keyDown.rawValue
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: nil
        )
        guard let tap = eventTap else { showInputMonitoringAlert(); return }
        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func showInputMonitoringAlert() {
        let a = NSAlert()
        a.messageText     = "Input Monitoring permission needed"
        a.informativeText = "System Settings → Privacy & Security → Input Monitoring → enable Ghost Finisher, then relaunch."
        a.addButton(withTitle: "Open System Settings")
        a.addButton(withTitle: "Quit")
        if a.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!)
        }
        NSApp.terminate(nil)
    }
}

// MARK: - Entry point
let app      = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
