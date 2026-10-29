import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · Value — what a bar cell reads (00:42, LIVE, 04).
//   tone   "" | "hot" | "warn" | "alarm" | "dim" | "soft" | "second"
//   strong a state word (Lantern has one weight: ignored) · size "glyph": a
//          glyph the kit knows (◉) is drawn as its icon
// Lantern reads which cell it sits in, so the colour keeps its one job:
// the message count is a pink badge (unread = you), a running timer is amber
// (time), recording audio is cyan (sound), anything else live is green.
LText {
    id: v
    property string tone: ""
    property bool strong: false
    property string size: ""

    readonly property string cell: parent && parent.parent ? (parent.parent["cellLabel"] || "") : ""
    readonly property bool badge: cell === "MSG" && tone === "second"
    readonly property bool asIcon: size === "glyph" && glyph.known
    readonly property color toneColor:
          tone === "hot" ? (cell === "TMR" ? Theme.lanAmber : size === "glyph" ? Theme.lanPink : Theme.lanOk)
        : tone === "warn" ? Theme.lanWarn : tone === "alarm" ? Theme.lanAlarm
        : tone === "dim" ? Theme.lanDim
        : tone === "second" ? (badge ? Theme.lanOnPink : Theme.lanSound)
        : Theme.lanText

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    // Drawn by the copy below with Jersey's own symbols (Glyphs.js); a glyph
    // the kit knows is drawn as its icon instead (this text stays, tiny).
    color: "transparent"
    leftPadding: badge ? 6 : asIcon ? 24 : 0
    rightPadding: badge ? 6 : 0
    font.pixelSize: asIcon ? 1 : Theme.lanSize
    textFormat: Text.PlainText

    Rectangle {   // the badge: pink, notched
        visible: v.badge
        z: -1
        x: 0
        y: Math.round((v.height - 20) / 2)
        width: v.width
        height: 20
        color: Theme.lanPink
        Rectangle { width: 2; height: 2; color: Theme.lanPaper }
        Rectangle { x: parent.width - 2; width: 2; height: 2; color: Theme.lanPaper }
        Rectangle { y: 18; width: 2; height: 2; color: Theme.lanPaper }
        Rectangle { x: parent.width - 2; y: 18; width: 2; height: 2; color: Theme.lanPaper }
    }
    Icon {
        id: glyph
        visible: v.size === "glyph" && known
        anchors.verticalCenter: parent.verticalCenter
        name: v.size === "glyph" ? v.text : ""
        color: v.tone === "hot" ? Theme.lanPink : v.tone === "warn" ? Theme.lanWarn : v.tone === "alarm" ? Theme.lanAlarm : Theme.lanDim
    }
    LText {
        anchors.fill: parent
        visible: !v.asIcon
        text: G.plain(v.text)
        color: v.toneColor
        elide: v.elide
        horizontalAlignment: v.horizontalAlignment
        verticalAlignment: v.verticalAlignment
        leftPadding: v.leftPadding
        rightPadding: v.rightPadding
    }
}
