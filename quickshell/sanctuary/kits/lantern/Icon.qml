import QtQuick
import QtQuick.Shapes
import "icons/paths.js" as Paths
import ".."

// KIT · Icon — a thing, by name (DESIGN-SYSTEM §3 rule 5). Lantern draws
// Pixelarticons (Gerrit Halfmann, MIT, hand-drawn; icons/LICENSE): one path
// on a 24-unit grid with 2-unit pixels, so at 24px every icon pixel is two
// screen pixels, the same grid as the frames. Single colour: the theme paints
// it (pink when it's yours, state colours for the machine).
//
//   name    a Pixelarticons name ("zap"), or what a module already says:
//           a glyph ("⏻", "◉") or a bar label ("CPU", "MSG") — see `aliases`
//   size    24 = 1:1 · 48 = 2× (whole multiples only: the pixels stay square)
// An unknown name draws nothing and takes no width (`known` is false).
Item {
    id: icon
    property string name: ""
    property color color: Theme.lanDim
    property int size: 24

    readonly property var aliases: ({
        // bar labels: things, not labels (rule 4)
        "TMR": "hourglass", "CPU": "zap", "MEM": "backpack", "MIC": "mic", "PLAY": "music",
        "HOLD": "music", "VC": "headphone", "MSG": "mailbox", "SCR": "video", "AUD·1": "mic",
        "AUD·2": "users", "TEMP": "thermometer", "DISK": "save", "VOL": "volume-2",
        // the glyphs modules hand over (launcher DESK, web, RIG, …)
        "⇄": "shuffle", "≋": "sliders", "◉": "video", "◎": "headphone", "▣": "monitor",
        "⌗": "camera", "⎘": "clipboard", "▤": "image", "▥": "layout", "◐": "colors-swatch",
        "☰": "bell", "◌": "bell-off", "☾": "moon", "☼": "sun", "○": "lightbulb-off",
        "󰂯": "radio", "▔": "arrow-bar-up", "↔": "arrows-horizontal", "⌨": "keyboard",
        "⏻": "power", "⊘": "lock", "z": "bed", "◆": "file", "+": "plus", "·": "more-horizontal",
        "=": "calculator", "✎": "book-open", "↗": "external-link", "▶": "play", "⌥": "github", "W": "book-open",
        "…": "more-horizontal", "▸": "chevron-right", "✕": "close", "■": "stop", "‖": "pause",
        "▶|": "arrow-bar-right", "|◀": "arrow-bar-left",
        // apps (a toast's header, a workspace)
        "discord": "discord", "vesktop": "discord", "brave": "globe", "brave-browser": "globe",
        "firefox": "globe", "qutebrowser": "globe", "kitty": "terminal", "vulms": "book-open"
    })
    readonly property string key: {
        const n = String(name);
        const a = Paths.d[n] !== undefined ? n : (aliases[n] || aliases[n.toLowerCase()] || "");
        return Paths.d[a] !== undefined ? a : "";
    }
    readonly property bool known: key !== ""

    visible: known
    width: known ? size : 0
    height: size

    Shape {
        width: 24
        height: 24
        scale: icon.size / 24
        transformOrigin: Item.TopLeft
        ShapePath {
            fillColor: icon.color
            strokeWidth: -1
            strokeColor: "transparent"
            PathSvg { path: Paths.d[icon.key] || "" }
        }
    }
}
