import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

// The system tray, shared by both styles. Left click activates, middle is the
// secondary action, right opens the app's own menu — drawn by TrayMenu.qml in
// the current style. (Not `modelData.display()`: that hands the menu to Qt's
// native QMenu, which ignores our styles and renders as a white box.)
Row {
    id: root
    property int iconSize: 14
    spacing: 8

    readonly property bool empty: SystemTray.items.values.length === 0

    Repeater {
        model: SystemTray.items

        delegate: MouseArea {
            id: cell
            required property SystemTrayItem modelData

            width: root.iconSize
            height: root.iconSize
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor

            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton && !modelData.onlyMenu) {
                    modelData.activate();
                } else if (mouse.button === Qt.MiddleButton) {
                    modelData.secondaryActivate();
                } else if (modelData.hasMenu) {
                    Ui.trayX = cell.mapToItem(null, cell.width / 2, 0).x;
                    Ui.trayMenu = modelData.menu;
                }
            }

            IconImage {
                anchors.fill: parent
                source: cell.modelData.icon
                asynchronous: true
            }
        }
    }
}
