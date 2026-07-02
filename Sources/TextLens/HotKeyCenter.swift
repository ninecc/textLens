import Carbon.HIToolbox
import Foundation

final class HotKeyCenter {
    private var hotKeyRef: EventHotKeyRef?
    private static var action: (() -> Void)?

    func registerScreenshotHotKey(action: @escaping () -> Void) {
        Self.action = action

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            HotKeyCenter.action?()
            return noErr
        }, 1, &eventType, nil, nil)

        let hotKeyID = EventHotKeyID(signature: OSType(UInt32(UInt8(ascii: "T"))), id: 1)
        RegisterEventHotKey(
            UInt32(kVK_ANSI_T),
            UInt32(cmdKey | optionKey | controlKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
}
