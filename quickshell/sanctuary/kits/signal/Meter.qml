import QtQuick
import ".."

// KIT · Meter — a level as a row of segments (volume, gain, a device).
// Signal: cells lit in the hot colour; `off` = all dark (muted);
// `quiet` = lit in the label colour instead (a level that isn't the live one).
//   bias   a cell lights when value > index/segments + bias
//   steps  compare in whole steps (100 = percent, as a readout shows it); 0 = exact
Row {
    id: meter
    property real value: 0          // 0..1
    property int segments: 20
    property bool off: false
    property bool quiet: false
    property real bias: 0
    property int steps: 0
    property int cellWidth: 6
    property int cellHeight: 12

    spacing: 2
    Repeater {
        model: meter.segments
        delegate: Rectangle {
            required property int index
            width: meter.cellWidth
            height: meter.cellHeight
            readonly property real at: index / meter.segments + meter.bias
            readonly property bool lit: meter.steps > 0
                ? Math.round(meter.value * meter.steps) > Math.round(at * meter.steps)
                : meter.value > at
            color: !meter.off && lit ? (meter.quiet ? Theme.sigLabel : Theme.sigHot) : Theme.surface0
            Behavior on color { ColorAnimation { duration: 80 } }
        }
    }
}
