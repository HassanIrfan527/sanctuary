pragma Singleton
import QtQuick
import Quickshell

// Tokens for every Quickshell surface.
//
// THE ONE WORD: `SANCTUARY_QS`, exported by scripts/sanctuary/qs.sh.
// `signal` → Signal, `flare` → Flare (Signal in daylight). Anything else falls
// back to Signal rather than showing nothing. (Ink and Paper, the manga
// styles, were removed 2026-10-16 — unused since they were built.)
Singleton {
    id: root

    // The words: `signal`, `flare`. They are one style printed two ways: Flare
    // draws with the Signal*.qml files on the parchment palette (2026-10-12).
    readonly property string word: String(Quickshell.env("SANCTUARY_QS") || "signal").toLowerCase()
    readonly property bool flare: word === "flare"
    readonly property string style: "signal"
    readonly property bool signal: true

    // ── Catppuccin Mocha (DESIGN-BRIEF §4) — or Flare's parchment ─────
    // Flare keeps the NAMES so every Signal file restyles untouched; the values
    // are warm parchment that reads white but isn't (Kanagawa-lotus feel), deep
    // indigo ink, and dark-enough accents (all >= 4:1 on mantle). The roles flip
    // where the hue would fail on paper: the trace is ember, not green (`sigHot`),
    // and peach — Signal's warm second voice — turns cool teal, so it still
    // stands apart from the trace.
    readonly property color crust: flare ? "#e2d4ad" : "#11111b"     // strip fill
    readonly property color mantle: flare ? "#eadfc0" : "#181825"    // cells, cards
    readonly property color base: flare ? "#f1e8cf" : "#1e1e2e"      // windows
    readonly property color surface0: flare ? "#d6c69c" : "#313244"  // rules, selection
    readonly property color surface1: flare ? "#c6b48a" : "#45475a"
    readonly property color surface2: flare ? "#a8986f" : "#585b70"  // "off" / dim
    readonly property color overlay0: flare ? "#857a62" : "#6c7086"  // labels
    readonly property color subtext0: flare ? "#5c5445" : "#a6adc8"
    readonly property color text: flare ? "#2b2838" : "#cdd6f4"      // ink
    readonly property color lavender: flare ? "#3f56a6" : "#b4befe"  // indigo
    readonly property color mauve: flare ? "#74489a" : "#cba6f7"     // violet
    readonly property color peach: flare ? "#17706a" : "#fab387"     // teal (see above)
    readonly property color green: flare ? "#3d7a2a" : "#a6e3a1"
    readonly property color teal: flare ? "#17706a" : "#94e2d5"
    readonly property color yellow: flare ? "#8a6400" : "#f9e2af"    // ochre
    readonly property color red: flare ? "#b0283c" : "#f38ba8"       // crimson
    readonly property color ember: "#b04a06"                         // Flare's trace

    // Left-pad to a fixed width so readouts never change size as numbers move.
    // (Hand-rolled: String.padStart is ES2017, newer than QML's JS baseline.)
    function pad(v, n, ch) {
        let s = String(v);
        while (s.length < n)
            s = ch + s;
        return s;
    }

    // ── Motion ────────────────────────────────────────────────────────
    readonly property int quick: 120     // exits: shorter than §2's 160
    readonly property int duration: 160  // everything else

    // ── Type ──────────────────────────────────────────────────────────
    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property string sans: "Geist"

    // ── Signal: instrument panel ──────────────────────────────────────
    readonly property color sigFill: crust
    readonly property color sigCell: mantle
    readonly property color sigRule: surface0
    readonly property color sigLabel: overlay0
    readonly property color sigValue: text
    readonly property color sigHot: flare ? ember : green   // the trace colour
    readonly property color sigWarn: yellow
    readonly property color sigAlarm: red
    readonly property int sigStripH: 35           // was 30; +5 on 2026-10-03, Harry's call
    readonly property int sigBarH: 47             // 6 top + 35 strip + 6 air
}
