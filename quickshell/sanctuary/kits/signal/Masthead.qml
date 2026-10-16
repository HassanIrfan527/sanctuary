import QtQuick
import ".."

// KIT · Masthead — the top of the launcher: the style's name as a wordmark,
// a subtitle, the time and a readout. `kick()` when something happens (you
// typed): the style reacts. `active` = animate (only while on screen).
// Signal: a scope screen — faint graticule, a slow carrier trace that jumps on
// a kick and settles, the wordmark with CRT scanlines.
//
//   SIGNAL  ∿∿∿∿∿∿∿ live trace ∿∿∿∿∿∿∿              19:06
//   SANCTUARY // CONSOLE                CITADEL · UP 3H 12M
Item {
    id: head
    property string word: ""
    property string subtitle: ""
    property string time: ""
    property string detail: ""
    property bool active: false

    function kick() { energy = Math.min(1.6, energy + 0.55); }

    property real phase: 0
    property real energy: 0.35

    width: parent ? parent.width : 0
    height: 78
    clip: true

    Timer {
        running: head.active
        interval: 33
        repeat: true
        onTriggered: {
            head.phase += 0.12;
            head.energy = Math.max(0.18, head.energy * 0.94);
            traceCanvas.requestPaint();
        }
    }

    // graticule: faint dots every 20px, like a scope screen
    Canvas {
        anchors.fill: parent
        onPaint: {
            const c = getContext("2d");
            c.reset();
            c.fillStyle = Theme.surface0;
            for (let x = 10; x < width; x += 20)
                for (let y = 9; y < height; y += 20)
                    c.fillRect(x, y, 1, 1);
        }
    }

    // the trace
    Canvas {
        id: traceCanvas
        x: 200
        width: parent.width - 200 - 150
        height: parent.height
        onPaint: {
            const c = getContext("2d");
            c.reset();
            const mid = height / 2, w = width, ph = head.phase, en = head.energy;
            // fade in / out at both ends so the line comes from nowhere
            const env = x => Math.sin(Math.PI * x / w);
            const pass = (alpha, lw) => {
                c.beginPath();
                for (let x = 0; x <= w; x += 2) {
                    const t = x / 18;
                    const y = mid + env(x) * en * (Math.sin(t - ph) * 9
                              + Math.sin(t * 2.7 + ph * 1.6) * 4 * en
                              + Math.sin(t * 7.1 - ph * 3) * 2 * en);
                    if (x === 0)
                        c.moveTo(x, y);
                    else
                        c.lineTo(x, y);
                }
                c.strokeStyle = Qt.rgba(Theme.sigHot.r, Theme.sigHot.g, Theme.sigHot.b, alpha);
                c.lineWidth = lw;
                c.stroke();
            };
            c.fillStyle = Qt.rgba(Theme.sigHot.r, Theme.sigHot.g, Theme.sigHot.b, 0.12);
            c.fillRect(0, mid, w, 1);   // the zero line
            pass(0.12, 5);              // glow
            pass(0.85, 1.2);            // line
        }
    }

    // wordmark: the style's name
    Item {
        id: mark
        x: 18
        y: 13
        width: word.implicitWidth
        height: word.implicitHeight
        Text {
            id: word
            text: head.word
            font.family: Theme.mono
            font.pixelSize: 30
            font.weight: Font.Black
            font.letterSpacing: 7
            color: Theme.sigHot
        }
        // scanlines over the letters: a CRT, not a logo
        Column {
            anchors.fill: parent
            Repeater {
                model: Math.ceil(word.implicitHeight / 3)
                delegate: Item {
                    width: mark.width
                    height: 3
                    Rectangle { y: 2; width: parent.width; height: 1; color: Theme.sigFill; opacity: 0.55 }
                }
            }
        }
    }
    Text {
        x: 19
        anchors.top: mark.bottom
        anchors.topMargin: 2
        text: head.subtitle
        font.family: Theme.mono
        font.pixelSize: 9
        font.letterSpacing: 2
        color: Theme.sigLabel
    }

    // clock + readout
    Column {
        anchors.right: parent.right
        anchors.rightMargin: 18
        y: 16
        spacing: 5
        Text {
            anchors.right: parent.right
            text: head.time
            font.family: Theme.mono
            font.pixelSize: 22
            font.weight: Font.Bold
            color: Theme.sigValue
        }
        Text {
            anchors.right: parent.right
            text: head.detail
            font.family: Theme.mono
            font.pixelSize: 9
            font.letterSpacing: 1.2
            color: Theme.sigLabel
        }
    }
}
