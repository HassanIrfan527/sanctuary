import QtQuick
import ".."

// KIT (Lantern only) · Pips — a level as stepped pips in a sunk well: ok,
// orange from 65%, red from 85% (the machine's colours). `tint` overrides
// the threshold colour (sound is cyan); `off` = all dark.
Rectangle {
    id: pips
    property real level: 0
    property int count: 8
    property int pipWidth: 4
    property int pipHeight: 12
    property bool off: false
    property color tint: "transparent"
    property color tintHi: "transparent"

    readonly property bool custom: tint.a > 0
    readonly property color fillC: custom ? tint : level >= 0.85 ? Theme.lanAlarm : level >= 0.65 ? Theme.lanWarn : Theme.lanOk
    readonly property color hiC: custom ? tintHi : level >= 0.85 ? Theme.lanAlarmHi : level >= 0.65 ? Theme.lanWarnHi : Theme.lanOkHi
    readonly property int lit: off ? 0 : Math.round(Math.max(0, Math.min(1, level)) * count)

    width: row.width + 4
    height: pipHeight + 4
    color: Theme.lanSunk
    Row {
        id: row
        x: 2
        y: 2
        spacing: 2
        Repeater {
            model: pips.count
            delegate: Rectangle {
                required property int index
                readonly property bool on: index < pips.lit
                width: pips.pipWidth
                height: pips.pipHeight
                color: on ? pips.fillC : Qt.rgba(Theme.lanPaper.r, Theme.lanPaper.g, Theme.lanPaper.b, 0.35)
                Rectangle { visible: parent.on; width: parent.width; height: 2; color: pips.hiC }
            }
        }
    }
}
