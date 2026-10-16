import QtQuick

// KIT · Scrim — what sits behind a popup's card. Signal: nothing at all, or
// with `dim` a 35% black wash (a prompt that must be answered).
Rectangle {
    property bool dim: false
    color: dim ? Qt.rgba(0, 0, 0, 0.35) : "transparent"
}
