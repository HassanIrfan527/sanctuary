pragma Singleton
import QtQuick
import Quickshell

// What KEYS (KeySheet.qml, Mod+/) prints. HAND-WRITTEN on purpose: the words here
// are for reading, not parsed out of binds.kdl — so they drift unless kept in
// step.
//
//   ▶ RULE: every change to niri/niri/binds.kdl updates this file in the same
//     edit (add, remove, rename, move a key). binds.kdl says so at its top.
//
// Families (Mod+1..9, H J K L + arrows) are one row each. Keys are written as
// words in caps — SUPER SHIFT D — and `col` places a section in one of the
// card's three columns (balance by eye: ~22 lines each).
Singleton {
    readonly property var sections: [
        { col: 0, name: "LAUNCH", rows: [
            ["SUPER RETURN", "terminal"],
            ["SUPER SPACE", "launcher"],
            ["SUPER SHIFT SPACE", "launcher · fuzzel fallback"],
            ["SUPER E", "files · yazi"],
            ["SUPER Y", "files · nautilus"],
            ["SUPER B", "browser"]
        ] },
        { col: 0, name: "PANELS", rows: [
            ["SUPER /", "keys · this card"],
            ["SUPER TAB", "overview"],
            ["SUPER `", "column strip"],
            ["SUPER U", "RIG · recorders"],
            ["SUPER C", "COMMS · discord voice"],
            ["SUPER O", "PATCH · audio in / out"],
            ["SUPER ALT M", "mixer · wiremix"],
            ["SUPER V", "clipboard"],
            ["SUPER SHIFT W", "wallpaper"],
            ["SUPER SHIFT T", "style · signal ink paper"],
            ["SUPER SHIFT A", "hide / show the bar"]
        ] },
        { col: 0, name: "NOTIFICATIONS", rows: [
            ["SUPER SHIFT D", "centre"],
            ["SUPER CTRL D", "clear all"],
            ["SUPER ALT D", "do not disturb"]
        ] },

        { col: 1, name: "AUDIO", rows: [
            ["SUPER M", "system mic mute"],
            ["SUPER = / -", "volume up / down"],
            ["SUPER 0", "output mute"],
            ["SUPER SHIFT M", "play / pause"],
            ["SUPER SHIFT ] / [", "next / previous track"]
        ] },
        { col: 1, name: "RECORD", rows: [
            ["SUPER SHIFT R", "meeting · start / stop"],
            ["SUPER ALT R", "practice · mic only"],
            ["CTRL PRINT", "screen · start / stop"],
            ["CTRL ALT PRINT", "screen · pause / resume"]
        ] },
        { col: 1, name: "SCREENSHOT", rows: [
            ["PRINT", "screenshot"],
            ["SHIFT PRINT", "region → swappy"]
        ] },
        { col: 1, name: "NIGHT LIGHT", rows: [
            ["SUPER CTRL -", "warmer"],
            ["SUPER CTRL =", "cooler"],
            ["SUPER CTRL 0", "reset"]
        ] },
        { col: 1, name: "SYSTEM", rows: [
            ["SUPER ESC", "lock"],
            ["SUPER ALT ESC", "lock rescue · swaylock"],
            ["SUPER SHIFT ESC", "power menu"],
            ["SUPER SHIFT S", "keysounds · choose"],
            ["SUPER ALT S", "keysounds · on / off"]
        ] },

        { col: 2, name: "WINDOWS", rows: [
            ["SUPER W", "close"],
            ["SUPER F", "maximize column"],
            ["SUPER SHIFT F", "fullscreen"],
            ["SUPER SHIFT V", "float / tile"],
            ["SUPER ALT C", "centre column"],
            ["SUPER G", "tabbed column"],
            ["SUPER R", "cycle column width"],
            ["SUPER ALT H / L", "width − / +"],
            ["SUPER ALT K / J", "height − / +"]
        ] },
        { col: 2, name: "FOCUS · MOVE", rows: [
            ["SUPER H L  ← →", "focus column"],
            ["SUPER J K  ↓ ↑", "focus window"],
            ["SUPER SHIFT H J K L", "move  · arrows too"],
            ["SUPER CTRL H / L", "into / out of column"],
            ["SUPER CTRL J / K", "move within column"]
        ] },
        { col: 2, name: "COLUMNS · WORKSPACES", rows: [
            ["SUPER 1-9", "focus column N"],
            ["SUPER SHIFT 1-9", "move column to N"],
            ["SUPER P / N", "workspace up / down"],
            ["SUPER SHIFT P / N", "column to workspace ↑ / ↓"]
        ] }
    ]
}
