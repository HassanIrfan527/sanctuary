import QtQuick

// Registration marks: a short L at each corner, in the trace colour. The one
// decoration Signal allows itself — it frames a surface the way a HUD reticle
// frames a reading, and it says "instrument" before you read anything.
Item {
    id: ticks
    property color color: Theme.sigHot
    property int len: 7
    property int w: 1

    Repeater {
        model: 4
        delegate: Item {
            required property int index
            readonly property bool isRight: index % 2 === 1
            readonly property bool isBottom: index >= 2
            x: isRight ? ticks.width - ticks.len : 0
            y: isBottom ? ticks.height - ticks.len : 0
            width: ticks.len
            height: ticks.len

            Rectangle {
                y: parent.isBottom ? parent.height - ticks.w : 0
                width: parent.width
                height: ticks.w
                color: ticks.color
            }
            Rectangle {
                x: parent.isRight ? parent.width - ticks.w : 0
                width: ticks.w
                height: parent.height
                color: ticks.color
            }
        }
    }
}
