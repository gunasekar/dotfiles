// Generate Terminal.app "Black" profile (.terminal plist).
// Usage (font must be installed):
//   swift generate-black-terminal.swift .config/terminal/Black.terminal
// Then: ./install.sh

import AppKit
import Foundation

func archive(_ object: Any) -> Data {
    try! NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: false)
}

func hexColor(_ hex: String, alpha: CGFloat = 1.0) -> NSColor {
    var h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    if h.count == 3 {
        h = h.map { "\($0)\($0)" }.joined()
    }
    let n = UInt32(h, radix: 16) ?? 0
    let r = CGFloat((n >> 16) & 0xff) / 255
    let g = CGFloat((n >> 8) & 0xff) / 255
    let b = CGFloat(n & 0xff) / 255
    return NSColor(calibratedRed: r, green: g, blue: b, alpha: alpha)
}

guard let font = NSFont(name: "Hack Nerd Font Mono", size: 12)
        ?? NSFont(name: "HackNFM-Regular", size: 12) else {
    fputs("error: Hack Nerd Font Mono not installed\n", stderr)
    exit(1)
}

// Ayu-on-black palette from kitty/.config/kitty/kitty.conf
let colors: [String: String] = [
    "TextColor": "#bfbdb6",
    "TextBoldColor": "#ffffff",
    "BackgroundColor": "#000000",
    "CursorColor": "#e6b450",
    "SelectionColor": "#409fff",
    "ANSIBlackColor": "#11151c",
    "ANSIRedColor": "#ea6c73",
    "ANSIGreenColor": "#7fd962",
    "ANSIYellowColor": "#f9af4f",
    "ANSIBlueColor": "#53bdfa",
    "ANSIMagentaColor": "#cda1fa",
    "ANSICyanColor": "#90e1c6",
    "ANSIWhiteColor": "#c7c7c7",
    "ANSIBrightBlackColor": "#686868",
    "ANSIBrightRedColor": "#f07178",
    "ANSIBrightGreenColor": "#aad94c",
    "ANSIBrightYellowColor": "#ffb454",
    "ANSIBrightBlueColor": "#59c2ff",
    "ANSIBrightMagentaColor": "#d2a6ff",
    "ANSIBrightCyanColor": "#95e6cb",
    "ANSIBrightWhiteColor": "#ffffff",
]

var profile: [String: Any] = [
    "name": "Black",
    "type": "Window Settings",
    "ProfileCurrentVersion": 2.09,
    "Font": archive(font),
    "FontAntialias": true,
    "FontWidthSpacing": 1.0,
    "FontHeightSpacing": 1.0,
    "columnCount": 120,
    "rowCount": 30,
    // 0 = Close the window (Apple Terminal Shell settings)
    "shellExitAction": 0,
    "useOptionAsMetaKey": true,
    "CursorBlink": false,
    "Bell": false,
    "VisualBell": false,
    // Titles: shell sets user@host:cwd on OSC ]1 and ]2. Terminal.app joins
    // its own checkboxes with an em dash — including *separate* tab-title
    // checkboxes (that produced "~ — guna@airbochs:~ — -zsh"). All off.
    "ShowRepresentedURLInTitle": false,
    "ShowRepresentedURLPathInTitle": false,
    "ShowActiveProcessInTitle": false,
    "ShowActiveProcessArgumentsInTitle": false,
    "ShowShellCommandInTitle": false,
    "ShowCommandKeyInTitle": false,
    "ShowWindowSettingsNameInTitle": false,
    "ShowDimensionsInTitle": false,
    "ShowDeviceNameInTitle": false,
    "ShowTTYNameInTitle": false,
    "ShowRepresentedURLInTabTitle": false,
    "ShowRepresentedURLPathInTabTitle": false,
    "ShowActiveProcessInTabTitle": false,
    "ShowActiveProcessArgumentsInTabTitle": false,
    "ShowTTYNameInTabTitle": false,
    "ShowComponentsWhenTabHasCustomTitle": false,
    "ShowActivityIndicatorInTab": true,
    "WindowTitle": "",
    "BackgroundBlur": 0.0,
    "Transparency": 0.0,
]

for (key, hex) in colors {
    profile[key] = archive(hexColor(hex))
}

let out = URL(fileURLWithPath: CommandLine.arguments[1])
let data = try PropertyListSerialization.data(
    fromPropertyList: profile,
    format: .xml,
    options: 0
)
try data.write(to: out, options: .atomic)
print("wrote \(out.path)")
