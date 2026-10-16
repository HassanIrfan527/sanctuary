import QtQuick
import Quickshell
import Quickshell.Wayland
import "kit"

// The volume pop-up: appears under the bar's centre when the output volume or
// mute changes, holds for 1.4s, goes. It takes no input — the pointer passes
// straight through it — because it is a readout, never a control (§1).
//
//   VOL ▕██████████░░░░░░░░░░▏ 52%
PanelWindow {
    id: osd

    property bool shown: false

    visible: shown
    color: "transparent"
    anchors.top: true
    margins.top: 8
    exclusionMode: ExclusionMode.Normal   // below the bar
    exclusiveZone: 0
    implicitWidth: plate.width + 16
    implicitHeight: plate.height + 16

    WlrLayershell.namespace: "sanctuary-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region {}

    readonly property real level: Math.max(0, Math.min(1, Media.volume))
    readonly property int pctNum: Math.round(Media.volume * 100)

    Connections {
        target: Media
        function onTouched() {
            osd.shown = true;
            hold.restart();
        }
    }
    Timer {
        id: hold
        interval: 1400
        onTriggered: osd.shown = false
    }

    Fade {
        x: 8
        y: 4
        width: parent.width - 16
        shown: osd.shown

        Plate {
            id: plate
            tone: Media.muted ? "warn" : ""

            Label {
                anchors.verticalCenter: parent.verticalCenter
                width: implicitWidth
                role: "tag"
                tone: Media.muted ? "warn" : ""
                text: Media.muted ? "MUTE" : "VOL"
            }
            Meter {
                anchors.verticalCenter: parent.verticalCenter
                value: osd.level
                off: Media.muted
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                width: implicitWidth
                role: "readout"
                tone: Media.muted ? "dim" : ""
                text: Theme.pad(osd.pctNum + "%", 4, " ")
            }
        }
    }
}
