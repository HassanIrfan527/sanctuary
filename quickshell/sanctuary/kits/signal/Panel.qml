import QtQuick
import ".."

// KIT · Panel — a card that holds things. Signal: a filled box with a
// hairline edge and registration marks at the corners.
//
//   ┌ TITLE ──────────────────────────── detail ┐
//   │ (content: MenuRow, …)                     │
//   └ hint ─────────────────────────────────────┘
//
// A list card (rows run edge to edge) keeps the defaults. A sheet (KEYS)
// pads its content in: `pad: 18, inset: 0, spacing: 10, ruled: true`.
//   tone         state of the marks: "" | "live" | "warn" | "alarm"
//   titleTone / detailTone / edgeTone   the same, for the title, the detail
//                and the border (a wrong password, …)
//   fit          the card is as wide as its content (+ pad on both sides)
//   headerItems  extra items at the title line's right, after `detail`
Rectangle {
    id: panel

    property string title: ""
    property string detail: ""
    property string hint: ""
    property string tone: ""
    property string titleTone: ""
    property string titleRole: "title"   // "status": a live line (PLAY · SPOTIFY), not a name
    property string detailTone: ""
    property bool detailStrong: false    // the detail is a state word (LIVE, MUTE): bold
    property string edgeTone: ""
    property int headerHeight: 20
    property int pad: 1          // content's distance from the edge
    property int vpad: 12        // … from the top and bottom
    property int inset: 14       // title / hint / detail indent inside the content
    property int spacing: 2
    property bool ruled: false   // hairline under the header
    property int hintGap: 8
    property bool hintCaps: false        // the hint in small caps, label colour (a strip, not a list)
    property bool fit: false
    default property alias content: body.data
    property alias headerItems: right.data

    implicitWidth: fit ? Math.max(body.implicitWidth, hintText.visible ? hintText.implicitWidth + 2 * inset : 0) + 2 * pad : 0
    implicitHeight: col.implicitHeight + 2 * vpad
    height: implicitHeight
    color: Theme.sigFill
    border.width: 1
    border.color: toned(edgeTone, Theme.sigRule)

    function toned(t, base) {
        return t === "alarm" ? Theme.sigAlarm : t === "warn" ? Theme.sigWarn : t === "live" ? Theme.sigHot : base;
    }

    Ticks {
        anchors.fill: parent
        anchors.margins: -3
        color: panel.toned(panel.tone, Theme.sigHot)
    }

    Column {
        id: col
        x: panel.pad
        y: panel.vpad
        width: parent.width - 2 * panel.pad
        spacing: panel.spacing

        Item {
            width: parent.width
            height: panel.headerHeight
            visible: panel.title !== ""

            Text {
                x: panel.inset
                anchors.top: parent.top
                text: panel.title
                font.family: Theme.mono
                font.pixelSize: 9
                font.weight: Font.Bold
                font.letterSpacing: panel.titleRole === "status" ? 1.4 : 2
                color: panel.titleTone === "dim" ? Theme.sigLabel : panel.toned(panel.titleTone, Theme.sigHot)
            }
            Row {
                id: right
                anchors.right: parent.right
                anchors.rightMargin: panel.inset
                anchors.top: parent.top
                spacing: 8

                Text {
                    visible: panel.detail !== ""
                    text: panel.detail
                    font.family: Theme.mono
                    font.pixelSize: 9
                    font.weight: panel.detailStrong ? Font.Bold : Font.Normal
                    font.letterSpacing: 1.4
                    color: panel.toned(panel.detailTone, Theme.sigLabel)
                }
            }
        }

        Rectangle {
            visible: panel.ruled
            width: parent.width
            height: 1
            color: Theme.sigRule
        }

        Column {
            id: body
            width: parent.width
            spacing: panel.spacing
        }

        Text {
            id: hintText
            x: panel.inset
            topPadding: panel.hintGap
            visible: panel.hint !== ""
            text: panel.hint
            font.family: Theme.mono
            font.pixelSize: 9
            font.letterSpacing: panel.hintCaps ? 1 : 0
            color: panel.hintCaps ? Theme.sigLabel : Theme.surface2
        }
    }
}
