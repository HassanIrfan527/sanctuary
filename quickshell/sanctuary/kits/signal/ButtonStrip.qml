import QtQuick
import ".."

// KIT · ButtonStrip — a row of StripButtons (and readouts) on one surface.
// Signal: a strip like the bar's; its edge takes the tone while something
// is live (recording = alarm, paused = warn). It swallows its own clicks.
Item {
    id: strip
    property string tone: ""
    default property alias content: row.data

    width: row.implicitWidth + 2
    height: 32 + 2

    Rectangle {
        anchors.fill: parent
        color: Theme.sigFill
        border.width: 1
        border.color: strip.tone === "alarm" ? Theme.sigAlarm : strip.tone === "warn" ? Theme.sigWarn
                    : strip.tone === "live" ? Theme.sigHot : Theme.sigRule
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }
    Row {
        id: row
        x: 1
        y: 1
        spacing: 0
    }
}
