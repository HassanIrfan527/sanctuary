import QtQuick
import ".."

// KIT · BarClock — the time, dead centre (§1: the one thing read without
// looking). Signal: hh:mm big, :ss small in the trace colour (red under
// Master Caution — part 2), then AM/PM and the date in small caps.
Row {
    id: clockRoot
    property var date: new Date()
    property bool caution: false

    spacing: 8
    Row {   // hh:mm big, :ss small, sharing a baseline
        anchors.verticalCenter: parent.verticalCenter
        Text {
            id: hm
            // 12-hour. "hh" is only 12-hour when AP is in the SAME format
            // string, so format once, slice.
            text: Qt.formatDateTime(clockRoot.date, "hh:mm AP").slice(0, 5)
            font.family: Theme.mono
            font.pixelSize: 14
            font.weight: Font.Bold
            color: Theme.sigValue
        }
        Text {
            anchors.baseline: hm.baseline
            text: Qt.formatDateTime(clockRoot.date, ":ss")
            font.family: Theme.mono
            font.pixelSize: 11
            color: clockRoot.caution ? Theme.sigAlarm : Theme.sigHot
        }
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(clockRoot.date, "AP · ddd dd MMM").toUpperCase()
        font.family: Theme.mono
        font.pixelSize: 9
        font.letterSpacing: 1.2
        color: Theme.sigLabel
    }
}
