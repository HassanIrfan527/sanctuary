import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · ModeTabs — a row of modes, the live one marked (apps · *pinned · =calc…),
// with a readout at the right. picked(index) when one is clicked.
// Lantern: the live mode pink with a 2px pink underline; the rest dim.
Item {
    id: tabs
    property var labels: []
    property int current: 0
    property string detail: ""
    signal picked(int index)

    width: parent ? parent.width : 0
    height: 34
    Row {
        x: 4
        height: parent.height
        Repeater {
            model: tabs.labels
            delegate: Item {
                id: tab
                required property var modelData
                required property int index
                readonly property bool on: index === tabs.current
                width: tabText.implicitWidth + 20
                height: parent.height
                LText {
                    id: tabText
                    anchors.centerIn: parent
                    text: G.plain(String(tab.modelData).toLowerCase())
                    color: tab.on ? Theme.lanPink : Theme.lanDim
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: tabText.implicitWidth
                    height: 2
                    color: Theme.lanPink
                    visible: tab.on
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tabs.picked(tab.index)
                }
            }
        }
    }
    LText {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: G.plain(tabs.detail.toLowerCase())
        color: Theme.lanDim
    }
}
