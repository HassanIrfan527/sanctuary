pragma Singleton
import QtQuick
import Quickshell

// What KEYS (KeySheet.qml, Mod+/) prints. HAND-WRITTEN on purpose: the words here
// are for reading, not parsed out of binds.kdl — so they drift unless kept in
// step.
//
//   ▶ RULE: every change to niri/niri/binds.kdl OR mango/mango/binds.conf
//     updates this file in the same edit (add, remove, rename, move a key).
//     Both bind files say so at their top.
//
// One list for both compositors. A row with a third field only shows there:
// ["SUPER G", "tabbed column", "niri"] / ["SUPER G", "pin to all tags", "mango"].
// Rows without one are the same key doing the same job in both.
//
// Families (Mod+1..9, H J K L + arrows) are one row each. Keys are written as
// words in caps — SUPER SHIFT D — and `col` places a section in one of the
// card's three columns (balance by eye: ~22 lines each).
Singleton {
    readonly property string wm: Wm.isMango ? "mango" : "niri"

    // What KeySheet reads: _all with the other compositor's rows taken out.
    readonly property var sections: _all.map(s => ({
        col: s.col,
        name: s.name,
        rows: s.rows.filter(r => !r[2] || r[2] === wm)
    })).filter(s => s.rows.length)

    readonly property var _all: [
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
            ["SUPER .", "jump · type a window's letter", "mango"],
            ["SUPER `", "column strip"],
            ["SUPER U", "RIG · recorders"],
            ["SUPER C", "COMMS · discord voice"],
            ["SUPER O", "PATCH · audio in / out"],
            ["SUPER ALT M", "mixer · wiremix"],
            ["SUPER V", "clipboard"],
            ["SUPER SHIFT W", "wallpaper"],
            ["SUPER SHIFT T", "style · signal ink paper flare"],
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
        { col: 1, name: "WHEEL · MOUSE", rows: [
            ["SUPER WHEEL", "workspace up / down"],
            ["SUPER SHIFT WHEEL", "window left / right"],
            ["SUPER DRAG", "move window"],
            ["SUPER RIGHT DRAG", "resize window"]
        ] },

        { col: 2, name: "WINDOWS", rows: [
            ["SUPER W", "close"],
            ["SUPER F", "maximize column", "niri"],
            ["SUPER F", "maximize window · again to restore", "mango"],
            ["SUPER SHIFT F", "fullscreen"],
            ["SUPER SHIFT V", "float / tile"],
            ["SUPER ALT C", "centre column"],
            ["SUPER G", "tabbed column", "niri"],
            ["SUPER G", "pin to all tags", "mango"],
            ["SUPER BACKSPACE", "last window", "mango"],
            ["ALT TAB", "switch window · this tag", "mango"],
            ["SUPER ALT SPACE", "cycle layout · this tag", "mango"],
            ["SUPER CTRL SPACE", "layout picker · all 14", "mango"],
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
            ["SUPER SHIFT 1-9", "move column to N", "niri"],
            ["SUPER SHIFT 1-9", "send window to tag N · follow", "mango"],
            ["SUPER P / N", "workspace up / down"],
            ["SUPER SHIFT P / N", "column to workspace ↑ / ↓"]
        ] }
    ]
}
