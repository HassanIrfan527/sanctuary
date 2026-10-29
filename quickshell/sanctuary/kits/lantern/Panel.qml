import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · Panel — a card that holds things. Lantern: a wooden frame with paper
// inside and a hard shadow (three materials: wood frames, paper holds).
//
//   ╔ title ──────────────────────────── detail ╗
//   ║ (content: MenuRow, …)                     ║
//   ╚ hint ─────────────────────────────────────╝
//
// A list card (rows run edge to edge) keeps the defaults. A sheet (KEYS)
// pads its content in: `pad: 18, inset: 0, spacing: 10, ruled: true`.
//   tone         "" | "live" | "warn" | "alarm": warn / alarm colour the frame
//   titleTone / detailTone / edgeTone   the same, for the title, the detail
//                and the frame (a wrong password, …)
//   fit          the card is as wide as its content (+ pad on both sides)
//   headerItems  extra items at the title line's right, after `detail`
Item {
    id: panel

    property string title: ""
    property string detail: ""
    property string hint: ""
    property string tone: ""
    property string titleTone: ""
    property string titleRole: "title"   // "status": a live line (play · spotify), not a name
    property string detailTone: ""
    property bool detailStrong: false
    property string edgeTone: ""
    property int headerHeight: 20
    property int pad: 1          // content's distance from the paper's edge
    property int vpad: 12        // … from the top and bottom
    property int inset: 14       // title / hint / detail indent inside the content
    property int spacing: 2
    property bool ruled: false   // a groove under the header
    property int hintGap: 8
    property bool hintCaps: false
    property bool fit: false
    default property alias content: body.data
    property alias headerItems: right.data

    readonly property int edge: wood.edge

    implicitWidth: fit ? Math.max(body.implicitWidth, hintText.visible ? hintText.implicitWidth + 2 * inset : 0) + 2 * pad + 2 * edge : 0
    implicitHeight: col.implicitHeight + 2 * vpad + 2 * edge
    height: implicitHeight

    function toned(t, base) {
        return t === "alarm" ? Theme.lanAlarm : t === "warn" ? Theme.lanWarn : t === "live" ? Theme.lanOk : base;
    }

    Wood {
        id: wood
        anchors.fill: parent
        thick: 6
        shadow: true
        outline: panel.edgeTone === "alarm" || panel.tone === "alarm" ? Theme.lanAlarm
               : panel.edgeTone === "warn" || panel.tone === "warn" ? Theme.lanWarn
               : Theme.lanOutline
    }

    Column {
        id: col
        x: panel.edge + panel.pad
        y: panel.edge + panel.vpad
        width: parent.width - 2 * panel.pad - 2 * panel.edge
        spacing: panel.spacing

        Item {
            width: parent.width
            height: Math.max(panel.headerHeight, 26)
            visible: panel.title !== ""

            LText {
                x: Math.min(panel.inset, 12)
                anchors.top: parent.top
                width: Math.min(implicitWidth, parent.width - right.width - 24)
                elide: Text.ElideRight
                text: G.plain(panel.title.toLowerCase())
                color: panel.titleTone === "dim" ? Theme.lanDim : panel.toned(panel.titleTone, Theme.lanBright)
            }
            Row {
                id: right
                anchors.right: parent.right
                anchors.rightMargin: Math.min(panel.inset, 12)
                anchors.top: parent.top
                spacing: 8

                LText {
                    visible: panel.detail !== ""
                    text: G.plain(panel.detail.toLowerCase())
                    color: panel.toned(panel.detailTone, Theme.lanDim)
                }
            }
        }

        Rectangle {
            visible: panel.ruled
            width: parent.width
            height: 2
            color: Theme.lanSunk
        }

        Column {
            id: body
            width: parent.width
            spacing: panel.spacing
        }

        LText {
            id: hintText
            x: Math.min(panel.inset, 12)
            width: Math.min(implicitWidth, parent.width - 2 * x)
            elide: Text.ElideRight
            topPadding: panel.hintGap
            visible: panel.hint !== ""
            text: G.plain(panel.hintCaps ? panel.hint.toLowerCase() : panel.hint)
            color: Theme.lanDim
        }
    }
}
