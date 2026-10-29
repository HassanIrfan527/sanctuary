import QtQuick
import Quickshell.Widgets
import "Glyphs.js" as G
import ".."

// KIT · MenuItem — one entry of an app's menu (tray menus).
//   check     "none" | "box" | "radio"; checked = lit
//   icon      an image source, or ""
//   usable    false = greyed out, can't be picked
//   submenu   draws the › that says "this opens more"
//   textX     where the label starts (Measure.textX, so all rows line up)
// Lantern: a shop row; selected is raised, its words bright, a pink pointer.
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
    property int textX: 12

    signal hovered()
    signal clicked()

    width: parent ? parent.width : 0
    height: 32

    Rectangle {
        anchors.fill: parent
        color: item.selected ? Theme.lanRaised : "transparent"

        // check / radio: a small sunk box, pink-filled when on
        Rectangle {
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: item.check !== "none"
            width: 12
            height: 12
            color: Theme.lanSunk
            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                visible: item.checked
                color: Theme.lanPink
            }
        }
        IconImage {
            x: 12 + (item.hasChecks ? 24 : 0)
            anchors.verticalCenter: parent.verticalCenter
            visible: source != ""
            implicitSize: 16
            source: item.icon
            asynchronous: true
            opacity: item.usable ? 1 : 0.4
        }
        LText {
            x: item.textX
            width: parent.width - item.textX - 30
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 1
            elide: Text.ElideRight
            text: G.plain(item.text)
            color: !item.usable ? Theme.lanDim : item.selected ? Theme.lanBright : Theme.lanText
        }
        Icon {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            visible: item.submenu
            name: "chevron-right"
            color: item.selected ? Theme.lanPink : Theme.lanDim
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
