import QtQuick
import Quickshell
import Quickshell.Wayland

// The volume pop-up: appears under the bar's centre when the output volume or
// mute changes, holds for 1.4s, goes. It takes no input — the pointer passes
// straight through it — because it is a readout, never a control (§1).
//
//   Signal       a hairline gauge: VOL ▕██████████░░░░░░░░░░▏ 52%
//   Ink / Paper  a manga panel: VOL, ten chunky blocks, the number lettered big
PanelWindow {
    id: osd

    property bool shown: false

    visible: shown
    color: "transparent"
    anchors.top: true
    margins.top: 8
    exclusionMode: ExclusionMode.Normal   // below the bar
    exclusiveZone: 0
    implicitWidth: (Theme.signal ? sig.width : ink.width) + 16
    implicitHeight: (Theme.signal ? sig.height : ink.height) + 16

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
            if (Theme.ink)
                slam.restart();
        }
    }
    Timer {
        id: hold
        interval: 1400
        onTriggered: osd.shown = false
    }

    Item {
        id: body
        x: 8
        y: 4
        width: parent.width - 16
        height: parent.height - 16
        opacity: osd.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }

        // ── Signal ────────────────────────────────────────────────────
        Rectangle {
            id: sig
            visible: Theme.signal
            width: sigRow.implicitWidth + 28
            height: 34
            color: Theme.sigFill
            border.width: 1
            border.color: Theme.sigRule

            SignalTicks {
                anchors.fill: parent
                anchors.margins: -3
                color: Media.muted ? Theme.sigWarn : Theme.sigHot
            }

            Row {
                id: sigRow
                anchors.centerIn: parent
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Media.muted ? "MUTE" : "VOL"
                    font.family: Theme.mono
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: 1.4
                    color: Media.muted ? Theme.sigWarn : Theme.sigLabel
                }
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Repeater {
                        model: 20
                        delegate: Rectangle {
                            required property int index
                            width: 6
                            height: 12
                            color: !Media.muted && osd.level > index / 20 ? Theme.sigHot : Theme.surface0
                            Behavior on color { ColorAnimation { duration: 80 } }
                        }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.pad(osd.pctNum + "%", 4, " ")
                    font.family: Theme.mono
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: Media.muted ? Theme.surface2 : Theme.sigValue
                }
            }
        }

        // ── Ink / Paper ───────────────────────────────────────────────
        InkPanel {
            id: ink
            visible: Theme.ink
            accent: Media.muted ? Theme.surface1 : Theme.lavender
            face: Media.muted ? Theme.paperDim : Theme.paper
            padX: 14
            implicitHeight: 40
            transformOrigin: Item.Top

            Row {
                spacing: 10
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Media.muted ? "MUTE" : "VOL"
                    font.family: Theme.sans
                    font.weight: Font.Black
                    font.pixelSize: 11
                    font.letterSpacing: 1
                    color: Theme.inkLine
                }
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    Repeater {
                        model: 10
                        delegate: Rectangle {
                            required property int index
                            width: 12
                            height: 16
                            border.width: 2
                            border.color: Theme.inkLine
                            color: !Media.muted && osd.level > index / 10 ? Theme.inkLine : Theme.paper
                        }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    horizontalAlignment: Text.AlignRight
                    text: String(osd.pctNum)
                    font.family: Theme.display
                    font.weight: Theme.displayWeight
                    font.pixelSize: Theme.hasBangers ? 24 : 19
                    color: Media.muted ? Theme.inkMuted : Theme.inkLine
                }
            }
        }

        NumberAnimation {
            id: slam
            target: ink
            property: "scale"
            from: 1.12
            to: 1
            duration: Theme.quick
            easing.type: Easing.OutCubic
        }
    }
}
