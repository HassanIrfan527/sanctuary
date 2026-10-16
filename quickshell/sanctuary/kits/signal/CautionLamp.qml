import QtQuick
import ".."

// KIT · CautionLamp — Master Caution, part 3: the one light that means
// "something needs you", naming what. clicked() = acknowledge.
// Signal: a red-tinted cell with a red edge, ▲ and the reasons.
Item {
    id: root
    property string text: ""
    signal clicked()

    width: lamp.width
    height: parent ? parent.height : 35
    Rectangle {
        id: lamp
        anchors.verticalCenter: parent.verticalCenter
        width: lampText.implicitWidth + 16
        height: Theme.sigStripH - 12
        color: Theme.flare ? (lampArea.containsMouse ? "#ecc6bd" : "#f2d6cc")      // a red-tinted cell on paper
                           : (lampArea.containsMouse ? "#3a1f2a" : "#2a1720")
        border.width: 1
        border.color: Theme.sigAlarm
        Text {
            id: lampText
            anchors.centerIn: parent
            text: "▲ " + root.text
            font.family: Theme.mono
            font.pixelSize: 10
            font.weight: Font.Bold
            font.letterSpacing: 1.2
            color: Theme.sigAlarm
        }
        MouseArea {
            id: lampArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }
}
