import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · Label — words inside a panel, by role:
//   body      what you read (a message): wraps
//   headline  the main line (a track title): bright, two lines at most
//   sub       the line under it (an artist)
//   note      a remark under something: wraps (oneLine: elides instead)
//   small     a quiet readout (0:42 / 3:15)
//   fine      small print (an id, a path): dim, elides in the middle
//   empty     what shows when a list has nothing in it
//   none      the same (a menu with no entries)
//   nomatch   a grid / list that found nothing (no match, reading…)
//   path      where you are (/ wallpapers / dark): elides from the left
//   caption   the name of the thing under the cursor
//   tag       a name for a readout (vol)
//   readout   the number itself (52%)
// tone: "alarm" / "warn" colour it; "dim" quiets it.
// Lantern: one size for all of them (rule 6); the role is only colour. The
// words are drawn by a copy laid over this one with Jersey's own symbols
// (Glyphs.js); this Text keeps the size and layout the module asked for.
LText {
    id: label
    property string role: "body"
    property string tone: ""
    property bool oneLine: false

    readonly property bool wraps: !oneLine && (role === "body" || role === "note" || role === "headline")

    width: parent ? parent.width : implicitWidth
    wrapMode: wraps ? Text.Wrap : Text.NoWrap
    maximumLineCount: role === "headline" ? 2 : 1000
    elide: role === "fine" || role === "caption" ? Text.ElideMiddle
         : role === "path" ? Text.ElideLeft
         : role === "headline" || role === "sub" || oneLine ? Text.ElideRight
         : Text.ElideNone
    readonly property color ink: tone === "alarm" ? Theme.lanAlarm
         : tone === "warn" ? Theme.lanWarn
         : tone === "dim" ? Theme.lanDim
         : ({ body: Theme.lanText, headline: Theme.lanBright, sub: Theme.lanText, note: Theme.lanDim,
              small: Theme.lanDim, fine: Theme.lanDim, tag: Theme.lanDim, readout: Theme.lanBright, empty: Theme.lanDim,
              none: Theme.lanDim, nomatch: Theme.lanDim, path: Theme.lanDim, caption: Theme.lanText })[role] || Theme.lanText
    color: "transparent"

    LText {
        anchors.fill: parent
        text: G.plain(label.text)
        color: label.ink
        wrapMode: label.wrapMode
        maximumLineCount: label.maximumLineCount
        elide: label.elide
        horizontalAlignment: label.horizontalAlignment
        verticalAlignment: label.verticalAlignment
        topPadding: label.topPadding
        bottomPadding: label.bottomPadding
        leftPadding: label.leftPadding
        rightPadding: label.rightPadding
    }
}
