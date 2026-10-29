import QtQuick
import ".."

// KIT · Heading — a group's name inside a panel (a KEYS section).
// Lantern: amber, like a chapter in a ledger; pink when `lit` (a match).
LText {
    property bool lit: false
    bottomPadding: 2
    color: lit ? Theme.lanPink : Theme.lanAmber
}
