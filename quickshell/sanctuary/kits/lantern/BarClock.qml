import QtQuick
import ".."

// KIT · BarClock — the time, dead centre. Lantern: the one raised plaque on
// the bar, standing the rail's full height: moon or sun, the day, the time in
// the display face in lamp amber, am/pm. Master Caution turns its frame red.
Item {
    id: clockRoot
    property var date: new Date()
    property bool caution: false

    readonly property int hour: date.getHours()
    readonly property bool day: hour >= 6 && hour < 18

    width: row.width + 36
    height: 32
    Wood {
        x: 0
        y: -6
        width: parent.width
        height: 44
        thick: 4
        fill: Theme.lanRaised
        outline: clockRoot.caution ? Theme.lanAlarm : Theme.lanOutline
    }
    Row {
        id: row
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 1
        spacing: 10
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: clockRoot.day ? "sun" : "moon"
            color: Theme.lanAmber
        }
        LText {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clockRoot.date, "ddd d").toUpperCase()
        }
        LText {
            anchors.verticalCenter: parent.verticalCenter
            big: true
            // 12-hour, no leading zero. "h" is 12-hour only beside AP.
            text: Qt.formatDateTime(clockRoot.date, "h:mm AP").split(" ")[0]
            color: clockRoot.caution ? Theme.lanAlarm : Theme.lanLamp
        }
        LText {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clockRoot.date, "AP").toLowerCase()
            color: Theme.lanDim
        }
    }
}
