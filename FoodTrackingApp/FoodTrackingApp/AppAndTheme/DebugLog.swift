//
//  DebugLog.swift
//  FoodTrackingApp
//
//  Lightweight logging that compiles to a no-op in release builds, so food
//  logs, file paths, and barcode-scan data never reach the device console in
//  the shipped app. Use `debugLog(...)` exactly like `print(...)`.
//

import Foundation

#if DEBUG
func debugLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    let line = items.map { "\($0)" }.joined(separator: separator)
    print(line, terminator: terminator)
}
#else
@inline(__always)
func debugLog(_ items: Any..., separator: String = " ", terminator: String = "\n") { }
#endif
