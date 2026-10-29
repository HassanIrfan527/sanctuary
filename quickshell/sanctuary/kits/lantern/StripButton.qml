import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · StripButton — one button on a button strip (the capture strip).
//   lit   this toggle is on, or this is the button that matters right now
//   tone  its lit colour: "" (pink: yours) | "warn" | "alarm"
//   rule  a groove after it
Item {
    id: btn

    property string text: ""
    property bool lit: false
    property string tone: ""
    property bool rule: true

    signal clicked()

    readonly property color hot: tone === "alarm" ? Theme.lanAlarm : tone === "warn" ? Theme.lanWarn : Theme.lanPink

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 36

    Rectangle {
        anchors.fill: parent
        anchors.rightMargin: btn.rule ? 2 : 0
        color: area.containsMouse ? Theme.lanRaised : "transparent"
    }
    Rectangle {
        visible: btn.rule
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: 20
        color: Theme.lanSunk
    }
    LText {
        id: label
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 1
        text: G.plain(btn.text.toLowerCase())
        color: btn.lit ? btn.hot : Theme.lanText
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
