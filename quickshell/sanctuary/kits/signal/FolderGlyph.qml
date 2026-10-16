import QtQuick
import ".."

// KIT · FolderGlyph — a folder, drawn — not an icon-font glyph (DESIGN-BRIEF §4: square line work
// over icon fonts). Two outlined rectangles: a short tab, and the body laid
// over the tab's bottom edge so the two read as one shape. `label` sits inside
// the body (".." for the way up). Used by WallPicker.qml in both styles; the
// style picks the stroke, line and fill.
//
//   ┌────┐
//   │    └─────────┐
//   │      ..      │
//   └──────────────┘
Item {
    id: root
    property color line: Theme.sigLabel
    property color fill: "transparent"
    property int stroke: 1
    property string label: ""
    property string labelFont: Theme.mono
    property int labelSize: 11
    property int labelWeight: Font.Bold

    implicitWidth: 44
    implicitHeight: 32

    readonly property int tabH: Math.round(height * 0.22)

    Rectangle {   // tab
        width: Math.round(root.width * 0.42)
        height: root.tabH + root.stroke
        color: root.fill
        border.width: root.stroke
        border.color: root.line
    }
    Rectangle {   // body, over the tab's bottom edge
        y: root.tabH
        width: root.width
        height: root.height - root.tabH
        color: root.fill
        border.width: root.stroke
        border.color: root.line

        Text {
            anchors.centerIn: parent
            visible: root.label !== ""
            text: root.label
            font.family: root.labelFont
            font.pixelSize: root.labelSize
            font.weight: root.labelWeight
            color: root.line
        }
    }
}
