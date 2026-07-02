import AppKit

let app = NSApplication.shared
let delegate = AppShell()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
