import QtQuick

// KIT · Scrim — what sits behind a popup's card. Lantern: nothing (the card's
// hard shadow is enough), or with `dim` a 45% dusk wash (a prompt that must
// be answered).
Rectangle {
    property bool dim: false
    color: dim ? Qt.rgba(0.04, 0.02, 0.05, 0.45) : "transparent"
}
