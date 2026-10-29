.pragma library
// Lantern only: Jersey has no ● ▸ ▶ ‖ arrows ✕ …, and Qt would borrow them
// from a smooth system font — a soft blob in a pixel world. Every part that
// prints a module's text passes it through plain(), which swaps each one for
// a character Jersey draws (• › ‹ < > ^ v x …). Icons are the Icon part's job.
var map = {
    "●": "•", "○": "°", "■": "•", "□": "°", "◆": "•", "◉": "•", "◎": "•",
    "▸": "›", "▶": "›", "◀": "‹", "◂": "‹", "▾": "v", "▴": "^",
    "‖": "||", "▲": "!", "△": "!",
    "←": "<", "→": ">", "↑": "^", "↓": "v", "⇄": "<>", "↔": "<>", "↗": ">",
    "✕": "x", "✓": "ok", "⌫": "bksp", "⏎": "enter", "⌥": "alt", "⇧": "shift",
    "─": "-", "│": "|", "▌": "|", "−": "-"
};
var re = new RegExp("[" + Object.keys(map).join("") + "]", "g");
function plain(s) {
    s = s === undefined || s === null ? "" : String(s);
    return s.replace(re, function (c) { return map[c]; });
}
