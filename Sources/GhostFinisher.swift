import Cocoa
import ApplicationServices
import ServiceManagement
import IOKit.pwr_mgt

// MARK: - Dictionary
var personalDictionary: [String] = [
    "Illustrator", "Photoshop", "InDesign", "Blender", "Figma",
    "Saikiran", "Typography", "Animation", "Mechanism", "Notchly",
    "Portfolio", "Thumbnail", "Resolution", "Gradient", "Transform"
]

let englishDictionary: [String] = [
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
    "before","right","too","means","old","same","tell","boy","follow",
    "came","show","around","form","small","set","put","end","does",
    "another","where","again","many","off","never","last",
    "found","still","should","under","home","read","point","letter","mother","answer",
    "spell","away","animal","house","page","study","learn","plant","cover",
    "food","sun","four","state","keep","start","city","earth","eye",
    "light","thought","head","story","left","few","while","along","might","close",
    "something","seem","next","hard","open","example","begin","life","always","those",
    "both","paper","together","group","run","important","until","children",
    "side","feet","car","night","walk","white","sea","began","grow",
    "took","river","carry","once","book","hear","stop","without",
    "second","later","idea","enough","eat","face","watch","far",
    "real","almost","let","above","girl","sometimes","mountain","cut","young","talk",
    "soon","list","song","being","leave","family","body","music","color","stand",
    "receive","believe","achieve","beautiful","definitely","necessary","separate",
    "occurrence","beginning","environment","government","immediately","knowledge",
    "particularly","unfortunately","professional","international","communication",
    "development","experience","information","opportunity","organization","understanding",
    "because","different","through","people","should","about","every","before",
    "working","writing","getting","putting","making","taking","coming","going",
    "their","there","here","where","which","while","would","could","should",
    "actually","usually","probably","quickly","really","easily","clearly",
    "everything","something","anything","nothing","someone","anyone","everyone",
    "another","whether","whatever","however","together","although","therefore",
    "always","never","often","sometimes","already","still","even","just","also",
    "notion","figma","illustrator","photoshop","blender","animation","design",
    "everything","something","someone","nothing","everyone","anyone","somewhere",
    "themselves","ourselves","yourself","himself","herself","together","without",
    "through","although","because","however","therefore","whenever","wherever",
    "whatever","whether","neither","another","different","important","possible",
    "probably","question","remember","sentence","terrible","various","welcome",
    "across","against","already","during","enough","except","inside","instead",
    "outside","really","though","unless","until","while","beyond","within",
    "write","writing","written","wrote","wrong","right","their","there","they're",
    "your","you're","its","it's","then","than","affect","effect","lose","loose",
    "accept","except","advice","advise","among","between","amount","number",
    "fewer","less","good","well","bad","badly","further","farther",
    "which","that","who","whom","whose","where","when","why","how",
    "could","would","should","might","must","shall","will","may","can",
    "about","above","after","against","along","among","around","at","before",
    "behind","below","beneath","beside","between","beyond","by","down",
    "during","except","for","from","in","inside","into","like","near",
    "next","of","off","on","onto","out","outside","over","past",
    "since","through","throughout","to","toward","under","until","up",
    "upon","with","within","without",
]

var ghostDictionary: [String] { personalDictionary + englishDictionary }

// MARK: - Typo map  (checked first — instant, no fuzzy math needed)
// 300+ most common English misspellings → correct form
let typoMap: [String: String] = [
    // A
    "abotu":"about","abscence":"absence","absense":"absence","accomodate":"accommodate",
    "acheive":"achieve","acheiving":"achieving","acn":"can","acomplish":"accomplish",
    "acomodate":"accommodate","acquaintence":"acquaintance","acrage":"acreage",
    "adress":"address","adn":"and","affort":"afford","agian":"again","agknowledge":"acknowledge",
    "ahppen":"happen","ahve":"have","alcohal":"alcohol","almsot":"almost","alot":"a lot",
    "alreayd":"already","alright":"all right","alwasy":"always","amature":"amateur",
    "ambivilent":"ambivalent","amzing":"amazing","anbd":"and","anual":"annual",
    "anyoen":"anyone","appauling":"appalling","apparantly":"apparently","appearence":"appearance",
    "appriciate":"appreciate","aquire":"acquire","arguement":"argument","arround":"around",
    "articel":"article","asap":"asap","assasinate":"assassinate","asside":"aside",
    "aswell":"as well","atain":"attain","athiest":"atheist","athority":"authority",
    "autamatically":"automatically","automaticaly":"automatically","auxillary":"auxiliary",
    // B
    "bakc":"back","basicaly":"basically","basicly":"basically","becasue":"because",
    "becuase":"because","becomeing":"becoming","befoer":"before","begining":"beginning",
    "beleive":"believe","belive":"believe","benifit":"benefit","buisness":"business",
    "buliding":"building","buton":"button","beutiful":"beautiful","buetiful":"beautiful",
    // C
    "calender":"calendar","caluclate":"calculate","camoflage":"camouflage","cant":"can't",
    "catagory":"category","caugh":"caught","challange":"challenge","changeing":"changing",
    "charachter":"character","charactor":"character","cheif":"chief","cieling":"ceiling",
    "collegue":"colleague","comback":"comeback","comming":"coming","comittee":"committee",
    "commited":"committed","commitee":"committee","compatable":"compatible",
    "compitent":"competent","completly":"completely","concious":"conscious",
    "condescending":"condescending","congradulations":"congratulations",
    "consistant":"consistent","controll":"control","convienient":"convenient",
    "copywrite":"copyright","couldnt":"couldn't","coverd":"covered","critisism":"criticism",
    "currant":"current","cusotmer":"customer",
    // D
    "daed":"dead","dael":"deal","daes":"does","definitly":"definitely","definately":"definitely",
    "dependant":"dependent","descrption":"description","dieing":"dying","diffrence":"difference",
    "dilema":"dilemma","dilemna":"dilemma","dissapoint":"disappoint","doesnt":"doesn't",
    "doign":"doing","dont":"don't","downlaod":"download","duing":"during","dupicate":"duplicate",
    // E
    "eagre":"eager","eigth":"eighth","embarass":"embarrass","embarrasing":"embarrassing",
    "eminate":"emanate","emmit":"emit","enviroment":"environment","equiped":"equipped",
    "esential":"essential","excede":"exceed","existance":"existence","expecially":"especially",
    "experiance":"experience","experince":"experience","explict":"explicit","expresion":"expression",
    "extemely":"extremely","extention":"extension",
    // F
    "familliar":"familiar","fasle":"false","favorate":"favorite","favourate":"favourite",
    "fianlly":"finally","filetr":"filter","finaly":"finally","florescent":"fluorescent",
    "focuss":"focus","foriegn":"foreign","forseeable":"foreseeable","freind":"friend",
    "frmo":"from","fromthe":"from the","futher":"further",
    // G
    "gaurantee":"guarantee","geting":"getting","goverment":"government","grammer":"grammar",
    "greatful":"grateful","guarentee":"guarantee","guidence":"guidance",
    // H
    "haev":"have","happend":"happened","hapening":"happening","harrassment":"harassment",
    "heigth":"height","hapen":"happen","havnt":"haven't","heirarchy":"hierarchy",
    "helpfull":"helpful","hge":"huge","hierachry":"hierarchy","hisself":"himself",
    "hobbies":"hobbies","hopefuly":"hopefully","horizantal":"horizontal","howver":"however",
    // I
    "ignorence":"ignorance","ilegal":"illegal","imaginery":"imaginary","imediately":"immediately",
    "imeadiatly":"immediately","immedietly":"immediately","immeditly":"immediately",
    "implemnt":"implement","importent":"important","imposible":"impossible",
    "impresive":"impressive","inadvertant":"inadvertent","incase":"in case",
    "incidently":"incidentally","independance":"independence","indispensible":"indispensable",
    "infered":"inferred","interupt":"interrupt","intresting":"interesting",
    "irregardless":"regardless","irresistable":"irresistible",
    "isnt":"isn't","itms":"items",
    // J K L
    "judgement":"judgment","knowlege":"knowledge","knwo":"know","laguage":"language",
    "langauge":"language","laready":"already","leanr":"learn","learnign":"learning",
    "leathr":"leather","lenght":"length","liasion":"liaison","libary":"library",
    "lisense":"license","litle":"little","litrally":"literally","loosing":"losing",
    // M
    "maintance":"maintenance","maintenence":"maintenance","managment":"management",
    "maufacture":"manufacture","medically":"medically","memeber":"member",
    "mesage":"message","millenia":"millennia","millenium":"millennium","mispell":"misspell",
    "mroe":"more","myslef":"myself",
    // N
    "necesary":"necessary","neccessary":"necessary","negociate":"negotiate",
    "noticable":"noticeable","nowdays":"nowadays","nuisanse":"nuisance",
    // O
    "occured":"occurred","occurence":"occurrence","occurance":"occurrence",
    "ofcourse":"of course","offical":"official","omision":"omission","omitt":"omit",
    "onece":"once","optinal":"optional","orginize":"organize","orignal":"original",
    "ouput":"output","overide":"override","ovelap":"overlap",
    // P
    "paralel":"parallel","peice":"piece","peolpe":"people","percieve":"perceive",
    "performace":"performance","permenant":"permanent","persevearance":"perseverance",
    "persistance":"persistence","personel":"personnel","plateu":"plateau","playright":"playwright",
    "posible":"possible","pospone":"postpone","practise":"practice","preceed":"precede",
    "prefered":"preferred","prepair":"prepare","privelege":"privilege","priviledge":"privilege",
    "probelm":"problem","proceeed":"proceed","proffesional":"professional",
    "programing":"programming","pronounciation":"pronunciation","publically":"publicly",
    // Q R
    "questionaire":"questionnaire","realy":"really","recieve":"receive",
    "reccomend":"recommend","recomend":"recommend","recurrring":"recurring",
    "referance":"reference","relevent":"relevant","remeber":"remember",
    "repitition":"repetition","reposnd":"respond","resposne":"response",
    "retreive":"retrieve","rythm":"rhythm",
    // S
    "sacrifise":"sacrifice","saftey":"safety","saveing":"saving","secratary":"secretary",
    "seperate":"separate","sepearte":"separate","seprate":"separate",
    "simalar":"similar","similer":"similar","simalr":"similar",
    "sinse":"since","skillset":"skill set","soem":"some","somthing":"something",
    "speach":"speech","specifally":"specifically","statment":"statement",
    "strech":"stretch","studing":"studying","succesful":"successful","succesfull":"successful",
    "suttle":"subtle","sytem":"system",
    // T
    "tahn":"than","taht":"that","teh":"the","thats":"that's","thay":"they",
    "thier":"their","thign":"thing","thigns":"things","thsi":"this",
    "tommorow":"tomorrow","tomorrrow":"tomorrow","tounge":"tongue","truely":"truly",
    "typo":"typo","tyranny":"tyranny",
    // U V W
    "unforseen":"unforeseen","unfortunatly":"unfortunately","untill":"until",
    "usefull":"useful","vrey":"very","visable":"visible","waht":"what",
    "whcih":"which","wher":"where","whith":"with","wierd":"weird","wieth":"with",
    "wirte":"write","wnat":"want","wnated":"wanted","wokring":"working","wordl":"world",
    "wroking":"working","woudl":"would","wouldnt":"wouldn't","writting":"writing",
    "wrogn":"wrong",
    // Y
    "yoru":"your","youre":"you're","ytou":"you","yuor":"your",
]

// MARK: - Caffeine (prevent display sleep)
var caffeineAssertionID: IOPMAssertionID = 0
var isCaffeinated = false

func enableCaffeine() {
    guard !isCaffeinated else { return }
    let reason = "GhostFinisher caffeine" as CFString
    let result = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep as CFString,
                                             IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                             reason, &caffeineAssertionID)
    isCaffeinated = (result == kIOReturnSuccess)
}

func disableCaffeine() {
    guard isCaffeinated else { return }
    IOPMAssertionRelease(caffeineAssertionID)
    caffeineAssertionID = 0
    isCaffeinated = false
}

// MARK: - State
var wordBuffer       = ""
var isEnabled        = true
var eventTap: CFMachPort?

// Auto-correct undo state
// When we auto-correct "saikianr" → "Saikiran", we store the original
// so that the very next backspace can revert it.
struct AutoCorrectRecord {
    let original: String   // what the user actually typed
    let corrected: String  // what we replaced it with
}
var lastAutoCorrect: AutoCorrectRecord? = nil
var justAutoCorrected = false

// Injection marker — stamped on every event we inject so the tap ignores them
let GHOST_MARKER: Int64 = 0x47484F5354
let injectionSource = CGEventSource(stateID: .combinedSessionState)

// MARK: - Edit distance (Levenshtein, capped)
func editDistance(_ a: String, _ b: String, cap: Int = 3) -> Int {
    let a = Array(a.lowercased()), b = Array(b.lowercased())
    let m = a.count, n = b.count
    guard abs(m - n) <= cap else { return cap + 1 }
    var row = Array(0...n)
    for i in 1...m {
        var prev = row[0]; row[0] = i
        for j in 1...n {
            let tmp = row[j]
            row[j] = a[i-1] == b[j-1] ? prev : min(prev, min(row[j], row[j-1])) + 1
            prev = tmp
        }
        if row.min()! > cap { return cap + 1 }
    }
    return row[n]
}

// MARK: - Match kinds
enum MatchKind {
    case prefix(tail: String, word: String)
    case spell(word: String)
    case fuzzy(word: String)
}

// Live suggestion while typing (Tab/→ to accept)
func bestMatch(for input: String) -> MatchKind? {
    guard input.count >= 2 else { return nil }
    let lower = input.lowercased()
    if let hit = ghostDictionary.first(where: { $0.lowercased().hasPrefix(lower) }) {
        let tail = String(hit.dropFirst(input.count))
        return tail.isEmpty ? nil : .prefix(tail: tail, word: hit)
    }
    if input.count >= 3 {
        var bestDist = 3; var bestWord: String?
        for word in ghostDictionary {
            guard abs(word.count - input.count) <= 2 else { continue }
            let d = editDistance(lower, word, cap: 2)
            if d < bestDist { bestDist = d; bestWord = word }
        }
        if let w = bestWord, bestDist <= 2 { return .spell(word: w) }
    }
    if let hit = ghostDictionary.first(where: { word in
        var idx = word.lowercased().startIndex
        for ch in lower {
            guard let f = word.lowercased()[idx...].firstIndex(of: ch) else { return false }
            idx = word.lowercased().index(after: f)
        }
        return true
    }) { return .fuzzy(word: hit) }
    return nil
}

// Auto-correct candidate when the user finishes a word (hits space/punctuation)
func autoCorrectCandidate(for input: String) -> String? {
    guard input.count >= 2 else { return nil }
    let lower = input.lowercased()
    // 1 — Explicit typo map: instant lookup, highest confidence
    if let fix = typoMap[lower] { return fix }
    // 2 — Already a valid word — don't touch it
    if ghostDictionary.contains(where: { $0.lowercased() == lower }) { return nil }
    // 3 — Fuzzy Levenshtein fallback for words not in the typo map
    guard input.count >= 3 else { return nil }
    var bestDist = 3; var bestWord: String?
    for word in ghostDictionary {
        guard abs(word.count - input.count) <= 2 else { continue }
        let d = editDistance(lower, word, cap: 2)
        if d < bestDist { bestDist = d; bestWord = word }
    }
    if let w = bestWord, bestDist <= 2 { return w }
    return nil
}

// MARK: - Position helpers
// Returns the screen position just below the text cursor.
// Tries 4 sources in order of precision.
func badgeOrigin(windowWidth: CGFloat = 200, windowHeight: CGFloat = 28) -> NSPoint {
    // 1 — exact caret bounds via AX — place badge just ABOVE the line so eyes
    //     don't need to travel far from the text being typed
    if let rect = caretRect() {
        let (pt, lineH) = nsFlip(rect)
        return NSPoint(x: pt.x, y: pt.y + lineH + 4)
    }
    // 2 — focused element frame (Illustrator layer rename, text tool, etc.)
    if let rect = focusedElementRect() {
        let (pt, h) = nsFlip(rect)
        return NSPoint(x: rect.minX, y: pt.y - h - 6)
    }
    // 3 — focused window bottom-left
    if let rect = focusedWindowRect() {
        let (pt, _) = nsFlip(rect)
        return NSPoint(x: rect.minX + 16, y: pt.y + 6)
    }
    // 4 — mouse (last resort)
    let m = NSEvent.mouseLocation
    return NSPoint(x: m.x + 10, y: m.y - 36)
}

func caretRect() -> CGRect? {
    let sys = AXUIElementCreateSystemWide()
    var raw: AnyObject?
    guard AXUIElementCopyAttributeValue(sys, kAXFocusedUIElementAttribute as CFString, &raw) == .success else { return nil }
    let el = raw as! AXUIElement
    var rangeRaw: AnyObject?
    guard AXUIElementCopyAttributeValue(el, kAXSelectedTextRangeAttribute as CFString, &rangeRaw) == .success,
          let rv = rangeRaw else { return nil }
    var boundsRaw: AnyObject?
    guard AXUIElementCopyParameterizedAttributeValue(el, kAXBoundsForRangeParameterizedAttribute as CFString, rv, &boundsRaw) == .success,
          let bv = boundsRaw else { return nil }
    var r = CGRect.zero
    guard AXValueGetValue(bv as! AXValue, .cgRect, &r), r != .zero else { return nil }
    return r
}

func focusedElementRect() -> CGRect? {
    let sys = AXUIElementCreateSystemWide()
    var raw: AnyObject?
    guard AXUIElementCopyAttributeValue(sys, kAXFocusedUIElementAttribute as CFString, &raw) == .success else { return nil }
    let el = raw as! AXUIElement
    var frameRaw: AnyObject?
    guard AXUIElementCopyAttributeValue(el, "AXFrame" as CFString, &frameRaw) == .success,
          let fv = frameRaw else { return nil }
    var r = CGRect.zero
    guard AXValueGetValue(fv as! AXValue, .cgRect, &r), !r.isEmpty else { return nil }
    return r
}

func focusedWindowRect() -> CGRect? {
    let sys = AXUIElementCreateSystemWide()
    var appRaw: AnyObject?
    guard AXUIElementCopyAttributeValue(sys, kAXFocusedApplicationAttribute as CFString, &appRaw) == .success else { return nil }
    let app = appRaw as! AXUIElement
    var winRaw: AnyObject?
    guard AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &winRaw) == .success,
          let win = winRaw else { return nil }
    var frameRaw: AnyObject?
    guard AXUIElementCopyAttributeValue(win as! AXUIElement, "AXFrame" as CFString, &frameRaw) == .success,
          let fv = frameRaw else { return nil }
    var r = CGRect.zero
    AXValueGetValue(fv as! AXValue, .cgRect, &r)
    return r.isEmpty ? nil : r
}

// Quartz (top-left origin) → AppKit (bottom-left origin)
func nsFlip(_ rect: CGRect) -> (point: NSPoint, height: CGFloat) {
    let screen = NSScreen.screens.first { $0.frame.contains(NSPoint(x: rect.midX, y: rect.midY)) } ?? NSScreen.main!
    return (NSPoint(x: rect.minX, y: screen.frame.height - rect.maxY), rect.height)
}

func caretFontSize() -> CGFloat {
    let sys = AXUIElementCreateSystemWide()
    var raw: AnyObject?
    guard AXUIElementCopyAttributeValue(sys, kAXFocusedUIElementAttribute as CFString, &raw) == .success else { return 14 }
    var fontRaw: AnyObject?
    guard AXUIElementCopyAttributeValue(raw as! AXUIElement, "AXFont" as CFString, &fontRaw) == .success,
          let d = fontRaw as? [String: Any], let sz = d["AXFontSize"] as? CGFloat else { return 14 }
    return max(11, min(sz, 36))
}

// MARK: - Ghost window
class GhostWindow: NSPanel {
    private let label = NSTextField(labelWithString: "")
    private var hideTimer: Timer?

    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
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

    // Inline ghost text (only the tail) — sits right at cursor
    func showInline(tail: String, caret: CGRect) {
        hideTimer?.invalidate()
        contentView?.layer?.backgroundColor = .none
        contentView?.layer?.cornerRadius = 0
        hasShadow = false
        let (origin, lineH) = nsFlip(caret)
        let fontSize = caretFontSize()
        let str = NSMutableAttributedString(string: tail + "  ⇥", attributes: [
            .foregroundColor: NSColor(white: 0.55, alpha: 0.70),
            .font: NSFont.systemFont(ofSize: fontSize, weight: .regular)
        ])
        label.attributedStringValue = str
        label.sizeToFit()
        let w = label.frame.width + 2
        let h = max(lineH, fontSize + 4)
        setContentSize(NSSize(width: w, height: h))
        setFrameOrigin(NSPoint(x: origin.x, y: origin.y + (h - fontSize) * 0.5))
        label.frame = NSRect(x: 0, y: 0, width: w, height: h)
        orderFront(nil)
    }

    // Inline correction — shown at cursor for spell/fuzzy matches in amber so
    // it's visible in peripheral vision without the user looking away from text.
    func showInlineCorrection(word: String, caret: CGRect) {
        hideTimer?.invalidate()
        contentView?.layer?.backgroundColor = .none
        contentView?.layer?.cornerRadius = 0
        hasShadow = false
        let (origin, lineH) = nsFlip(caret)
        let fontSize = caretFontSize()
        let str = NSMutableAttributedString()
        str.append(NSAttributedString(string: " → ", attributes: [
            .foregroundColor: NSColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 0.75),
            .font: NSFont.systemFont(ofSize: fontSize * 0.85, weight: .regular)
        ]))
        str.append(NSAttributedString(string: word, attributes: [
            .foregroundColor: NSColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 0.85),
            .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold)
        ]))
        str.append(NSAttributedString(string: "  ⇥", attributes: [
            .foregroundColor: NSColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 0.50),
            .font: NSFont.systemFont(ofSize: fontSize * 0.80, weight: .light)
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

    // Badge — suggestions, corrections, and warnings
    // autoDismiss nil = stays until next word boundary (best for fast typing)
    func showBadge(text: NSAttributedString, autoDismiss: TimeInterval? = nil,
                   bgOverride: NSColor? = nil) {
        hideTimer?.invalidate()
        hasShadow = true
        let dark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let defaultBg = dark ? NSColor(white: 0.12, alpha: 0.95) : NSColor(white: 0.94, alpha: 0.97)
        let bg = bgOverride ?? defaultBg
        contentView?.layer?.backgroundColor = bg.cgColor
        contentView?.layer?.cornerRadius = 8

        label.attributedStringValue = text
        label.sizeToFit()
        let w = label.frame.width + 24
        let h: CGFloat = 34          // taller = easier to see at speed
        setContentSize(NSSize(width: w, height: h))
        label.frame = NSRect(x: 12, y: (h - label.frame.height) / 2,
                             width: label.frame.width, height: label.frame.height)

        var origin = badgeOrigin(windowWidth: w, windowHeight: h)
        if let scr = NSScreen.main?.visibleFrame {
            origin.x = min(max(origin.x, scr.minX + 4), scr.maxX - w - 4)
            origin.y = max(origin.y, scr.minY + 4)
        }
        setFrameOrigin(origin)
        orderFront(nil)

        if let delay = autoDismiss {
            hideTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                self?.hide()
            }
        }
    }

    func hide() {
        hideTimer?.invalidate()
        hideTimer = nil
        orderOut(nil)
    }
}

let ghost = GhostWindow()

// MARK: - Badge builders
func makeSuggestionBadge(word: String, typed: String, prefix: String) -> NSAttributedString {
    let str = NSMutableAttributedString()
    str.append(NSAttributedString(string: prefix + " ", attributes: [
        .foregroundColor: NSColor.secondaryLabelColor,
        .font: NSFont.systemFont(ofSize: 12, weight: .light)
    ]))
    let lower = typed.lowercased()
    var used = IndexSet(); var si = word.lowercased().startIndex
    for ch in lower {
        if let f = word.lowercased()[si...].firstIndex(of: ch) {
            used.insert(word.lowercased().distance(from: word.startIndex, to: f))
            si = word.lowercased().index(after: f)
        }
    }
    for (i, ch) in word.enumerated() {
        str.append(NSAttributedString(string: String(ch), attributes: [
            .foregroundColor: used.contains(i) ? NSColor.labelColor : NSColor.secondaryLabelColor,
            .font: NSFont.systemFont(ofSize: 15, weight: used.contains(i) ? .semibold : .regular)
        ]))
    }
    return str
}

func makeAutoCorrectedBadge(original: String, corrected: String) -> NSAttributedString {
    let str = NSMutableAttributedString()
    let light: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.secondaryLabelColor,
                                                 .font: NSFont.systemFont(ofSize: 12, weight: .regular)]
    let bold: [NSAttributedString.Key: Any]  = [.foregroundColor: NSColor.labelColor,
                                                 .font: NSFont.systemFont(ofSize: 15, weight: .semibold)]
    str.append(NSAttributedString(string: "✦ ", attributes: light))
    str.append(NSAttributedString(string: corrected, attributes: bold))
    str.append(NSAttributedString(string: "  ↩ undo", attributes: light))
    return str
}

// Shown when 5+ chars typed and no dictionary match found — "you're making a mistake"
func makeWarningBadge(typed: String) -> NSAttributedString {
    let str = NSMutableAttributedString()
    str.append(NSAttributedString(string: "⚠ ", attributes: [
        .foregroundColor: NSColor(red: 1, green: 0.6, blue: 0, alpha: 1),
        .font: NSFont.systemFont(ofSize: 13, weight: .semibold)
    ]))
    str.append(NSAttributedString(string: typed, attributes: [
        .foregroundColor: NSColor.labelColor,
        .font: NSFont.systemFont(ofSize: 15, weight: .regular)
    ]))
    str.append(NSAttributedString(string: " ?", attributes: [
        .foregroundColor: NSColor.secondaryLabelColor,
        .font: NSFont.systemFont(ofSize: 13, weight: .light)
    ]))
    return str
}

// MARK: - Show suggestion (main thread)
func showSuggestion(match: MatchKind, typed: String) {
    switch match {
    case .prefix(let tail, let word):
        if let rect = caretRect() { ghost.showInline(tail: tail, caret: rect) }
        else { ghost.showBadge(text: makeSuggestionBadge(word: word, typed: typed, prefix: "⇥")) }
    case .spell(let word):
        // Prefer inline at cursor so it's visible without looking away from text
        if let rect = caretRect() { ghost.showInlineCorrection(word: word, caret: rect) }
        else { ghost.showBadge(text: makeSuggestionBadge(word: word, typed: typed, prefix: "✦")) }
    case .fuzzy(let word):
        if let rect = caretRect() { ghost.showInlineCorrection(word: word, caret: rect) }
        else { ghost.showBadge(text: makeSuggestionBadge(word: word, typed: typed, prefix: "⇥")) }
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
    for ch in text { if let c = keyMap[Character(ch.lowercased())] { postKey(keyCode: c, shift: ch.isUppercase) } }
}

func deleteChars(_ n: Int) {
    for _ in 0..<n { postKey(keyCode: 51, shift: false) }
}

func acceptMatch(_ match: MatchKind, typedCount: Int) {
    switch match {
    case .prefix(let tail, _):
        typeString(tail)                     // only inject the tail — instant, no sleep needed
    case .spell(let word), .fuzzy(let word):
        deleteChars(typedCount)
        Thread.sleep(forTimeInterval: 0.020) // 20ms — enough for Electron/Notion to catch up
        typeString(word)
    }
}

// MARK: - Menu Bar
class MenuBarController: NSObject {
    var item: NSStatusItem!
    var caffeineItem: NSMenuItem!

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
        caffeineItem = NSMenuItem(title: "☕ Caffeine: Off", action: #selector(toggleCaffeine), keyEquivalent: "")
        caffeineItem.target = self
        menu.addItem(caffeineItem)
        menu.addItem(.separator())
        let add = NSMenuItem(title: "Add clipboard word to dictionary", action: #selector(addWord), keyEquivalent: "")
        add.target = self; menu.addItem(add)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Ghost Finisher", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
        // Auto-enable caffeine on launch
        enableCaffeine()
        updateCaffeineItem()
    }
    func updateIcon() {
        item.button?.title   = isEnabled ? "👻" : "💤"
        item.button?.toolTip = isEnabled ? "Ghost Finisher active — ⌘⇧G to pause" : "Ghost Finisher paused — ⌘⇧G to resume"
        (item.menu?.items.first)?.title = isEnabled ? "Pause Ghost Finisher" : "Resume Ghost Finisher"
    }
    func updateCaffeineItem() {
        caffeineItem?.title = isCaffeinated ? "☕ Caffeine: On — display won't sleep" : "☕ Caffeine: Off"
        caffeineItem?.state = isCaffeinated ? .on : .off
    }
    @objc func toggleEnabled() {
        isEnabled.toggle(); wordBuffer = ""; ghost.hide(); updateIcon()
    }
    @objc func toggleCaffeine() {
        if isCaffeinated { disableCaffeine() } else { enableCaffeine() }
        updateCaffeineItem()
    }
    @objc func addWord() {
        guard let w = NSPasteboard.general.string(forType: .string)?
                        .trimmingCharacters(in: .whitespacesAndNewlines),
              !w.isEmpty, w.count < 40, w.allSatisfy({ $0.isLetter }),
              !personalDictionary.contains(w) else { return }
        personalDictionary.append(w)
        let a = NSAlert(); a.messageText = "Added"
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

    // Skip our own injected events
    if event.getIntegerValueField(.eventSourceUserData) == GHOST_MARKER {
        return Unmanaged.passRetained(event)
    }

    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let flags   = event.flags

    // ⌘⇧G — toggle
    if keyCode == 5, flags.contains(.maskCommand), flags.contains(.maskShift) {
        DispatchQueue.main.async { (NSApp.delegate as? AppDelegate)?.menuBar.toggleEnabled() }
        return nil
    }

    guard isEnabled else { return Unmanaged.passRetained(event) }

    // ── Backspace ─────────────────────────────────────────────────────────
    if keyCode == 51 {
        // Undo last auto-correct — fires when user hits backspace right after correction
        if justAutoCorrected, let ac = lastAutoCorrect {
            justAutoCorrected = false
            lastAutoCorrect   = nil
            wordBuffer        = ""
            let corrected = ac.corrected
            let original  = ac.original
            DispatchQueue.main.async { ghost.hide() }
            DispatchQueue.global(qos: .userInteractive).async {
                // Delete corrected word + the space we injected
                deleteChars(corrected.count + 1)
                Thread.sleep(forTimeInterval: 0.020)
                typeString(original)   // put the original typo back
            }
            return nil  // consume this backspace
        }
        justAutoCorrected = false
        lastAutoCorrect   = nil
        if !wordBuffer.isEmpty { wordBuffer.removeLast() }
        if wordBuffer.isEmpty { DispatchQueue.main.async { ghost.hide() } }
        else if let m = bestMatch(for: wordBuffer) {
            let s = wordBuffer
            DispatchQueue.main.async { showSuggestion(match: m, typed: s) }
        } else { DispatchQueue.main.async { ghost.hide() } }
        return Unmanaged.passRetained(event)
    }

    // ── Tab or Right Arrow — manual accept ────────────────────────────────
    let isAccept = keyCode == 48 || keyCode == 124
    if isAccept, !wordBuffer.isEmpty, let match = bestMatch(for: wordBuffer) {
        let count = wordBuffer.count; let snap = match
        wordBuffer = ""; justAutoCorrected = false; lastAutoCorrect = nil
        DispatchQueue.main.async { ghost.hide() }
        DispatchQueue.global(qos: .userInteractive).async { acceptMatch(snap, typedCount: count) }
        return nil
    }

    // ── Space / Return / Punctuation — word boundary + auto-correct ───────
    // keyCodes: space=49, return=36, .=47, ,=43, ;=41, :=39
    let isBoundary = keyCode == 49 || keyCode == 36 || keyCode == 47 ||
                     keyCode == 43 || keyCode == 41 || keyCode == 39
    if isBoundary && !wordBuffer.isEmpty {
        let typed    = wordBuffer
        let boundaryCode = keyCode
        wordBuffer        = ""
        justAutoCorrected = false
        lastAutoCorrect   = nil

        if let corrected = autoCorrectCandidate(for: typed) {
            // Consume the boundary key — we will re-inject it ourselves after the
            // corrected word. This means we never have a timing race where the
            // boundary is already in the text when we start deleting.
            DispatchQueue.main.async { ghost.hide() }
            DispatchQueue.global(qos: .userInteractive).async {
                Thread.sleep(forTimeInterval: 0.010)
                deleteChars(typed.count)
                Thread.sleep(forTimeInterval: 0.020)
                typeString(corrected)
                // Re-inject the original boundary (space, period, comma, etc.)
                postKey(keyCode: CGKeyCode(boundaryCode), shift: false)
            }
            DispatchQueue.main.async {
                let badge = makeAutoCorrectedBadge(original: typed, corrected: corrected)
                ghost.showBadge(text: badge)
                lastAutoCorrect   = AutoCorrectRecord(original: typed, corrected: corrected)
                justAutoCorrected = true
            }
            return nil  // consume — we re-inject the boundary ourselves
        }

        DispatchQueue.main.async { ghost.hide() }
        return Unmanaged.passRetained(event)
    }

    // ── Escape ────────────────────────────────────────────────────────────
    if keyCode == 53 {
        wordBuffer = ""; justAutoCorrected = false; lastAutoCorrect = nil
        DispatchQueue.main.async { ghost.hide() }
        return Unmanaged.passRetained(event)
    }

    // ── Modifier combos ───────────────────────────────────────────────────
    if flags.contains(.maskCommand) || flags.contains(.maskControl) {
        wordBuffer = ""; justAutoCorrected = false; lastAutoCorrect = nil
        DispatchQueue.main.async { ghost.hide() }
        return Unmanaged.passRetained(event)
    }

    // ── Letter ────────────────────────────────────────────────────────────
    var uLen = 0; var uBuf = [UniChar](repeating: 0, count: 4)
    event.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &uLen, unicodeString: &uBuf)
    let chars = String(uBuf.prefix(uLen).compactMap { UnicodeScalar($0).map(Character.init) })

    if chars.count == 1, let ch = chars.first, ch.isLetter {
        justAutoCorrected = false
        wordBuffer.append(ch)
        if let m = bestMatch(for: wordBuffer) {
            let s = wordBuffer
            DispatchQueue.main.async { showSuggestion(match: m, typed: s) }
        } else if wordBuffer.count >= 5 {
            // 5+ chars with no match = likely a typo in progress — warn the user
            let s = wordBuffer
            DispatchQueue.main.async {
                let warn = makeWarningBadge(typed: s)
                ghost.showBadge(text: warn,
                                bgOverride: NSColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 0.15))
            }
        } else {
            DispatchQueue.main.async { ghost.hide() }
        }
        return Unmanaged.passRetained(event)
    }

    // Any other key = word boundary
    wordBuffer = ""; justAutoCorrected = false; lastAutoCorrect = nil
    DispatchQueue.main.async { ghost.hide() }
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
    func applicationWillTerminate(_ n: Notification) {
        disableCaffeine()
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
        a.addButton(withTitle: "Open System Settings"); a.addButton(withTitle: "Quit")
        if a.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!)
        }
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
