import QtQuick

// One manga panel: paper face, ink outline, hard offset shadow in the module's
// accent. The shadow is the module's identity — you tell the clock from the mic
// by the colour sticking out from under it, without reading either.
//
// Children go inside, vertically centred, with `padX` of air either side.
Item {
    id: root

    property color accent: Theme.peach
    property color face: Theme.paper
    property int padX: 12
    property real tone: 0            // halftone strength; 0 = plain paper
    property real toneFrom: 0.55
    property real progress: -1       // ≥0 draws an ink strip along the bottom
    property bool hot: false         // attention: the shadow grows (pressing does it too)
    property bool interactive: false // take clicks / wheel on the whole panel

    signal clicked(var mouse)
    signal scrolled(var wheel)

    default property alias content: holder.data

    implicitWidth: holder.childrenRect.width + padX * 2 + Theme.inkStroke * 2
    implicitHeight: Theme.inkPanelH

    // Pressing collapses the shadow to 1px, so the panel reads as pushed into
    // the page; attention (`hot`) does the opposite and lifts it.
    readonly property bool _down: area.pressed
    readonly property int shadowOffset: _down ? 1 : hot ? Theme.inkShadow + 2 : Theme.inkShadow

    Rectangle {
        id: shadow
        x: root.shadowOffset
        y: root.shadowOffset
        width: root.width
        height: root.height
        color: root.accent
        Behavior on color { ColorAnimation { duration: Theme.duration } }
        Behavior on x { NumberAnimation { duration: Theme.quick; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: Theme.quick; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        id: faceRect
        anchors.fill: parent
        color: root.face
        border.width: Theme.inkStroke
        border.color: Theme.inkLine

        InkHalftone {
            anchors.fill: parent
            anchors.margins: Theme.inkStroke
            visible: root.tone > 0
            strength: root.tone
            from: root.toneFrom
        }

        Rectangle {
            visible: root.progress >= 0
            x: Theme.inkStroke
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.inkStroke
            height: 3
            width: Math.max(0, (parent.width - Theme.inkStroke * 2) * root.progress)
            color: Theme.inkLine
            Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
        }
    }

    // Declared before the content, so it sits UNDER it: a child with its own
    // MouseArea (a workspace box) still gets its click first.
    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.interactive
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.scrolled(wheel)
    }

    Item {
        id: holder
        x: root.padX + Theme.inkStroke
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
