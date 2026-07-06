import AppKit
import TextLensCore

struct PermissionCenter {
    var accessibility: PermissionState {
        AXIsProcessTrusted() ? .granted : .missing
    }

    var screenRecording: PermissionState {
        CGPreflightScreenCaptureAccess() ? .granted : .missing
    }

    func openAccessibilitySettings() {
        openSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    func openScreenRecordingSettings() {
        openSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
    }

    private func openSettings(_ value: String) {
        guard let url = URL(string: value) else { return }
        NSWorkspace.shared.open(url)
    }
}
