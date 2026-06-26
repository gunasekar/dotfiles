import Foundation

// Applies a macOS symbolic hotkey live via private SkyLight APIs.
// `defaults write` updates the plist, but on recent macOS versions activateSettings
// no longer reloads symbolic hotkeys; this bridges that gap.
//
// Usage: swift apply-symbolic-hotkey.swift <id> <ascii> <keyCode> <modifiers>
// Example (Quick Note = Control+Option+Q): swift apply-symbolic-hotkey.swift 190 113 12 786432

@_silgen_name("CGSSetSymbolicHotKeyEnabled")
func CGSSetSymbolicHotKeyEnabled(_ hotKey: Int32, _ enabled: Bool) -> Int32

@_silgen_name("CGSSetSymbolicHotKeyValue")
func CGSSetSymbolicHotKeyValue(
    _ hotKey: Int32,
    _ keyEquivalent: UInt32,
    _ keyCode: UInt32,
    _ modifiers: UInt32
) -> Int32

guard CommandLine.arguments.count == 5,
      let hotKeyId = Int32(CommandLine.arguments[1]),
      let keyEquivalent = UInt32(CommandLine.arguments[2]),
      let keyCode = UInt32(CommandLine.arguments[3]),
      let modifiers = UInt32(CommandLine.arguments[4]) else {
    fputs("usage: swift apply-symbolic-hotkey.swift <id> <ascii> <keyCode> <modifiers>\n", stderr)
    exit(1)
}

let enable = CGSSetSymbolicHotKeyEnabled(hotKeyId, true)
let set = CGSSetSymbolicHotKeyValue(hotKeyId, keyEquivalent, keyCode, modifiers)

if enable != 0 || set != 0 {
    fputs("failed to apply hotkey \(hotKeyId): enable=\(enable) set=\(set)\n", stderr)
    exit(1)
}
