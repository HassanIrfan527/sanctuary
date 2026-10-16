import QtQuick
import ".."

// KIT · ModeTabs — a row of modes, the live one marked (APPS · *PINNED · =CALC…),
// with a readout at the right. picked(index) when one is clicked.
Item {
    id: tabs
    property var labels: []
    property int current: 0
    property string detail: ""
    signal picked(int index)

    width: parent ? parent.width : 0
    height: 30
    Row {
        x: 8
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
                Text {
                    id: tabText
                    anchors.centerIn: parent
                    text: tab.modelData
                    font.family: Theme.mono
                    font.pixelSize: 10
                    font.weight: tab.on ? Font.Bold : Font.Normal
                    font.letterSpacing: 1.4
                    color: tab.on ? Theme.sigHot : Theme.sigLabel
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 8
                    height: 2
                    color: Theme.sigHot
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
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: tabs.detail
        font.family: Theme.mono
        font.pixelSize: 9
        font.letterSpacing: 1.4
        color: Theme.surface2
    }
}
