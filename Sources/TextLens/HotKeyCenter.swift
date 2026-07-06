import Carbon.HIToolbox
import Foundation

final class HotKeyCenter {
    private var hotKeyRefs: [EventHotKeyRef?] = []
    private static var actions: [UInt32: () -> Void] = [:]
    private static var installedHandler = false

    func unregisterAll() {
        hotKeyRefs.compactMap { $0 }.forEach { UnregisterEventHotKey($0) }
        hotKeyRefs.removeAll()
        Self.actions.removeAll()
    }

    func registerScreenshotHotKey(key: String = "T", action: @escaping () -> Void) -> Bool {
        register(key: key, id: 1, action: action)
    }

    func registerSelectionHotKey(key: String = "S", action: @escaping () -> Void) -> Bool {
        register(key: key, id: 2, action: action)
    }

    private func register(key: String, id: UInt32, action: @escaping () -> Void) -> Bool {
        guard let keyCode = keyCode(for: key) else { return false }
        Self.actions[id] = action
        installHandlerIfNeeded()

        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(UInt32(UInt8(ascii: "T"))), id: id)
        let status = RegisterEventHotKey(
            keyCode,
            UInt32(cmdKey | optionKey | controlKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        hotKeyRefs.append(hotKeyRef)
        return status == noErr
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

    private func keyCode(for key: String) -> UInt32? {
        switch key.uppercased() {
        case "A": return UInt32(kVK_ANSI_A)
        case "B": return UInt32(kVK_ANSI_B)
        case "C": return UInt32(kVK_ANSI_C)
        case "D": return UInt32(kVK_ANSI_D)
        case "E": return UInt32(kVK_ANSI_E)
        case "F": return UInt32(kVK_ANSI_F)
        case "G": return UInt32(kVK_ANSI_G)
        case "H": return UInt32(kVK_ANSI_H)
        case "I": return UInt32(kVK_ANSI_I)
        case "J": return UInt32(kVK_ANSI_J)
        case "K": return UInt32(kVK_ANSI_K)
        case "L": return UInt32(kVK_ANSI_L)
        case "M": return UInt32(kVK_ANSI_M)
        case "N": return UInt32(kVK_ANSI_N)
        case "O": return UInt32(kVK_ANSI_O)
        case "P": return UInt32(kVK_ANSI_P)
        case "Q": return UInt32(kVK_ANSI_Q)
        case "R": return UInt32(kVK_ANSI_R)
        case "S": return UInt32(kVK_ANSI_S)
        case "T": return UInt32(kVK_ANSI_T)
        case "U": return UInt32(kVK_ANSI_U)
        case "V": return UInt32(kVK_ANSI_V)
        case "W": return UInt32(kVK_ANSI_W)
        case "X": return UInt32(kVK_ANSI_X)
        case "Y": return UInt32(kVK_ANSI_Y)
        case "Z": return UInt32(kVK_ANSI_Z)
        default: return nil
        }
    }
}
