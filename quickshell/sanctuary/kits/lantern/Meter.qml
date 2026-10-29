import QtQuick
import ".."

// KIT · Meter — a level as a row of segments (volume, gain, a device).
// Lantern: pips in a sunk well, cyan (every Meter is sound); `off` = all dark
// (muted); `quiet` = dim instead (a level that isn't the live one).
//   bias   a cell lights when value > index/segments + bias
//   steps  compare in whole steps (100 = percent, as a readout shows it); 0 = exact
Rectangle {
    id: meter
    property real value: 0          // 0..1
    property int segments: 20
    property bool off: false
    property bool quiet: false
    property real bias: 0
    property int steps: 0
    property int cellWidth: 6
    property int cellHeight: 12

    readonly property int pw: Math.max(2, Math.round(cellWidth / 2) * 2)
    readonly property int ph: Math.max(6, Math.round(cellHeight / 2) * 2 + 2)

    width: row.width + 4
    height: ph + 4
    color: Theme.lanSunk
    Row {
        id: row
        x: 2
        y: 2
        spacing: 2
        Repeater {
            model: meter.segments
            delegate: Rectangle {
                required property int index
                readonly property real at: index / meter.segments + meter.bias
                readonly property bool lit: !meter.off && (meter.steps > 0
                    ? Math.round(meter.value * meter.steps) > Math.round(at * meter.steps)
                    : meter.value > at)
                width: meter.pw
                height: meter.ph
                color: lit ? (meter.quiet ? Theme.lanDim : Theme.lanSound)
                           : Qt.rgba(Theme.lanPaper.r, Theme.lanPaper.g, Theme.lanPaper.b, 0.35)
                Rectangle {
                    visible: parent.lit && !meter.quiet
                    width: parent.width
                    height: 2
                    color: Qt.lighter(Theme.lanSound, 1.3)
                }
            }
        }
    }
}
