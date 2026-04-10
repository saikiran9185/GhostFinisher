import Cocoa
import ApplicationServices
import ServiceManagement

// MARK: - Dictionary
// Add your own words here — names, tools, anything you type often
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
var wordBuffer      = ""
var isEnabled       = true   // toggled by Cmd+Shift+G
var eventTap: CFMachPort?

// MARK: - Fuzzy Matcher
func bestMatch(for input: String) -> String? {
    guard input.count >= 2 else { return nil }
    let lower = input.lowercased()

    // Priority 1 — exact prefix ("fin" → "Figma" before fuzzy)
    if let hit = ghostDictionary.first(where: { $0.lowercased().hasPrefix(lower) }) {
        return hit
    }
    // Priority 2 — letters appear in order anywhere ("ilu" → "Illustrator")
    return ghostDictionary.first { word in
        var idx = word.lowercased().startIndex
        for ch in lower {
            guard let found = word.lowercased()[idx...].firstIndex(of: ch) else { return false }
            idx = word.lowercased().index(after: found)
        }
        return true
    }
}

// MARK: - Inject Text (Backspace Nuke + retype)
func injectCompletion(word: String, deleteCount: Int) {
    // Step 1 — nuke the typo
    for _ in 0..<deleteCount {
        postKey(keyCode: 51, shift: false)  // backspace
    }
    Thread.sleep(forTimeInterval: 0.015)

    // Step 2 — type the perfect word
    let keyMap: [Character: CGKeyCode] = [
        "a":0,"s":1,"d":2,"f":3,"h":4,"g":5,"z":6,"x":7,"c":8,"v":9,
        "b":11,"q":12,"w":13,"e":14,"r":15,"y":16,"t":17,"o":31,"u":32,
        "i":34,"p":35,"l":37,"j":38,"k":40,"n":45,"m":46,
        " ":49
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

// MARK: - Ghost Popup Window
class GhostWindow: NSPanel {
    private let label = NSTextField(labelWithString: "")

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 32),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level                = .floating
        backgroundColor      = NSColor(white: 0.15, alpha: 0.92)
        isOpaque             = false
        hasShadow            = true
        ignoresMouseEvents   = true
        collectionBehavior   = [.canJoinAllSpaces, .stationary]
        isMovable            = false

        // Rounded corners
        contentView?.wantsLayer = true
        contentView?.layer?.cornerRadius = 8

        label.font          = .systemFont(ofSize: 13, weight: .medium)
        label.textColor     = .white
        label.alignment     = .center
        label.frame         = contentView!.bounds.insetBy(dx: 8, dy: 4)
        label.autoresizingMask = [.width, .height]
        contentView?.addSubview(label)
    }

    func show(_ suggestion: String, typed: String) {
        // "fin|al" — bold typed part, lighter completion
        let full  = NSMutableAttributedString()
        let dims  = [NSAttributedString.Key.foregroundColor: NSColor(white: 1, alpha: 0.5),
                     .font: NSFont.systemFont(ofSize: 13, weight: .regular)]
        let bold  = [NSAttributedString.Key.foregroundColor: NSColor.white,
                     .font: NSFont.systemFont(ofSize: 13, weight: .semibold)]
        full.append(NSAttributedString(string: typed, attributes: bold))
        if suggestion.lowercased().hasPrefix(typed.lowercased()) {
            let rest = String(suggestion.dropFirst(typed.count))
            full.append(NSAttributedString(string: rest, attributes: dims))
        }
        full.append(NSAttributedString(string: "  ⇥", attributes: dims))
        label.attributedStringValue = full

        let mouse = NSEvent.mouseLocation
        setFrameOrigin(NSPoint(x: mouse.x + 12, y: mouse.y - 36))
        orderFront(nil)
    }

    func hide() { orderOut(nil) }
}

let popup = GhostWindow()

// MARK: - Menu Bar Controller
class MenuBarController: NSObject {
    private var item: NSStatusItem!

    override init() {
        super.init()
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateIcon()

        let menu = NSMenu()
        let toggle = NSMenuItem(title: "Stop Ghost Finisher", action: #selector(toggleEnabled), keyEquivalent: "g")
        toggle.keyEquivalentModifierMask = [.command, .shift]
        toggle.target = self
        menu.addItem(toggle)
        menu.addItem(.separator())

        let addWord = NSMenuItem(title: "Add current clipboard word…", action: #selector(addClipboardWord), keyEquivalent: "")
        addWord.target = self
        menu.addItem(addWord)
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Ghost Finisher", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        item.menu = menu
    }

    func updateIcon() {
        item.button?.title = isEnabled ? "👻" : "💤"
        item.button?.toolTip = isEnabled ? "Ghost Finisher — Active (⌘⇧G to pause)" : "Ghost Finisher — Paused (⌘⇧G to resume)"
        if let menu = item.menu, let toggle = menu.items.first {
            toggle.title = isEnabled ? "Pause Ghost Finisher" : "Resume Ghost Finisher"
        }
    }

    @objc func toggleEnabled() {
        isEnabled.toggle()
        wordBuffer = ""
        DispatchQueue.main.async { popup.hide() }
        updateIcon()
    }

    @objc func addClipboardWord() {
        guard let word = NSPasteboard.general.string(forType: .string),
              !word.isEmpty, word.count < 30,
              !ghostDictionary.contains(word) else { return }
        ghostDictionary.append(word)
        let alert = NSAlert()
        alert.messageText = "Word added"
        alert.informativeText = "\"\(word)\" is now in Ghost Finisher's dictionary."
        alert.runModal()
    }
}

// MARK: - Event Tap Callback
let callback: CGEventTapCallBack = { proxy, type, event, _ in

    // Re-enable tap if macOS disables it (timeout safety)
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
        return Unmanaged.passRetained(event)
    }

    guard type == .keyDown else { return Unmanaged.passRetained(event) }

    let keyCode  = event.getIntegerValueField(.keyboardEventKeycode)
    let flags    = event.flags

    // ── Global toggle: Cmd+Shift+G ──────────────────────────────────────
    if keyCode == 5 && flags.contains(.maskCommand) && flags.contains(.maskShift) {
        DispatchQueue.main.async {
            (NSApp.delegate as? AppDelegate)?.menuBar.toggleEnabled()
        }
        return nil  // consume the shortcut
    }

    guard isEnabled else { return Unmanaged.passRetained(event) }

    // ── Tab: accept suggestion ──────────────────────────────────────────
    if keyCode == 48 {
        if let match = bestMatch(for: wordBuffer), !wordBuffer.isEmpty {
            let count = wordBuffer.count
            wordBuffer = ""
            DispatchQueue.main.async { popup.hide() }
            DispatchQueue.global(qos: .userInteractive).async {
                injectCompletion(word: match, deleteCount: count)
            }
            return nil  // consume Tab
        }
        wordBuffer = ""
        DispatchQueue.main.async { popup.hide() }
        return Unmanaged.passRetained(event)
    }

    // ── Escape: cancel ──────────────────────────────────────────────────
    if keyCode == 53 {
        wordBuffer = ""
        DispatchQueue.main.async { popup.hide() }
        return Unmanaged.passRetained(event)
    }

    // ── Backspace ───────────────────────────────────────────────────────
    if keyCode == 51 {
        if !wordBuffer.isEmpty { wordBuffer.removeLast() }
        if wordBuffer.isEmpty {
            DispatchQueue.main.async { popup.hide() }
        } else if let match = bestMatch(for: wordBuffer) {
            let snap = wordBuffer
            DispatchQueue.main.async { popup.show(match, typed: snap) }
        } else {
            DispatchQueue.main.async { popup.hide() }
        }
        return Unmanaged.passRetained(event)
    }

    // ── Any modifier combo (Cmd+X, etc.) → reset ───────────────────────
    if flags.contains(.maskCommand) || flags.contains(.maskControl) {
        wordBuffer = ""
        DispatchQueue.main.async { popup.hide() }
        return Unmanaged.passRetained(event)
    }

    // ── Standard letter ─────────────────────────────────────────────────
    var unicodeLen: Int = 0
    var unicodeBuffer = [UniChar](repeating: 0, count: 4)
    event.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &unicodeLen, unicodeString: &unicodeBuffer)
    let chars = String(unicodeBuffer.prefix(unicodeLen).compactMap { UnicodeScalar($0).map(Character.init) })
    if chars.count == 1, let ch = chars.first, ch.isLetter {
        wordBuffer.append(ch)
        if let match = bestMatch(for: wordBuffer) {
            let snap = wordBuffer
            DispatchQueue.main.async { popup.show(match, typed: snap) }
        } else {
            DispatchQueue.main.async { popup.hide() }
        }
        return Unmanaged.passRetained(event)
    }

    // ── Space, punctuation, arrow keys → new word boundary ──────────────
    wordBuffer = ""
    DispatchQueue.main.async { popup.hide() }
    return Unmanaged.passRetained(event)
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBar: MenuBarController!

    func applicationDidFinishLaunching(_ note: Notification) {
        menuBar = MenuBarController()
        startEventTap()
        registerLoginItem()
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
        guard let tap = eventTap else {
            showPermissionAlert()
            return
        }
        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func registerLoginItem() {
        // Registers this app to auto-launch at login (macOS 13+)
        if #available(macOS 13.0, *) {
            try? SMAppService.mainApp.register()
        }
    }

    func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText    = "Input Monitoring needed"
        alert.informativeText = "Open System Settings → Privacy & Security → Input Monitoring → enable Ghost Finisher, then relaunch."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Quit")
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!)
        }
        NSApp.terminate(nil)
    }
}

// MARK: - Entry Point
let app      = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)  // no Dock icon
app.run()
