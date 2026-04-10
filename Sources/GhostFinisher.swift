import Cocoa
import ApplicationServices
import ServiceManagement

// MARK: - Dictionary
// Personal words (always highest priority)
var personalDictionary: [String] = [
    "Illustrator", "Photoshop", "InDesign", "Blender", "Figma",
    "Saikiran", "Typography", "Animation", "Mechanism", "Notchly",
    "Portfolio", "Thumbnail", "Resolution", "Gradient", "Transform"
]

// Top ~300 common English words — covers MonkeyType english/english1k lists
// and the most-mistyped everyday words
let englishDictionary: [String] = [
    // MonkeyType top-200 core words
    "the","be","to","of","and","a","in","that","have","it",
    "for","not","on","with","he","as","you","do","at","this",
    "but","his","by","from","they","we","say","her","she","or",
    "an","will","my","one","all","would","there","their","what","so",
    "up","out","if","about","who","get","which","go","me","when",
    "make","can","like","time","no","just","him","know","take","people",
    "into","year","your","good","some","could","them","see","other","than",
    "then","now","look","only","come","its","over","think","also","back",
    "after","use","two","how","our","work","first","well","way","even",
    "new","want","because","any","these","give","day","most","us","great",
    "between","need","large","often","hand","high","place","hold","turn","were",
    "before","right","too","means","old","any","same","tell","boy","follow",
    "came","show","also","around","form","small","set","put","end","does",
    "another","well","large","big","where","again","many","off","never","last",
    "found","still","should","under","never","home","read","hand","port","large",
    "spell","air","away","animal","house","point","page","letter","mother","answer",
    "found","study","still","learn","plant","cover","food","sun","four","between",
    "state","keep","never","start","city","earth","eye","light","thought","head",
    "under","story","saw","left","don","few","while","along","might","close",
    "something","seem","next","hard","open","example","begin","life","always","those",
    "both","paper","together","got","group","often","run","important","until","children",
    "side","feet","car","mile","night","walk","white","sea","began","grow",
    "took","river","four","carry","state","once","book","hear","stop","without",
    "second","later","miss","idea","enough","eat","face","watch","far","indian",
    "real","almost","let","above","girl","sometimes","mountain","cut","young","talk",
    "soon","list","song","being","leave","family","body","music","color","stand",
    // Commonly misspelled words (spell correction targets)
    "receive","believe","achieve","beautiful","definitely","necessary","separate",
    "occurrence","beginning","environment","government","immediately","knowledge",
    "particularly","unfortunately","professional","international","communication",
    "development","experience","information","opportunity","organization","understanding",
    "everything","something","someone","nothing","everyone","anyone","somewhere",
    "themselves","ourselves","yourself","himself","herself","together","without",
    "through","although","because","however","therefore","whenever","wherever",
    "whatever","whether","neither","another","different","important","possible",
    "probably","question","remember","sentence","terrible","various","welcome",
    "across","against","already","during","enough","except","inside","instead",
    "outside","really","though","unless","until","while","beyond","within",
]

var ghostDictionary: [String] { personalDictionary + englishDictionary }

// MARK: - State
var wordBuffer = ""
var isEnabled  = true
var eventTap: CFMachPort?

// Unique marker so the tap ignores our own injected keystrokes
let GHOST_MARKER: Int64 = 0x47484F5354  // "GHOST"
let injectionSource = CGEventSource(stateID: .combinedSessionState)

// MARK: - Levenshtein distance (fast, capped at 3 for speed)
func editDistance(_ a: String, _ b: String, cap: Int = 3) -> Int {
    let a = Array(a.lowercased()), b = Array(b.lowercased())
    let m = a.count, n = b.count
    guard abs(m - n) <= cap else { return cap + 1 }
    var row = Array(0...n)
    for i in 1...m {
        var prev = row[0]
        row[0] = i
        for j in 1...n {
            let temp = row[j]
            row[j] = a[i-1] == b[j-1] ? prev : min(prev, min(row[j], row[j-1])) + 1
            prev = temp
        }
        if row.min()! > cap { return cap + 1 }
    }
    return row[n]
}

// MARK: - Match result
enum MatchKind {
    case prefix(tail: String, word: String)  // "fin" → tail="al", word="final" — inline ghost
    case spell(word: String)                 // "teh" → "the" — spell correction badge
    case fuzzy(word: String)                 // "ilu" → "Illustrator" — fuzzy badge
}

func bestMatch(for input: String) -> MatchKind? {
    guard input.count >= 2 else { return nil }
    let lower = input.lowercased()

    // 1 — Exact prefix (fastest, highest confidence)
    if let hit = ghostDictionary.first(where: { $0.lowercased().hasPrefix(lower) }) {
        let tail = String(hit.dropFirst(input.count))
        return tail.isEmpty ? nil : .prefix(tail: tail, word: hit)
    }

    // 2 — Spell correction via edit distance ≤ 2
    //     Only for words that are the same length ± 2 (avoids false positives on short prefixes)
    if input.count >= 3 {
        var bestDist = 3
        var bestWord: String? = nil
        for word in ghostDictionary {
            guard abs(word.count - input.count) <= 2 else { continue }
            let d = editDistance(lower, word, cap: 2)
            if d < bestDist {
                bestDist = d
                bestWord = word
            }
        }
        if let w = bestWord, bestDist <= 2 { return .spell(word: w) }
    }

    // 3 — Fuzzy (letters appear in order anywhere)
    if let hit = ghostDictionary.first(where: { word in
        var idx = word.lowercased().startIndex
        for ch in lower {
            guard let found = word.lowercased()[idx...].firstIndex(of: ch) else { return false }
            idx = word.lowercased().index(after: found)
        }
        return true
    }) { return .fuzzy(word: hit) }

    return nil
}

// MARK: - Cursor position via Accessibility API
func caretRect() -> CGRect? {
    let sys = AXUIElementCreateSystemWide()
    var raw: AnyObject?
    guard AXUIElementCopyAttributeValue(sys, kAXFocusedUIElementAttribute as CFString, &raw) == .success else { return nil }
    let el = raw as! AXUIElement
    var rangeRaw: AnyObject?
    guard AXUIElementCopyAttributeValue(el, kAXSelectedTextRangeAttribute as CFString, &rangeRaw) == .success,
          let rangeVal = rangeRaw else { return nil }
    var boundsRaw: AnyObject?
    guard AXUIElementCopyParameterizedAttributeValue(el, kAXBoundsForRangeParameterizedAttribute as CFString, rangeVal, &boundsRaw) == .success,
          let boundsVal = boundsRaw else { return nil }
    var rect = CGRect.zero
    guard AXValueGetValue(boundsVal as! AXValue, .cgRect, &rect), rect != .zero else { return nil }
    return rect
}

func caretFontSize() -> CGFloat {
    let sys = AXUIElementCreateSystemWide()
    var raw: AnyObject?
    guard AXUIElementCopyAttributeValue(sys, kAXFocusedUIElementAttribute as CFString, &raw) == .success else { return 14 }
    let el = raw as! AXUIElement
    var fontRaw: AnyObject?
    guard AXUIElementCopyAttributeValue(el, "AXFont" as CFString, &fontRaw) == .success,
          let dict = fontRaw as? [String: Any],
          let size = dict["AXFontSize"] as? CGFloat else { return 14 }
    return max(11, min(size, 36))
}

func nsOrigin(from cgRect: CGRect) -> (point: NSPoint, height: CGFloat) {
    let screen = NSScreen.screens.first { $0.frame.contains(NSPoint(x: cgRect.midX, y: cgRect.midY)) } ?? NSScreen.main!
    let y = screen.frame.height - cgRect.origin.y - cgRect.height
    return (NSPoint(x: cgRect.maxX, y: y), cgRect.height)
}

// MARK: - Ghost Window
class GhostWindow: NSPanel {
    private let label = NSTextField(labelWithString: "")

    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        contentView?.wantsLayer = true
        label.isBezeled = false; label.isEditable = false; label.drawsBackground = false
        contentView?.addSubview(label)
    }

    // Ghost text directly at the cursor — only the tail is shown
    func showInline(tail: String, caret: CGRect) {
        contentView?.layer?.backgroundColor = .none
        contentView?.layer?.cornerRadius = 0
        hasShadow = false
        let (origin, lineH) = nsOrigin(from: caret)
        let fontSize = caretFontSize()
        let str = NSMutableAttributedString()
        str.append(NSAttributedString(string: tail, attributes: [
            .foregroundColor: NSColor(white: 0.55, alpha: 0.72),
            .font: NSFont.systemFont(ofSize: fontSize, weight: .regular)
        ]))
        str.append(NSAttributedString(string: "  ⇥", attributes: [
            .foregroundColor: NSColor(white: 0.55, alpha: 0.38),
            .font: NSFont.systemFont(ofSize: fontSize * 0.78, weight: .light)
        ]))
        label.attributedStringValue = str
        label.sizeToFit()
        let w = label.frame.width + 2
        let h = max(lineH, fontSize + 4)
        setContentSize(NSSize(width: w, height: h))
        setFrameOrigin(NSPoint(x: origin.x, y: origin.y + (h - fontSize) * 0.5))
        label.frame = NSRect(x: 0, y: 0, width: w, height: h)
        orderFront(nil)
    }

    // Small badge for spell corrections and fuzzy matches
    func showBadge(word: String, typed: String, kind: MatchKind) {
        hasShadow = true
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let bgColor = isDark ? NSColor(white: 0.13, alpha: 0.92) : NSColor(white: 0.95, alpha: 0.96)
        contentView?.layer?.backgroundColor = bgColor.cgColor
        contentView?.layer?.cornerRadius = 7

        let str = NSMutableAttributedString()
        let hintAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.secondaryLabelColor,
            .font: NSFont.systemFont(ofSize: 11, weight: .light)
        ]
        // Label: ✦ for spell, ⇥ for others
        switch kind {
        case .spell: str.append(NSAttributedString(string: "✦ ", attributes: hintAttrs))
        default:     str.append(NSAttributedString(string: "⇥ ", attributes: hintAttrs))
        }
        // Highlight matched chars bold, rest normal
        let lower = typed.lowercased()
        var usedIdx = IndexSet()
        var si = word.lowercased().startIndex
        for ch in lower {
            if let f = word.lowercased()[si...].firstIndex(of: ch) {
                usedIdx.insert(word.lowercased().distance(from: word.startIndex, to: f))
                si = word.lowercased().index(after: f)
            }
        }
        for (i, ch) in word.enumerated() {
            let matched = usedIdx.contains(i)
            str.append(NSAttributedString(string: String(ch), attributes: [
                .foregroundColor: matched ? NSColor.labelColor : NSColor.secondaryLabelColor,
                .font: NSFont.systemFont(ofSize: 13, weight: matched ? .semibold : .regular)
            ]))
        }

        label.attributedStringValue = str
        label.sizeToFit()
        let w = label.frame.width + 18
        let h: CGFloat = 27
        setContentSize(NSSize(width: w, height: h))
        label.frame = NSRect(x: 9, y: (h - label.frame.height) / 2, width: label.frame.width, height: label.frame.height)

        // Try caret position first, fall back to mouse
        var origin = NSEvent.mouseLocation
        origin.x += 14; origin.y -= 34
        if let rect = caretRect() {
            let (pt, lineH) = nsOrigin(from: rect)
            origin = NSPoint(x: pt.x + 4, y: pt.y - lineH - 4)
        }
        // Keep on-screen
        if let screen = NSScreen.main {
            origin.x = min(origin.x, screen.visibleFrame.maxX - w - 8)
            origin.y = max(origin.y, screen.visibleFrame.minY + 8)
        }
        setFrameOrigin(origin)
        orderFront(nil)
    }

    func hide() { orderOut(nil) }
}

let ghost = GhostWindow()

// MARK: - Show suggestion (main thread)
func showSuggestion(match: MatchKind, typed: String) {
    switch match {
    case .prefix(let tail, let word):
        if let rect = caretRect() {
            ghost.showInline(tail: tail, caret: rect)
        } else {
            ghost.showBadge(word: word, typed: typed, kind: match)
        }
    case .spell(let word):
        ghost.showBadge(word: word, typed: typed, kind: match)
    case .fuzzy(let word):
        ghost.showBadge(word: word, typed: typed, kind: match)
    }
}

// MARK: - Injection
let keyMap: [Character: CGKeyCode] = [
    "a":0,"s":1,"d":2,"f":3,"h":4,"g":5,"z":6,"x":7,"c":8,"v":9,
    "b":11,"q":12,"w":13,"e":14,"r":15,"y":16,"t":17,"o":31,"u":32,
    "i":34,"p":35,"l":37,"j":38,"k":40,"n":45,"m":46," ":49
]

func postKey(keyCode: CGKeyCode, shift: Bool) {
    func stamp(_ e: CGEvent?) { e?.setIntegerValueField(.eventSourceUserData, value: GHOST_MARKER) }
    func send(_ e: CGEvent?)  { stamp(e); e?.post(tap: .cghidEventTap) }
    if shift { send(CGEvent(keyboardEventSource: injectionSource, virtualKey: 56, keyDown: true)) }
    send(CGEvent(keyboardEventSource: injectionSource, virtualKey: keyCode, keyDown: true))
    send(CGEvent(keyboardEventSource: injectionSource, virtualKey: keyCode, keyDown: false))
    if shift { send(CGEvent(keyboardEventSource: injectionSource, virtualKey: 56, keyDown: false)) }
}

func typeString(_ text: String) {
    for ch in text {
        if let code = keyMap[Character(ch.lowercased())] {
            postKey(keyCode: code, shift: ch.isUppercase)
        }
    }
}

func deleteChars(_ n: Int) {
    for _ in 0..<n { postKey(keyCode: 51, shift: false) }
}

func acceptMatch(_ match: MatchKind, typedCount: Int) {
    switch match {
    case .prefix(let tail, _):
        // Only type the tail — typed part already in the field, correct, no backspacing
        // This is 10x faster than nuke+retype
        typeString(tail)

    case .spell(let word), .fuzzy(let word):
        // Nuke the whole typed word and retype correctly
        deleteChars(typedCount)
        Thread.sleep(forTimeInterval: 0.005)  // 5ms — just enough for apps to process deletes
        typeString(word)
    }
}

// MARK: - Menu Bar
class MenuBarController: NSObject {
    var item: NSStatusItem!

    override init() {
        super.init()
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateIcon()
        let menu = NSMenu()
        let toggle = NSMenuItem(title: "Pause", action: #selector(toggleEnabled), keyEquivalent: "g")
        toggle.keyEquivalentModifierMask = [.command, .shift]
        toggle.target = self
        menu.addItem(toggle)
        menu.addItem(.separator())
        let add = NSMenuItem(title: "Add clipboard word to dictionary", action: #selector(addWord), keyEquivalent: "")
        add.target = self
        menu.addItem(add)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Ghost Finisher", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
    }

    func updateIcon() {
        item.button?.title   = isEnabled ? "👻" : "💤"
        item.button?.toolTip = isEnabled ? "Ghost Finisher active — ⌘⇧G to pause" : "Ghost Finisher paused — ⌘⇧G to resume"
        (item.menu?.items.first)?.title = isEnabled ? "Pause Ghost Finisher" : "Resume Ghost Finisher"
    }

    @objc func toggleEnabled() {
        isEnabled.toggle(); wordBuffer = ""; ghost.hide(); updateIcon()
    }

    @objc func addWord() {
        guard let w = NSPasteboard.general.string(forType: .string)?
                        .trimmingCharacters(in: .whitespacesAndNewlines),
              !w.isEmpty, w.count < 40, w.allSatisfy({ $0.isLetter }),
              !personalDictionary.contains(w) else { return }
        personalDictionary.append(w)
        let a = NSAlert()
        a.messageText = "Added"
        a.informativeText = "\"\(w)\" added to your personal dictionary."
        a.runModal()
    }
}

// MARK: - Event Tap
let callback: CGEventTapCallBack = { _, type, event, _ in
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let t = eventTap { CGEvent.tapEnable(tap: t, enable: true) }
        return Unmanaged.passRetained(event)
    }
    guard type == .keyDown else { return Unmanaged.passRetained(event) }

    // Ignore our own injected events
    if event.getIntegerValueField(.eventSourceUserData) == GHOST_MARKER {
        return Unmanaged.passRetained(event)
    }

    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let flags   = event.flags

    // ⌘⇧G — global toggle
    if keyCode == 5, flags.contains(.maskCommand), flags.contains(.maskShift) {
        DispatchQueue.main.async { (NSApp.delegate as? AppDelegate)?.menuBar.toggleEnabled() }
        return nil
    }

    guard isEnabled else { return Unmanaged.passRetained(event) }

    // Tab or Right-Arrow — accept suggestion
    // Right arrow (keyCode 124) is the natural "accept inline" key like macOS autocomplete
    let isAccept = keyCode == 48 || keyCode == 124
    if isAccept, !wordBuffer.isEmpty, let match = bestMatch(for: wordBuffer) {
        let count = wordBuffer.count
        let snap  = match
        wordBuffer = ""
        DispatchQueue.main.async { ghost.hide() }
        DispatchQueue.global(qos: .userInteractive).async { acceptMatch(snap, typedCount: count) }
        return nil
    }

    // Escape
    if keyCode == 53 {
        wordBuffer = ""; DispatchQueue.main.async { ghost.hide() }
        return Unmanaged.passRetained(event)
    }

    // Backspace
    if keyCode == 51 {
        if !wordBuffer.isEmpty { wordBuffer.removeLast() }
        if wordBuffer.isEmpty { DispatchQueue.main.async { ghost.hide() } }
        else if let m = bestMatch(for: wordBuffer) { let s = wordBuffer; DispatchQueue.main.async { showSuggestion(match: m, typed: s) } }
        else { DispatchQueue.main.async { ghost.hide() } }
        return Unmanaged.passRetained(event)
    }

    // Block modifier shortcuts from touching the buffer
    if flags.contains(.maskCommand) || flags.contains(.maskControl) {
        wordBuffer = ""; DispatchQueue.main.async { ghost.hide() }
        return Unmanaged.passRetained(event)
    }

    // Letter key
    var uLen = 0
    var uBuf = [UniChar](repeating: 0, count: 4)
    event.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &uLen, unicodeString: &uBuf)
    let chars = String(uBuf.prefix(uLen).compactMap { UnicodeScalar($0).map(Character.init) })

    if chars.count == 1, let ch = chars.first, ch.isLetter {
        wordBuffer.append(ch)
        if let m = bestMatch(for: wordBuffer) { let s = wordBuffer; DispatchQueue.main.async { showSuggestion(match: m, typed: s) } }
        else { DispatchQueue.main.async { ghost.hide() } }
        return Unmanaged.passRetained(event)
    }

    // Word boundary
    wordBuffer = ""; DispatchQueue.main.async { ghost.hide() }
    return Unmanaged.passRetained(event)
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBar: MenuBarController!

    func applicationDidFinishLaunching(_ n: Notification) {
        menuBar = MenuBarController()
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
        startEventTap()
        if #available(macOS 13.0, *) { try? SMAppService.mainApp.register() }
    }

    func startEventTap() {
        let mask: CGEventMask = 1 << CGEventType.keyDown.rawValue
        eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                     options: .defaultTap, eventsOfInterest: mask,
                                     callback: callback, userInfo: nil)
        guard let tap = eventTap else { showAlert(); return }
        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func showAlert() {
        let a = NSAlert()
        a.messageText = "Input Monitoring needed"
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
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
