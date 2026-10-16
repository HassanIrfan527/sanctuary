import QtQuick
import ".."

// KIT · StripButton — one button on a button strip (the capture strip).
//   lit   this toggle is on, or this is the button that matters right now
//   tone  its lit colour: "" (hot) | "warn" | "alarm"
//   rule  Signal: a hairline after it
// Signal: a cell — mono caps, lit text in the tone's colour, hover wash.
Item {
    id: btn

    property string text: ""
    property bool lit: false
    property string tone: ""
    property bool rule: true

    signal clicked()

    readonly property color hot: tone === "alarm" ? Theme.sigAlarm : tone === "warn" ? Theme.sigWarn : Theme.sigHot

    implicitWidth: label.implicitWidth + 22
    implicitHeight: 32

    Rectangle {
        anchors.fill: parent
        color: area.containsMouse ? Theme.sigCell : "transparent"
    }
    Rectangle {
        visible: btn.rule
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: parent.height - 12
        color: Theme.sigRule
    }
    Text {
        id: label
        anchors.centerIn: parent
        text: btn.text
        font.family: Theme.mono
        font.pixelSize: 11
        font.weight: Font.Bold
        font.letterSpacing: 1
        color: (btn.lit ? btn.hot : Theme.sigLabel)
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
