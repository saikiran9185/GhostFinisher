#!/usr/bin/env python3
"""
Generates the GhostFinisher Project Report PDF.
Run: python3 generate_report.py
Output: ~/Desktop/GhostFinisher_Report.pdf
"""

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    HRFlowable, PageBreak
)
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT
import os

OUTPUT = os.path.expanduser("~/Desktop/GhostFinisher_Report.pdf")

# ── Colour palette ──────────────────────────────────────────────────────────
GHOST_PURPLE  = colors.HexColor("#7B5EA7")
GHOST_DARK    = colors.HexColor("#1A1A2E")
GHOST_MID     = colors.HexColor("#2D2D44")
GHOST_LIGHT   = colors.HexColor("#E8E4F0")
ACCENT_GREEN  = colors.HexColor("#4CAF82")
ACCENT_RED    = colors.HexColor("#E05555")
ACCENT_YELLOW = colors.HexColor("#F0A500")
TEXT_BODY     = colors.HexColor("#2C2C2C")
TEXT_MUTED    = colors.HexColor("#666666")

# ── Styles ───────────────────────────────────────────────────────────────────
base = getSampleStyleSheet()

def style(name, parent="Normal", **kw):
    s = ParagraphStyle(name, parent=base[parent], **kw)
    return s

S_COVER_TITLE = style("CoverTitle",
    fontSize=34, leading=40, textColor=colors.white,
    fontName="Helvetica-Bold", alignment=TA_CENTER, spaceAfter=8)

S_COVER_SUB = style("CoverSub",
    fontSize=14, leading=20, textColor=GHOST_LIGHT,
    fontName="Helvetica", alignment=TA_CENTER, spaceAfter=6)

S_COVER_META = style("CoverMeta",
    fontSize=10, leading=14, textColor=colors.HexColor("#BBBBCC"),
    fontName="Helvetica", alignment=TA_CENTER)

S_H1 = style("H1",
    fontSize=20, leading=26, textColor=GHOST_PURPLE,
    fontName="Helvetica-Bold", spaceBefore=18, spaceAfter=8)

S_H2 = style("H2",
    fontSize=14, leading=18, textColor=GHOST_DARK,
    fontName="Helvetica-Bold", spaceBefore=12, spaceAfter=6)

S_BODY = style("Body",
    fontSize=10, leading=15, textColor=TEXT_BODY,
    fontName="Helvetica", spaceAfter=6)

S_MUTED = style("Muted",
    fontSize=9, leading=13, textColor=TEXT_MUTED,
    fontName="Helvetica", spaceAfter=4)

S_CODE = style("Code",
    fontSize=9, leading=13, textColor=colors.HexColor("#C8E6C9"),
    fontName="Courier", backColor=GHOST_MID,
    leftIndent=10, rightIndent=10, spaceBefore=4, spaceAfter=4)

S_BULLET = style("Bullet",
    fontSize=10, leading=15, textColor=TEXT_BODY,
    fontName="Helvetica", leftIndent=16, spaceAfter=3,
    bulletIndent=6)

S_CAPTION = style("Caption",
    fontSize=8, leading=11, textColor=TEXT_MUTED,
    fontName="Helvetica-Oblique", alignment=TA_CENTER, spaceAfter=8)

def hr(color=GHOST_PURPLE, thickness=1):
    return HRFlowable(width="100%", thickness=thickness,
                      color=color, spaceAfter=8, spaceBefore=4)

def sp(h=0.3):
    return Spacer(1, h * cm)

def h1(text):  return Paragraph(text, S_H1)
def h2(text):  return Paragraph(text, S_H2)
def body(text): return Paragraph(text, S_BODY)
def muted(text): return Paragraph(text, S_MUTED)
def code(text): return Paragraph(text, S_CODE)
def bullet(text): return Paragraph(f"• {text}", S_BULLET)

# ── Table helpers ─────────────────────────────────────────────────────────────
def mk_table(data, col_widths, header_bg=GHOST_PURPLE):
    t = Table(data, colWidths=col_widths, repeatRows=1)
    n = len(data)
    style_cmds = [
        ("BACKGROUND",  (0,0), (-1,0),  header_bg),
        ("TEXTCOLOR",   (0,0), (-1,0),  colors.white),
        ("FONTNAME",    (0,0), (-1,0),  "Helvetica-Bold"),
        ("FONTSIZE",    (0,0), (-1,0),  9),
        ("FONTNAME",    (0,1), (-1,-1), "Helvetica"),
        ("FONTSIZE",    (0,1), (-1,-1), 9),
        ("TEXTCOLOR",   (0,1), (-1,-1), TEXT_BODY),
        ("ROWBACKGROUNDS", (0,1), (-1,-1), [colors.white, GHOST_LIGHT]),
        ("GRID",        (0,0), (-1,-1), 0.4, colors.HexColor("#CCCCCC")),
        ("ALIGN",       (0,0), (-1,-1), "LEFT"),
        ("VALIGN",      (0,0), (-1,-1), "MIDDLE"),
        ("TOPPADDING",  (0,0), (-1,-1), 5),
        ("BOTTOMPADDING",(0,0),(-1,-1), 5),
        ("LEFTPADDING", (0,0), (-1,-1), 7),
    ]
    t.setStyle(TableStyle(style_cmds))
    return t

# ── Cover page ────────────────────────────────────────────────────────────────
def cover_page():
    W = A4[0] - 4*cm

    def cstyle(color, size, bold=False, align=TA_CENTER, space=6):
        return ParagraphStyle("_", fontName="Helvetica-Bold" if bold else "Helvetica",
                               fontSize=size, leading=size*1.3, textColor=color,
                               alignment=align, spaceAfter=space)

    # Build cover as a single full-width dark table
    rows = [
        [Paragraph("👻", cstyle(colors.white, 48, align=TA_CENTER, space=4))],
        [Paragraph("Ghost Finisher", cstyle(colors.white, 32, bold=True, space=6))],
        [Paragraph("System-Wide Autocomplete &amp; Spell Correction for macOS",
                   cstyle(GHOST_LIGHT, 13, space=16))],
        [HRFlowable(width="60%", thickness=2, color=GHOST_PURPLE, spaceAfter=14, spaceBefore=0)],
        [Paragraph("Built by Saikiran  |  April 2026", cstyle(colors.HexColor("#AAAACC"), 10, space=4))],
        [Paragraph("github.com/saikiran9185/GhostFinisher", cstyle(colors.HexColor("#AAAACC"), 10, space=4))],
        [Paragraph("Swift 6  •  macOS 13+  •  Apple Silicon  •  Open Source",
                   cstyle(colors.HexColor("#AAAACC"), 9, space=0))],
    ]
    cover_table = Table([[r] for r in rows], colWidths=[W])
    cover_table.setStyle(TableStyle([
        ("BACKGROUND",   (0,0), (-1,-1), GHOST_DARK),
        ("ALIGN",        (0,0), (-1,-1), "CENTER"),
        ("VALIGN",       (0,0), (-1,-1), "MIDDLE"),
        ("TOPPADDING",   (0,0), (-1,-1), 10),
        ("BOTTOMPADDING",(0,0), (-1,-1), 10),
        ("TOPPADDING",   (0,0), (0,0),   60),   # top breathing room
        ("BOTTOMPADDING",(0,6), (0,6),   50),   # bottom breathing room
    ]))
    return [cover_table, PageBreak()]

# ── Build document ────────────────────────────────────────────────────────────
def build():
    doc = SimpleDocTemplate(
        OUTPUT, pagesize=A4,
        leftMargin=2*cm, rightMargin=2*cm,
        topMargin=2*cm, bottomMargin=2*cm,
        title="Ghost Finisher — Project Report",
        author="Saikiran",
    )

    W = A4[0] - 4*cm  # usable width

    story = []
    story += cover_page()

    # ── 1. Project Overview ───────────────────────────────────────────────────
    story += [h1("1. Project Overview"), hr()]
    story += [body(
        "Ghost Finisher is a silent macOS background utility that provides system-wide "
        "word completion and automatic spell correction as you type — in any application. "
        "Unlike macOS's built-in predictive text (which only works in native Apple apps), "
        "Ghost Finisher intercepts keystrokes at the OS level using <b>CGEventTap</b>, "
        "allowing it to function in Adobe Illustrator, VS Code, Electron apps, and more."
    ), sp(0.2)]
    story += [body(
        "The project was built entirely in Swift as a single-file command-line app compiled "
        "into a macOS <b>.app bundle</b>. It runs silently in the background with no Dock icon, "
        "accessible only through a 👻 menu bar icon."
    ), sp(0.4)]

    story += [h2("Core Problem It Solves")]
    story += [bullet("macOS spell check only works in native Apple apps — not in Illustrator, VS Code, or Electron apps")]
    story += [bullet("No existing tool provides inline ghost text system-wide across all applications")]
    story += [bullet("Dyslexic or fast typists need real-time correction without switching tools")]
    story += [bullet("Browser spell check works in Chrome but not in desktop apps")]
    story += [sp(0.4)]

    story += [h2("Key Technical Achievement")]
    story += [body(
        "The core insight that makes Ghost Finisher work where others fail: instead of trying "
        "to <i>read</i> the text field (which Adobe and Electron apps block), it intercepts "
        "keystrokes <i>before</i> they reach any app and builds its own word buffer from the "
        "keystroke stream. This works in every app, including Adobe Illustrator's layer rename "
        "panel and custom canvas text tool."
    ), sp(0.5)]

    # ── 2. Architecture ───────────────────────────────────────────────────────
    story += [h1("2. Technical Architecture"), hr()]

    arch_data = [
        ["Component", "Technology", "Purpose"],
        ["Keystroke Interceptor", "CGEventTap (CoreGraphics)", "Intercepts ALL keystrokes at OS level before any app sees them"],
        ["Word Buffer", "Swift String", "Builds current word from keystroke stream — no text field reading needed"],
        ["Spell Correction", "Levenshtein Edit Distance", "Finds closest dictionary word (distance ≤ 2) for auto-correct on space"],
        ["Prefix Completion", "Linear scan with hasPrefix", "Instant prefix matching (<1ms) for ghost text suggestions"],
        ["Fuzzy Matching", "In-order character search", "Matches 'ilu' → 'Illustrator' when characters appear in sequence"],
        ["Cursor Position", "AXUIElement (Accessibility API)", "Reads text cursor screen coordinates for precise badge placement"],
        ["Ghost Window", "NSPanel (.floating level)", "Transparent overlay window that sits above all other apps"],
        ["Text Injection", "CGEventPost (.cghidEventTap)", "Injects corrected text as real system keystrokes"],
        ["Injection Guard", "CGEvent userData marker (0x47484F5354)", "Prevents injected events from re-triggering the word buffer"],
        ["Login Item", "SMAppService", "Auto-registers app to launch at every login (macOS 13+)"],
        ["Menu Bar", "NSStatusItem", "👻 icon for pause/resume and adding personal words"],
    ]
    story += [mk_table(arch_data,
        [3.2*cm, 4.2*cm, W - 7.4*cm]), sp(0.5)]

    story += [h2("Event Pipeline")]
    story += [code("User keystroke → CGEventTap callback → Injection marker check → Key router")]
    story += [code("    ├── Space/Return → autoCorrectCandidate() → delete + retype + badge")]
    story += [code("    ├── Tab / → → acceptMatch() → typeString(tail) or nuke+retype")]
    story += [code("    ├── Backspace → undo last auto-correct OR trim buffer")]
    story += [code("    └── Letter → buffer.append() → bestMatch() → showSuggestion()")]
    story += [sp(0.3)]

    story += [h2("Injection Speed Optimisation")]
    story += [body(
        "Prefix completions (e.g. <b>fin → final</b>) only inject the <i>tail</i> characters "
        "('al'), not the full word. This eliminates the backspace+sleep+retype cycle and "
        "reduces injection time from ~17ms to ~1.5ms — a <b>10× speedup</b>."
    )]
    story += [body(
        "Fuzzy and spell corrections still use the Backspace Nuke (delete wrong word, retype "
        "correct word) with a 5ms sleep — reduced from the original 15ms."
    ), sp(0.5)]

    # ── 3. Features ───────────────────────────────────────────────────────────
    story += [PageBreak(), h1("3. Features"), hr()]

    feat_data = [
        ["Feature", "How It Works", "Accept Key"],
        ["Inline ghost text", "Tail of prefix match rendered at exact cursor position via AXUIElement", "→ or Tab"],
        ["Spell correction badge", "Edit distance ≤ 2 match shown as ✦ badge near text field", "→ or Tab"],
        ["Fuzzy match badge", "Letters-in-order match shown as ⇥ badge", "→ or Tab"],
        ["Auto-correct on space", "On word boundary: detects distance-1 typo, silently corrects", "Automatic"],
        ["Backspace to undo", "Immediately after auto-correct: reverts to original typed word", "Backspace"],
        ["Personal dictionary", "Custom words (Saikiran, Illustrator, Notchly) always highest priority", "Always on"],
        ["⌘⇧G global toggle", "Pause/resume from anywhere via keyboard shortcut", "⌘⇧G"],
        ["Add word from clipboard", "Copy any word → click 👻 → Add clipboard word", "Menu click"],
        ["Auto-launch at login", "Registers via SMAppService — starts automatically on every reboot", "Automatic"],
        ["No Dock icon", "LSUIElement = true — completely silent", "Always on"],
    ]
    story += [mk_table(feat_data,
        [3.5*cm, W - 7*cm, 2.5*cm* (W/(W))* 1]), sp(0.5)]

    story += [h2("Dictionary")]
    story += [body(
        "Ghost Finisher ships with <b>300+ words</b> across two tiers:"
    )]
    story += [bullet("<b>Personal dictionary</b> — 15 custom words (Saikiran, Illustrator, Notchly, etc.) — highest priority, always checked first")]
    story += [bullet("<b>English dictionary</b> — top ~300 most common English words + most commonly misspelled words (receive, definitely, necessary, etc.)")]
    story += [bullet("User can add any word via clipboard at runtime — persists for the current session")]
    story += [sp(0.5)]

    # ── 4. Compatibility ──────────────────────────────────────────────────────
    story += [h1("4. Compatibility — Where It Works"), hr()]

    compat_data = [
        ["Application / Context", "Ghost Text", "Auto-correct", "Badge Position", "Notes"],
        ["Notes, Pages, Mail, Messages", "✅ Inline", "✅", "At cursor", "Full AX support"],
        ["Finder file rename", "✅ Inline", "✅", "Below field", "Native NSTextField"],
        ["Spotlight search", "✅ Inline", "✅", "Below bar", "Full AX support"],
        ["VS Code (editor)", "✅ Inline", "✅", "At cursor", "AX exposed"],
        ["Slack desktop", "✅ Inline", "✅", "At cursor", "Full AX support"],
        ["Save / Open dialogs", "✅ Inline", "✅", "At cursor", "Native text fields"],
        ["Notion desktop", "✅ Inline", "✅", "At cursor", "Electron + AX"],
        ["Adobe Illustrator layer rename", "❌ Badge", "✅", "Below field", "Custom UI, AX partial"],
        ["Adobe Illustrator text tool", "❌ Badge", "✅", "Below canvas", "Canvas render, no caret"],
        ["Figma text fields", "❌ Badge", "✅", "Below window", "Custom renderer"],
        ["Chrome text areas / forms", "❌ Badge", "✅", "Below element", "AX limited in Chrome"],
        ["ChatGPT / web apps", "❌ Badge", "✅", "Below window", "Browser limitation"],
        ["Electron apps (general)", "❌ Badge", "✅", "Below window", "Custom Chromium renderer"],
    ]
    story += [mk_table(compat_data,
        [4*cm, 1.8*cm, 1.8*cm, 2.2*cm, W - 9.8*cm]), sp(0.4)]

    story += [h2("Where It Will Never Work")]
    never_data = [
        ["Place", "Reason", "Alternative"],
        ["Terminal prompt", "Raw PTY byte stream — no text layer", "zsh-autosuggestions"],
        ["Browser URL / address bar", "Chrome/Safari lock AX access", "None"],
        ["Password fields", "macOS Secure Input — by design", "None (correct)"],
        ["Password manager popups", "Triggers Secure Input mode", "None"],
        ["Fullscreen games", "Block all accessibility APIs", "None"],
        ["Remote Desktop / VMs", "Events go to remote machine", "None"],
    ]
    story += [mk_table(never_data,
        [3.8*cm, W - 7.8*cm, 3*cm * (W / W)]), sp(0.5)]

    # ── 5. Comparison ─────────────────────────────────────────────────────────
    story += [PageBreak(), h1("5. Comparison with Existing Solutions"), hr()]

    comp_data = [
        ["Feature", "Ghost Finisher", "macOS Built-in", "Grammarly", "LanguageTool", "Espanso"],
        ["Auto-correct on space",   "✅", "✅ native only", "✅", "✅", "❌"],
        ["Inline ghost text",       "✅", "✅ native only", "❌", "❌", "❌"],
        ["Works in Illustrator",    "✅ badge", "❌", "❌", "❌", "Partial"],
        ["Works in Finder rename",  "✅", "✅", "❌", "❌", "✅"],
        ["Works in VS Code",        "✅", "❌", "❌", "✅ ext", "✅"],
        ["Works in Chrome",         "✅ badge", "❌", "✅ ext", "✅ ext", "✅"],
        ["Works in Terminal",       "❌", "❌", "❌", "❌", "Partial"],
        ["Custom personal words",   "✅", "❌", "❌", "❌", "✅"],
        ["Backspace to undo",       "✅", "✅", "❌", "❌", "❌"],
        ["Grammar checking",        "❌", "❌", "✅", "✅", "❌"],
        ["Learns from typing",      "❌", "✅", "✅", "✅", "❌"],
        ["No internet required",    "✅", "✅", "❌", "✅ paid", "✅"],
        ["Free",                    "✅", "✅", "Freemium", "Freemium", "✅"],
        ["Open source",             "✅", "❌", "❌", "✅", "✅"],
        ["Single Swift file",       "✅", "—", "—", "—", "—"],
    ]
    story += [mk_table(comp_data,
        [4.2*cm, 2.3*cm, 2.3*cm, 2*cm, 2.3*cm, 2*cm]), sp(0.4)]

    story += [body(
        "<b>Key differentiator:</b> Ghost Finisher is the only tool in this comparison "
        "that provides auto-correct and ghost text inside Adobe Illustrator and other "
        "custom-renderer apps. This is its primary unique value."
    ), sp(0.5)]

    # ── 6. GitHub & Versioning ────────────────────────────────────────────────
    story += [h1("6. GitHub Repository"), hr()]

    story += [body("<b>Repository:</b> github.com/saikiran9185/GhostFinisher")]
    story += [body("<b>Language:</b> Swift 6  |  <b>Target:</b> macOS 13+ (arm64)")]
    story += [body("<b>Build:</b> Single swiftc command — no Xcode project required")]
    story += [sp(0.2)]

    commit_data = [
        ["Commit", "Description"],
        ["795c969", "Initial release — CGEventTap + word buffer + fuzzy matcher + menu bar"],
        ["5333645", "Inline ghost text — prefix match at cursor, fuzzy match as badge"],
        ["b45247c", "Fix injection re-interception bug — GHOST_MARKER stamps injected events"],
        ["6a74c7b", "300-word dictionary, Levenshtein spell correction, 10x faster prefix injection"],
        ["2d55ed4", "Auto-correct on space, backspace to undo, 4-level AX badge positioning"],
    ]
    story += [mk_table(commit_data, [2.2*cm, W - 2.2*cm], header_bg=GHOST_MID), sp(0.3)]

    story += [h2("File Structure")]
    story += [code("GhostFinisher/")]
    story += [code("  Sources/GhostFinisher.swift   ← entire app in one file (~380 lines)")]
    story += [code("  Info.plist                    ← bundle identity, LSUIElement=true")]
    story += [code("  build.sh                      ← one-command build script")]
    story += [code("  README.md                     ← install + usage instructions")]
    story += [sp(0.3)]

    story += [h2("Build & Install")]
    story += [code("git clone https://github.com/saikiran9185/GhostFinisher")]
    story += [code("cd GhostFinisher && bash build.sh")]
    story += [code("cp -r GhostFinisher.app /Applications/")]
    story += [code("open /Applications/GhostFinisher.app")]
    story += [muted("Then: System Settings → Privacy & Security → Input Monitoring → enable Ghost Finisher"), sp(0.5)]

    # ── 7. Known Issues & Roadmap ─────────────────────────────────────────────
    story += [PageBreak(), h1("7. Known Issues & Roadmap"), hr()]

    story += [h2("Known Issues")]
    issues = [
        ("Popup position in Chrome", "AX cursor not exposed — badge falls back to focused window frame"),
        ("Terminal not supported", "PTY architecture makes keystroke-level interception insufficient"),
        ("Personal dictionary resets on relaunch", "Dictionary is in-memory only — no persistence to disk yet"),
        ("Secure Input freezes tap", "Password manager popups trigger macOS Secure Input, pausing suggestions"),
        ("Font size mismatch in some apps", "Ghost text uses AX font size when available, falls back to 14pt"),
        ("Auto-correct distance-2 not automatic", "Only distance-1 typos auto-correct on space; distance-2 shows badge only"),
    ]
    issue_data = [["Issue", "Detail"]] + [[i, d] for i, d in issues]
    story += [mk_table(issue_data, [4.5*cm, W - 4.5*cm], header_bg=ACCENT_RED), sp(0.4)]

    story += [h2("Roadmap")]
    roadmap = [
        ("Persist personal dictionary", "Save to ~/.ghostfinisher/words.txt, reload on launch"),
        ("Larger word list", "Load from bundled 10k-word JSON file at startup"),
        ("Per-app toggle", "Disable in Terminal and specific apps automatically"),
        ("Learning mode", "Track accepted corrections and promote them to personal dictionary"),
        ("Distance-2 auto-correct", "Auto-apply with short confirmation window instead of badge"),
        ("IMK version", "Parallel Input Method Kit build for true inline text in all native apps"),
        ("UI preferences window", "GUI for managing personal dictionary and settings"),
    ]
    road_data = [["Feature", "Implementation Plan"]] + [[f, p] for f, p in roadmap]
    story += [mk_table(road_data, [4.5*cm, W - 4.5*cm], header_bg=ACCENT_GREEN), sp(0.5)]

    # ── 8. Privacy & Security ─────────────────────────────────────────────────
    story += [h1("8. Privacy & Security"), hr()]
    story += [body(
        "Ghost Finisher requires two macOS permissions to function:"
    )]
    story += [bullet("<b>Input Monitoring</b> — reads keystrokes at OS level (same permission used by Karabiner-Elements, Rocket, PopClip)")]
    story += [bullet("<b>Accessibility</b> — reads text cursor position and element frames for badge placement")]
    story += [sp(0.2)]
    story += [body(
        "<b>No data ever leaves the device.</b> There are no network calls, no telemetry, "
        "no analytics. All word matching and correction runs locally using in-process Swift code. "
        "The entire source is <b>open and auditable</b> in a single 380-line file."
    ), sp(0.2)]
    story += [body(
        "Injected keystrokes are tagged with a unique marker (<code>0x47484F5354</code>) "
        "so the tap can distinguish them from real user input — preventing buffer corruption "
        "and ensuring the tool never accidentally re-processes its own output."
    ), sp(0.5)]

    # ── Footer note ───────────────────────────────────────────────────────────
    story += [hr(color=GHOST_PURPLE, thickness=0.5)]
    story += [muted("Ghost Finisher  •  Built by Saikiran  •  April 2026  •  github.com/saikiran9185/GhostFinisher")]
    story += [muted("Swift 6  •  macOS 13+  •  Apple Silicon  •  Open Source  •  MIT Licence")]

    doc.build(story)
    print(f"PDF saved: {OUTPUT}")

if __name__ == "__main__":
    build()
