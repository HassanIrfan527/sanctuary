pragma Singleton
import QtQuick
import Quickshell

// Tokens for every Quickshell surface, both styles.
//
// THE ONE WORD: `SANCTUARY_QS`, exported by scripts/sanctuary/qs.sh from the
// mode file's `BAR=` line. `BAR=ink` → Ink (dark manga), `BAR=paper` → Paper
// (light manga), `BAR=signal` → Signal. Anything else falls back to Ink rather than
// showing nothing.
Singleton {
    id: root

    // The words: `ink`, `paper`, `signal`. Ink and Paper are the same manga
    // style printed two ways — Ink is ONLY ever dark, Paper is the light one —
    // so both draw with the Ink*.qml files and differ only in the palette below.
    readonly property string word: String(Quickshell.env("SANCTUARY_QS") || "ink").toLowerCase()
    readonly property string style: word === "signal" ? "signal" : "ink"
    readonly property bool light: word === "paper"
    readonly property bool ink: style === "ink"
    readonly property bool signal: style === "signal"

    // ── Catppuccin Mocha (DESIGN-BRIEF §4) ────────────────────────────
    readonly property color crust: "#11111b"
    readonly property color mantle: "#181825"
    readonly property color base: "#1e1e2e"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color surface2: "#585b70"
    readonly property color overlay0: "#6c7086"
    readonly property color subtext0: "#a6adc8"
    readonly property color text: "#cdd6f4"
    readonly property color lavender: "#b4befe"
    readonly property color mauve: "#cba6f7"
    readonly property color peach: "#fab387"
    readonly property color green: "#a6e3a1"
    readonly property color teal: "#94e2d5"
    readonly property color yellow: "#f9e2af"
    readonly property color red: "#f38ba8"

    // Left-pad to a fixed width so readouts never change size as numbers move.
    // (Hand-rolled: String.padStart is ES2017, newer than QML's JS baseline.)
    function pad(v, n, ch) {
        let s = String(v);
        while (s.length < n)
            s = ch + s;
        return s;
    }

    // ── Motion ────────────────────────────────────────────────────────
    readonly property int quick: 120     // Ink's slam: shorter than §2's 160, it is an impact
    readonly property int duration: 160  // everything else

    // ── Type ──────────────────────────────────────────────────────────
    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property string sans: "Geist"
    // Ink's lettering face. Bangers if it is installed (README has the command),
    // otherwise Geist at Black weight, which is already on the system.
    readonly property bool hasBangers: Qt.fontFamilies().indexOf("Bangers") >= 0
    readonly property string display: hasBangers ? "Bangers" : "Geist"
    readonly property int displayWeight: hasBangers ? Font.Normal : Font.Black

    // ── Ink: manga panels ─────────────────────────────────────────────
    // Paper panels drawn in ink, on a dark desk. The shadow carries the module's
    // identity (§4: border colour is identity — here it moved to the shadow,
    // because the outline is always ink).
    //
    // Two printings of the same page. Every Ink file uses only these names, so
    // the variant is decided here and nowhere else:
    //   ink    dark — Mocha panels, light "ink" outlines (the default)
    //   paper  light — Latte panels, black ink outlines
    // "paper" = the panel face, "inkLine" = outlines + primary text, whatever
    // their actual lightness.
    readonly property color paper: light ? "#eff1f5" : "#1e1e2e"      // Latte base  | Mocha base
    readonly property color paperDim: light ? "#ccd0da" : "#181825"   // a face that is "off" (mic muted)
    readonly property color paperShade: light ? "#ccd0da" : "#313244" // shadows cast ON a page
    readonly property color paperHover: light ? "#ffffff" : "#313244"
    readonly property color inkLine: light ? "#11111b" : "#cdd6f4"
    readonly property color inkSoft: light ? "#4c4f69" : "#a6adc8"    // body text
    readonly property color inkMuted: light ? "#8c8fa1" : "#6c7086"   // de-emphasised
    readonly property int inkStroke: 3
    readonly property int inkShadow: 4
    readonly property int inkPanelH: 34
    readonly property int inkBarH: 52             // 8 top + 34 panel + 4 shadow + 6 air

    // ── Signal: instrument panel ──────────────────────────────────────
    readonly property color sigFill: crust
    readonly property color sigCell: mantle
    readonly property color sigRule: surface0
    readonly property color sigLabel: overlay0
    readonly property color sigValue: text
    readonly property color sigHot: green         // the trace colour
    readonly property color sigWarn: yellow
    readonly property color sigAlarm: red
    readonly property int sigStripH: 35           // was 30; +5 on 2026-10-03, Harry's call
    readonly property int sigBarH: 47             // 6 top + 35 strip + 6 air
}
