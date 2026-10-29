pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Tokens for every Quickshell surface.
//
// THE ONE WORD: `SANCTUARY_QS`, exported by scripts/sanctuary/qs.sh.
// `signal` → Signal, `flare` → Flare (Signal in daylight), `lantern` →
// Lantern (the pixel style, night), `harvest` → Harvest (Lantern by day).
// Anything else falls back to Signal rather than showing nothing. (Ink and
// Paper, the manga styles, were removed 2026-10-16.)
Singleton {
    id: root

    // The words. Two styles, each printed two ways: Flare draws with
    // kits/signal on parchment (2026-10-12); Harvest draws with kits/lantern
    // in the afternoon (2026-10-16).
    readonly property string word: ["signal", "flare", "lantern", "harvest"].indexOf(rawWord) >= 0 ? rawWord : "signal"
    readonly property string rawWord: String(Quickshell.env("SANCTUARY_QS") || "signal").toLowerCase()
    readonly property bool flare: word === "flare"
    readonly property bool harvest: word === "harvest"
    readonly property string style: word === "lantern" || word === "harvest" ? "lantern" : "signal"
    readonly property bool signal: style === "signal"

    // ── Signal's palette (Mod+Shift+C, scripts/sanctuary/palette.sh) ──────
    // palettes/signal.json holds every palette; ~/.local/state/sanctuary/palette
    // names the chosen one. Both are watched, so a pick restyles everything that
    // binds these colours at once — no restart. Colours only: shapes and fonts
    // stay Signal's. The fallbacks below are the default palette (Mocha), used
    // if either file is missing or broken. Flare ignores the palette.
    readonly property string home: Quickshell.env("HOME")
    property string paletteWord: "default"
    property var palettes: []
    readonly property var pal: palettes.find(p => p.word === paletteWord) || palettes[0] || ({})
    function pc(role, fallback) {
        return pal[role] || fallback;
    }
    FileView {
        path: root.home + "/.local/state/sanctuary/palette"
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.paletteWord = text().trim() || "default"
    }
    FileView {
        path: root.home + "/.dotfiles/palettes/signal.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.palettes = JSON.parse(text()).palettes;
            } catch (e) {}
        }
    }

    // ── The palette's colours — or Flare's parchment ─────────────────
    // The names are Catppuccin Mocha's (DESIGN-BRIEF §4), the default palette;
    // every palette fills the same roles. Flare keeps the NAMES so every Signal
    // file restyles untouched; the values are warm parchment that reads white
    // but isn't (Kanagawa-lotus feel), deep indigo ink, and dark-enough accents
    // (all >= 4:1 on mantle). The roles flip where the hue would fail on paper:
    // the trace is ember, not green (`sigHot`), and peach — Signal's warm second
    // voice — turns cool teal, so it still stands apart from the trace.
    readonly property color crust: flare ? "#e2d4ad" : pc("crust", "#11111b")        // strip fill
    readonly property color mantle: flare ? "#eadfc0" : pc("mantle", "#181825")      // cells, cards
    readonly property color base: flare ? "#f1e8cf" : pc("base", "#1e1e2e")          // windows
    readonly property color surface0: flare ? "#d6c69c" : pc("surface0", "#313244")  // rules, selection
    readonly property color surface1: flare ? "#c6b48a" : pc("surface1", "#45475a")
    readonly property color surface2: flare ? "#a8986f" : pc("surface2", "#585b70")  // "off" / dim
    readonly property color overlay0: flare ? "#857a62" : pc("overlay0", "#6c7086")  // labels
    readonly property color subtext0: flare ? "#5c5445" : pc("subtext0", "#a6adc8")
    readonly property color text: flare ? "#2b2838" : pc("text", "#cdd6f4")          // ink
    readonly property color lavender: flare ? "#3f56a6" : pc("link", "#b4befe")      // indigo; links
    readonly property color mauve: flare ? "#74489a" : "#cba6f7"                       // violet
    readonly property color peach: flare ? "#17706a" : pc("second", "#fab387")       // the second voice (teal in Flare, see above)
    readonly property color green: flare ? "#3d7a2a" : pc("ok", "#a6e3a1")
    readonly property color teal: flare ? "#17706a" : "#94e2d5"
    readonly property color yellow: flare ? "#8a6400" : pc("warn", "#f9e2af")        // ochre; warn
    readonly property color red: flare ? "#b0283c" : pc("alarm", "#f38ba8")          // crimson; alarm
    readonly property color hot: flare ? ember : pc("hot", "#a6e3a1")                // the trace

    // ── The palette's effects ────────────────────────────────────────
    // fx "off" | "glow" | "full"; glow = strength 0..1 (0 when off). The kit
    // reads these: "glow" lights the live parts (ticks, the focused workspace,
    // the clock, traces, hot/alarm readouts, card frames); "full" adds the
    // toast glitch, card scanlines and the neon flicker below. Flare: none.
    readonly property string fx: flare ? "off" : pc("fx", "off")
    readonly property real glow: fx === "off" ? 0 : Number(pc("glow", 0.5))
    readonly property bool fxFull: fx === "full"
    // Neon flicker: every 12–30s the tube stutters for ~300ms. Glowing parts
    // that opt in (the focused workspace, the clock) multiply by `flick`.
    property real flick: 1
    Timer {
        running: root.fxFull
        repeat: true
        interval: 12000
        onTriggered: {
            interval = 12000 + Math.floor(Math.random() * 18000);
            flicker.restart();
        }
    }
    SequentialAnimation {
        id: flicker
        NumberAnimation { target: root; property: "flick"; to: 0.25; duration: 40 }
        NumberAnimation { target: root; property: "flick"; to: 1; duration: 60 }
        PauseAnimation { duration: 70 }
        NumberAnimation { target: root; property: "flick"; to: 0.4; duration: 30 }
        NumberAnimation { target: root; property: "flick"; to: 1; duration: 110 }
    }
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
    readonly property color sigHot: hot                     // the trace colour
    readonly property color sigWarn: yellow
    readonly property color sigAlarm: red
    readonly property int sigStripH: 35           // was 30; +5 on 2026-10-03, Harry's call
    readonly property int sigBarH: 47             // 6 top + 35 strip + 6 air

    // ── Lantern / Harvest: the pixel style (docs/styles/lantern-harvest.md) ──
    // Every colour has one job: pink is YOU (focus, selection, unread), amber
    // is light and time, ok / warn / alarm are the machine, cyan is sound.
    // Three materials: wood frames, paper holds, slots sink into the paper.
    // Harvest is the same place on an autumn afternoon: same names, day values.
    readonly property color lanOutline: harvest ? "#3a2018" : "#1e1216"   // wood: outline
    readonly property color lanWoodDark: harvest ? "#7a4a2c" : "#3a2422"  // … shadow side
    readonly property color lanWood: harvest ? "#9c6236" : "#553226"      // … body
    readonly property color lanWoodSide: harvest ? "#b0713e" : "#6a3e2b"  // … left edge
    readonly property color lanWoodLit: harvest ? "#dba05a" : "#8f5a36"   // … top edge
    readonly property color lanNail: harvest ? "#f7d58c" : "#c99a5b"
    readonly property color lanPaper: harvest ? "#f6e2b3" : "#1a1630"     // paper (ink at night)
    readonly property color lanSunk: harvest ? "#d9b77c" : "#0f0c1e"      // slots, wells
    readonly property color lanRaised: harvest ? "#fff0cc" : "#2c2650"    // the selected row, the clock plaque
    readonly property color lanText: harvest ? "#4a2a1e" : "#f2dcb0"
    readonly property color lanDim: harvest ? "#8a5a3a" : "#9d8cb0"       // icons at rest, secondary words
    readonly property color lanBright: harvest ? "#2a160f" : "#fff0cc"
    readonly property color lanPink: harvest ? "#b8286c" : "#ff5c9d"      // you
    readonly property color lanPinkHi: harvest ? "#f08cb4" : "#ffc2dc"
    readonly property color lanOnPink: harvest ? "#fff0cc" : "#1e1216"
    readonly property color lanAmber: harvest ? "#a8561a" : "#ffb347"     // light, time
    readonly property color lanLamp: harvest ? "#c56a1a" : "#ffd68a"
    readonly property color lanOk: harvest ? "#3f8a2e" : "#7fc45a"
    readonly property color lanOkHi: harvest ? "#7cc45a" : "#b8e986"
    readonly property color lanWarn: harvest ? "#c56a1a" : "#f08a3c"
    readonly property color lanWarnHi: harvest ? "#f0a050" : "#ffc070"
    readonly property color lanAlarm: harvest ? "#a82418" : "#e8423f"
    readonly property color lanAlarmHi: harvest ? "#e8645a" : "#ff8a7a"
    readonly property color lanOnAlarm: "#fff0cc"
    readonly property color lanSound: harvest ? "#2f6fa0" : "#5fd3e0"
    // Type: Jersey 15 at 20px for everything, Jersey 10 at 32px for the clock
    // and titles (30 in the spec; 32 is where its pixels land evenly in Qt).
    // Drawn as hard pixels: native rendering, no antialiasing (Lantern's Text).
    readonly property string lanFont: "Jersey 15"
    readonly property string lanDisplay: "Jersey 10"
    readonly property int lanSize: 20
    readonly property int lanBig: 32
    readonly property int lanBarH: 50             // 2 top + 44 rail + 4 air

    readonly property int barH: style === "lantern" ? lanBarH : sigBarH   // what modules use: where things hang below the bar
    readonly property color desk: style === "lantern" ? lanSunk : crust   // what modules use: behind everything (the lock surface)
    readonly property color accent: style === "lantern" ? lanPink : sigHot  // what modules use: the style's one accent (the wallpaper haze)
}
