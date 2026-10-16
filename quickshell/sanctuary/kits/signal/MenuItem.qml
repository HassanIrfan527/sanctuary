import QtQuick
import Quickshell.Widgets
import ".."

// KIT · MenuItem — one entry of an app's menu (tray menus).
//   check     "none" | "box" | "radio"; checked = lit
//   icon      an image source, or ""
//   usable    false = greyed out, can't be picked
//   submenu   draws the › that says "this opens more"
//   textX     where the label starts (Measure.textX, so all rows line up)
// Signal: a 28px log line; selected gets the wash + marker, the label lights.
Item {
    id: item

    property string text: ""
    property string check: "none"
    property bool checked: false
    property string icon: ""
    property bool usable: true
    property bool submenu: false
    property bool selected: false
    property bool hasChecks: false
    property int textX: 14

    signal hovered()
    signal clicked()

    width: parent ? parent.width : 0
    height: 28

    Rectangle {
        anchors.fill: parent
        color: item.selected ? Theme.sigCell : "transparent"

        Rectangle {
            width: 2
            height: parent.height
            color: Theme.sigHot
            visible: item.selected
        }
        // Check / radio state: a small square lamp, lit when on.
        Rectangle {
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            visible: item.check !== "none"
            width: 7
            height: 7
            radius: item.check === "radio" ? 4 : 0
            color: item.checked ? Theme.sigHot : "transparent"
            border.width: 1
            border.color: item.checked ? Theme.sigHot : Theme.surface2
        }
        IconImage {
            x: 14 + (item.hasChecks ? 16 : 0)
            anchors.verticalCenter: parent.verticalCenter
            visible: source != ""
            implicitSize: 14
            source: item.icon
            asynchronous: true
            opacity: item.usable ? 1 : 0.4
        }
        Text {
            x: item.textX
            width: parent.width - item.textX - 30
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: item.text
            font.family: Theme.mono
            font.pixelSize: 12
            font.weight: item.selected ? Font.Bold : Font.Normal
            color: !item.usable ? Theme.surface2 : item.selected ? Theme.sigHot : Theme.sigValue
        }
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            visible: item.submenu
            text: "›"
            font.family: Theme.mono
            font.pixelSize: 13
            color: item.selected ? Theme.sigHot : Theme.sigLabel
        }
    }
    MouseArea {
        anchors.fill: parent
        enabled: item.usable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: item.hovered()
        onClicked: item.clicked()
    }
}
