import QtQuick
import ".."

// KIT · Label — words inside a panel, by role:
//   body      what you read (a message): wraps
//   headline  the main line (a track title): bold, two lines at most
//   sub       the line under it (an artist)
//   note      a remark under something: wraps (oneLine: elides instead)
//   small     a quiet readout (0:42 / 3:15)
//   fine      small print (an id, a path): faint, elides in the middle
//   empty     what shows when a list has nothing in it
//   none      the same, in small caps (a menu with no entries)
//   nomatch   a grid / list that found nothing (NO MATCH, READING…)
//   path      where you are (/ WALLPAPERS / DARK): small caps, elides from the left
//   caption   the name of the thing under the cursor
//   tag       a small-caps name for a readout (VOL)
//   readout   the number itself (52%)
// tone: "alarm" / "warn" colour it; "dim" quiets it.
Text {
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
    font.family: Theme.mono
    font.pixelSize: ({ body: 12, headline: 13, sub: 11, note: 10, small: 9, fine: 9, tag: 9, readout: 12, empty: 11, none: 9, nomatch: 10, path: 9, caption: 10 })[role] || 12
    font.weight: role === "headline" || role === "tag" || role === "readout" ? Font.Bold : Font.Normal
    font.letterSpacing: role === "tag" || role === "path" ? 1.4 : role === "none" || role === "nomatch" ? 1.6 : 0
    color: tone === "alarm" ? Theme.sigAlarm
         : tone === "warn" ? Theme.sigWarn
         : tone === "dim" ? Theme.surface2
         : ({ body: Theme.sigValue, headline: Theme.sigValue, sub: Theme.subtext0, note: Theme.sigLabel,
              small: Theme.sigLabel, fine: Theme.surface2, tag: Theme.sigLabel, readout: Theme.sigValue, empty: Theme.surface2, none: Theme.surface2,
              nomatch: Theme.surface2, path: Theme.sigLabel, caption: Theme.sigValue })[role] || Theme.sigValue
}
