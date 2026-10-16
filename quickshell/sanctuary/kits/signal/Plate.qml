import QtQuick
import ".."

// KIT · Plate — a one-line card: a readout that appears and goes (the volume
// pop-up). Signal: the panel look at 34px, content centred, marks in the
// tone's colour.
Rectangle {
    id: plate
    property string tone: ""
    default property alias content: row.data

    width: row.implicitWidth + 28
    height: 34
    color: Theme.sigFill
    border.width: 1
    border.color: Theme.sigRule

    Ticks {
        anchors.fill: parent
        anchors.margins: -3
        color: plate.tone === "warn" ? Theme.sigWarn : plate.tone === "alarm" ? Theme.sigAlarm : Theme.sigHot
    }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10
    }
}
