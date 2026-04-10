# Ghost Finisher

A silent macOS utility that completes your words as you type — everywhere. Illustrator, Spotlight, Finder, Notes, anywhere there is an input box.

No internet. No data sent anywhere. Runs fully on your Mac.

## How it works

- Type `ilu` → Ghost Finisher shows **✨ Illustrator** floating near your cursor
- Press **Tab** to accept — it nukes your typo and types the correct word perfectly
- Press **Escape** to dismiss
- Works in every app including Adobe Illustrator, Spotlight, and Finder rename

## Install

### Requirements
- macOS 13 or later
- Apple Silicon or Intel Mac

### Build and install

```bash
git clone https://github.com/saikiran9185/GhostFinisher
cd GhostFinisher
bash build.sh
cp -r GhostFinisher.app /Applications/
open /Applications/GhostFinisher.app
```

When prompted, open System Settings → Privacy & Security → Input Monitoring → enable Ghost Finisher.  
Relaunch the app once after granting permission.

Ghost Finisher will now auto-launch every time your Mac starts.

## Usage

| Action | What happens |
|---|---|
| Type 2+ letters | Suggestion appears near cursor |
| **Tab** | Accepts suggestion, corrects the word |
| **Escape** | Dismisses suggestion |
| **⌘⇧G** | Toggle Ghost Finisher on/off globally |

The 👻 icon in your menu bar shows it is active. 💤 means paused.

## Add your own words

Click the 👻 menu bar icon → "Add current clipboard word" — or edit the dictionary directly in `Sources/GhostFinisher.swift`:

```swift
var ghostDictionary: [String] = [
    "YourName", "YourProject", "YourTool",
    ...
]
```

Then run `bash build.sh` again.

## Why it works in Illustrator

Most spell checkers try to read the text field. Adobe apps block that.  
Ghost Finisher intercepts keystrokes at the OS level (before Illustrator sees them) using `CGEventTap`. It never needs to read the text field — it builds the word from the keystroke stream itself.

## Privacy

- All processing is local — no network calls, ever
- Requires Input Monitoring permission (same as Karabiner, Rocket, PopClip)
- Source is fully open — read every line in `Sources/GhostFinisher.swift`

## Limitations

- Password fields — blocked by macOS by design (correct behaviour)
- When a password manager popup is open — temporarily pauses
- Popup position follows mouse cursor, not text cursor (reliable fallback)
