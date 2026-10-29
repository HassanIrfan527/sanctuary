import QtQuick
import ".."

// KIT · Plate — a one-line card that appears and goes (the volume pop-up).
// Lantern: a small wooden sign, the frame in the tone's colour when warn /
// alarm.
Item {
    id: plate
    property string tone: ""
    default property alias content: row.data

    width: row.implicitWidth + 40
    height: 48
    Wood {
        anchors.fill: parent
        thick: 4
        shadow: true
        outline: plate.tone === "warn" ? Theme.lanWarn : plate.tone === "alarm" ? Theme.lanAlarm : Theme.lanOutline
    }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10
    }
}
