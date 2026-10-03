import QtQuick
import Quickshell
import Quickshell.Wayland

// The toast column, top-right, under the bar. Shared by both styles; only the
// delegate differs (InkToast / SignalToast).
//
// ScriptModel diffs the popups array by identity, so a new toast arriving
// creates ONE delegate — the ones already on screen keep their state and don't
// replay their entrance.
PanelWindow {
    id: win

    property Component delegate
    property int gap: 10
    property int toastWidth: 380

    visible: Notifs.popups.length > 0
    color: "transparent"
    anchors {
        top: true
        right: true
    }
    margins {
        top: 6
        right: 12
    }
    // Sit below the bar's exclusive zone, reserve none of our own.
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    implicitWidth: toastWidth + 16
    implicitHeight: Math.max(1, column.implicitHeight + 16)

    WlrLayershell.namespace: "sanctuary-toasts"
    WlrLayershell.layer: WlrLayer.Overlay

    // Only the toasts themselves take the pointer; the air between them and
    // around them clicks straight through to the window underneath.
    mask: Region { item: column }

    Column {
        id: column
        x: 8
        y: 4
        spacing: win.gap

        Repeater {
            model: ScriptModel { values: Notifs.popups }
            delegate: win.delegate
        }
    }
}
