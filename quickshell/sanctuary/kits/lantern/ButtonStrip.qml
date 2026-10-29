import QtQuick
import ".."

// KIT · ButtonStrip — a row of StripButtons (and readouts) on one surface.
// Lantern: a wooden rail like the bar's; its frame takes the tone while
// something is live (recording = alarm, paused = warn). It swallows its clicks.
Item {
    id: strip
    property string tone: ""
    default property alias content: row.data

    width: row.implicitWidth + 12
    height: 36 + 12

    Wood {
        anchors.fill: parent
        thick: 4
        shadow: true
        outline: strip.tone === "alarm" ? Theme.lanAlarm : strip.tone === "warn" ? Theme.lanWarn : Theme.lanOutline
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }
    Row {
        id: row
        x: 6
        y: 6
        spacing: 0
    }
}
