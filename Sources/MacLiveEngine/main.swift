import AppKit

// Ensure we run as a proper macOS app (agent — no dock icon)
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // Menu bar only — no dock icon
app.run()
