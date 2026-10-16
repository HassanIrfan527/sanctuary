import QtQuick
import ".."

// KIT · Button — something to press (transport, actions). `hint` = its key,
// printed small underneath. Signal: a hairline box that lights on hover.
Item {
    id: btn
    property string text: ""
    property string hint: ""
    signal clicked()

    width: 52
    height: 30
    Rectangle {
        anchors.fill: parent
        color: area.containsMouse ? Theme.sigCell : "transparent"
        border.width: 1
        border.color: area.containsMouse ? Theme.sigHot : Theme.sigRule
    }
    Text {
        anchors.centerIn: parent
        text: btn.text
        font.family: Theme.mono
        font.pixelSize: 13
        font.weight: Font.Bold
        color: Theme.sigValue
    }
    Text {
        anchors.top: parent.bottom
        anchors.topMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        visible: btn.hint !== ""
        text: btn.hint
        font.family: Theme.mono
        font.pixelSize: 8
        color: Theme.surface2
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
