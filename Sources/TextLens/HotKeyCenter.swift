import Carbon.HIToolbox
import Foundation

final class HotKeyCenter {
    private var hotKeyRefs: [EventHotKeyRef?] = []
    private static var actions: [UInt32: () -> Void] = [:]
    private static var installedHandler = false

    func registerScreenshotHotKey(action: @escaping () -> Void) {
        register(keyCode: UInt32(kVK_ANSI_T), id: 1, action: action)
    }

    func registerSelectionHotKey(action: @escaping () -> Void) {
        register(keyCode: UInt32(kVK_ANSI_S), id: 2, action: action)
    }

    private func register(keyCode: UInt32, id: UInt32, action: @escaping () -> Void) {
        Self.actions[id] = action
        installHandlerIfNeeded()

        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(UInt32(UInt8(ascii: "T"))), id: id)
        RegisterEventHotKey(
            keyCode,
            UInt32(cmdKey | optionKey | controlKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        hotKeyRefs.append(hotKeyRef)
    }

    private func installHandlerIfNeeded() {
        guard !Self.installedHandler else { return }
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            HotKeyCenter.actions[hotKeyID.id]?()
            return noErr
        }, 1, &eventType, nil, nil)
        Self.installedHandler = true
    }
}
