import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

// The launcher — Mod+Space (scripts/sanctuary/launcher.sh). Drawn in the
// current style; when Quickshell is down (fallback) the same key opens fsel.
//
// Five modes. Type a prefix as the FIRST character to switch (it is eaten, the
// mode shows as a tab); tab / shift-tab cycles; backspace on an empty field goes
// back to apps.
//
//   APPS        the default. Apps you haven't pinned, plus desk actions that
//               match ("lock", "audio"), plus a calculator row when what you
//               typed is a sum ("2*21"). ctrl-s pins the app under the cursor —
//               it moves to PINNED and leaves this list.
//   *  PINNED   your pinned apps, then your pinned files and folders — only
//               those. enter opens (a file: its default app) · shift-enter on a
//               file opens the folder it is in (a folder: a kitty there) · ctrl-s
//               unpins. Type a path (~/… or /…) and enter to pin that file or
//               folder; or Nautilus (right-click → Scripts → Pin to launcher),
//               or `files.py pin <path>`.
//   =  CALC     a sum: + - * / % ^ ( ), sqrt sin cos tan log ln abs round floor
//               ceil min max pow exp pi e. enter copies the answer (wl-copy).
//   :  DESK     this desk's own actions: audio in/out, recorders, wallpaper,
//               comms, style, power, lock, notifications, DND, night light, keybinds…
//   ?  WEB      search DuckDuckGo / YouTube / GitHub / Wikipedia, or open a URL.
//
// Pinned apps: ~/.local/state/sanctuary/pinned-apps.json (desktop ids, in your
// order). Pinned files: pins.json beside it (scripts/sanctuary/files.py).
//
// App ranking: name starts with the query > a word in the name starts with it >
// a word in the generic name / keywords starts with it > anywhere in the name >
// anywhere in generic name / keywords > comment > letters in order. Apps you
// launch often float up (counts in ~/.local/state/sanctuary/launches.json).
//
//   enter  go     ↑ ↓ · ctrl-j ctrl-k · ctrl-n ctrl-p  move     tab  mode     esc  close
//   ctrl-s  pin the app under the cursor (APPS) · unpin it (PINNED)
//   click a row to run it; click a tab to switch; click outside to close
PanelWindow {
    id: win

    visible: Ui.launcherOpen
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "sanctuary-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string query: ""
    property string mode: "apps"
    property int cursor: 0
    readonly property int rows: Theme.signal ? 13 : 9
    // First result shown: the list scrolls so the cursor is always on screen.
    property int top: 0
    onCursorChanged: {
        if (cursor < top)
            top = cursor;
        else if (cursor >= top + rows)
            top = cursor - rows + 1;
    }

    // ── modes ─────────────────────────────────────────────────────────
    readonly property var modes: [
        { id: "apps",   pre: "",  name: "APPS",   hint: "enter launch · ctrl-s pin" },
        { id: "pinned", pre: "*", name: "PINNED", hint: "enter open · shift-enter its folder · ctrl-s unpin" },
        { id: "calc",   pre: "=", name: "CALC",   hint: "enter copy" },
        { id: "desk",   pre: ":", name: "DESK",   hint: "enter do it" },
        { id: "web",    pre: "?", name: "WEB",    hint: "enter open in browser" }
    ]
    readonly property var modeNow: modes.find(m => m.id === mode) || modes[0]
    function modeFor(ch) {
        return modes.find(m => m.pre !== "" && m.pre === ch);
    }
    function setMode(id) {
        mode = id;
        cursor = 0;
    }
    function cycle(step) {
        const i = modes.findIndex(m => m.id === mode);
        setMode(modes[(i + step + modes.length) % modes.length].id);
    }
    function field() {
        return Theme.signal ? sigInput : inkInput;
    }
    // Both inputs feed this. A prefix typed into an empty APPS field switches
    // the mode and is removed again.
    function edited(t) {
        if (mode === "apps" && t.length > 0) {
            const m = modeFor(t[0]);
            if (m) {
                setMode(m.id);
                field().text = t.slice(1);
                return;
            }
        }
        query = t;
    }

    // Every visible app, once. noDisplay entries are hidden by their own choice.
    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay)
    // APPS lists only what isn't pinned; PINNED has the rest, in your order
    // (an id whose app is gone is skipped, and kept in the file).
    readonly property var mainApps: apps.filter(a => pinnedIds.indexOf(a.id) < 0)
    readonly property var pinnedApps: pinnedIds.map(id => apps.find(a => a.id === id)).filter(a => !!a)
    readonly property var results: collect(mode, query)

    onVisibleChanged: {
        if (visible) {
            // Clear the fields themselves: a `text: query` binding would break
            // the moment you type, and the old query would come back next time.
            mode = "apps";
            sigInput.text = "";
            inkInput.text = "";
            cursor = 0;
            uptimeFile.reload();
            pinnedAppsFile.reload();
            filesProc.running = true;
            Qt.callLater(() => field().forceActiveFocus());
        }
    }
    onQueryChanged: {
        cursor = 0;
        scope.kick();
    }
    onModeChanged: scope.kick()

    // ── state files ───────────────────────────────────────────────────
    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/sanctuary"
    property var counts: ({})
    FileView {
        id: countsFile
        path: win.stateDir + "/launches.json"
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                win.counts = JSON.parse(countsFile.text()) || {};
            } catch (e) {
                win.counts = {};
            }
        }
    }
    function bump(id) {
        const c = Object.assign({}, counts);
        c[id] = (c[id] || 0) + 1;
        counts = c;
        countsFile.setText(JSON.stringify(c));
    }

    // Pinned apps: desktop ids.
    property var pinnedIds: []
    FileView {
        id: pinnedAppsFile
        path: win.stateDir + "/pinned-apps.json"
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                const p = JSON.parse(pinnedAppsFile.text());
                win.pinnedIds = Array.isArray(p) ? p.filter(x => typeof x === "string") : [];
            } catch (e) {
                win.pinnedIds = [];
            }
        }
    }
    function setPinnedIds(ids) {
        pinnedIds = ids;
        pinnedAppsFile.setText(JSON.stringify(ids, null, 1));
    }
    // ctrl-s: pin an app (APPS), unpin an app or a file (PINNED). The row
    // leaves the list it is in, so keep the cursor inside what is left.
    function togglePin(r) {
        if (!r)
            return;
        if (r.kind === "app" && !r.pinned)
            setPinnedIds(pinnedIds.concat([r.entry.id]));
        else if (r.kind === "app")
            setPinnedIds(pinnedIds.filter(id => id !== r.entry.id));
        else if (r.kind === "file")
            unpin(r);
        else
            return;
        Qt.callLater(() => cursor = Math.max(0, Math.min(cursor, results.length - 1)));
    }

    // Pinned files / folders, from scripts/sanctuary/files.py (re-read on
    // open and after a pin / unpin).
    property var pins: []
    Process {
        id: filesProc
        command: [win.scripts + "/files.py"]
        stdout: StdioCollector {
            id: filesOut
            onStreamFinished: {
                try {
                    const d = JSON.parse(filesOut.text);
                    win.pins = d.pins || [];
                } catch (e) {}
            }
        }
    }
    function unpin(r) {
        if (!r || r.kind !== "file")
            return;
        pinsFile.setText(JSON.stringify(pins.map(p => p.path).filter(p => p !== r.file.path), null, 1));
        filesProc.running = true;   // after the write: setText is synchronous
    }
    FileView {
        id: pinsFile
        path: win.stateDir + "/pins.json"
        printErrors: false
    }
    // Pin a path typed into PINNED. files.py does the ~ and the checking; the
    // launcher stays open so you see it land.
    Process {
        id: pinProc
        onExited: filesProc.running = true
    }
    function pinPath(p) {
        pinProc.command = [scripts + "/files.py", "pin", p];
        pinProc.running = true;
        field().text = "";
    }

    // Header readouts.
    property string uptime: ""
    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        printErrors: false
        onLoaded: {
            const s = Math.floor(parseFloat(uptimeFile.text()));
            const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
            win.uptime = (d > 0 ? d + "D " : "") + h + "H " + Theme.pad(m, 2, "0") + "M";
        }
    }
    property string host: ""
    FileView {
        id: hostFile
        path: "/etc/hostname"
        printErrors: false
        onLoaded: win.host = hostFile.text().trim()
    }
    property date now: new Date()
    Timer {
        running: win.visible
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: win.now = new Date()
    }

    // ── desk actions (DESK mode, and mixed into APPS when they match) ──
    // `do` is the verb doDesk() dispatches on. Keywords are what you might type.
    readonly property string scripts: Quickshell.env("HOME") + "/.dotfiles/scripts/sanctuary"
    readonly property var desk: [
        { do: "patch",   glyph: "⇄", name: "Audio in / out",     desc: "PATCH — speakers, headphones, mic · Mod+O", keywords: ["sound", "output", "input", "headphones", "speaker", "mic", "microphone", "bluetooth", "patch", "switch"] },
        { do: "mixer",   glyph: "≋", name: "Mixer",              desc: "wiremix — every stream · Mod+Alt+M",        keywords: ["volume", "sound", "wiremix", "audio"] },
        { do: "rig",     glyph: "◉", name: "Recorders",          desc: "RIG — screen, meeting, practice · Mod+U",   keywords: ["record", "rec", "rig", "meeting", "audio"] },
        { do: "comms",   glyph: "◎", name: "Comms",              desc: "Discord voice — mute, deafen, leave · Mod+C", keywords: ["discord", "vesktop", "voice", "call", "vc", "comms", "mute", "deafen", "leave"] },
        { do: "capture", glyph: "▣", name: "Record screen",      desc: "drag a region · Ctrl+Print",                keywords: ["record", "screen", "video", "capture"] },
        { do: "shot",    glyph: "⌗", name: "Screenshot",         desc: "Print",                                     keywords: ["screenshot", "capture", "grim"] },
        { do: "clip",    glyph: "⎘", name: "Clipboard",          desc: "history · Mod+V",                           keywords: ["clipboard", "paste", "copy", "history"] },
        { do: "wall",    glyph: "▤", name: "Wallpaper",          desc: "stills and live · Mod+Shift+W",             keywords: ["wallpaper", "background"] },
        { do: "style",   glyph: "◐", name: "Style",              desc: "Signal · Ink · Paper · Mod+Shift+T",        keywords: ["theme", "style", "signal", "ink", "paper", "look"] },
        { do: "notifs",  glyph: "☰", name: "Notifications",      desc: "the centre · Mod+Shift+D",                  keywords: ["notifications", "centre", "center"] },
        { do: "dnd",     glyph: "◌", name: "Do not disturb",     desc: "toggle · Mod+Alt+D",                        keywords: ["dnd", "quiet", "silence", "notifications"] },
        { do: "warmer",  glyph: "☾", name: "Night light warmer", desc: "less blue",                                 keywords: ["night", "light", "warm", "gamma", "blue"] },
        { do: "cooler",  glyph: "☼", name: "Night light cooler", desc: "more blue",                                 keywords: ["night", "light", "cool", "gamma"] },
        { do: "nlreset", glyph: "○", name: "Night light off",    desc: "back to 6500K",                             keywords: ["night", "light", "reset", "off", "gamma"] },
        { do: "bar",     glyph: "▔", name: "Hide / show bar",    desc: "Mod+Shift+A",                               keywords: ["bar", "panel", "hide", "show"] },
        { do: "keys",    glyph: "⌨", name: "Keybinds",           desc: "KEYS cheat sheet · Mod+/",                    keywords: ["keys", "keybinds", "shortcuts", "hotkeys", "help"] },
        { do: "power",   glyph: "⏻", name: "Power menu",         desc: "Mod+Shift+Escape",                          keywords: ["power", "shutdown", "reboot", "logout"] },
        { do: "lock",    glyph: "⊘", name: "Lock",               desc: "Mod+Escape",                                keywords: ["lock", "away"] },
        { do: "suspend", glyph: "z", name: "Suspend",            desc: "sleep now",                                 keywords: ["suspend", "sleep"] }
    ]

    // ── ranking ───────────────────────────────────────────────────────
    function subsequence(hay, needle) {
        let i = 0;
        for (let j = 0; j < hay.length && i < needle.length; j++)
            if (hay[j] === needle[i])
                i++;
        return i === needle.length;
    }
    // Works on apps (DesktopEntry) and desk actions alike: both have a name,
    // keywords, and a description (genericName / desc).
    function score(a, q) {
        const name = a.name.toLowerCase();
        const generic = (a.genericName || a.desc || "").toLowerCase();
        const kw = a.keywords || [];
        let s = 0;
        if (name.startsWith(q))
            s = 100;
        else if (name.split(/[\s\-_.\/]+/).some(w => w.startsWith(q)))
            s = 80;
        // A word in the description starting with the query ("te" → Terminal,
        // Text Editor) says more about intent than letters buried mid-name
        // ("te" → Bluetooth Adap-te-rs), so it outranks a plain substring.
        else if (generic.split(/[\s\-_.]+/).some(w => w.startsWith(q))
                 || kw.some(k => k.toLowerCase().startsWith(q)))
            s = 65;
        else if (name.indexOf(q) >= 0)
            s = 60;
        else if (generic.indexOf(q) >= 0 || kw.some(k => k.toLowerCase().indexOf(q) >= 0))
            s = 40;
        else if ((a.comment || "").toLowerCase().indexOf(q) >= 0)
            s = 25;
        else if (subsequence(name, q))
            s = 15;
        if (s === 0)
            return 0;
        return s + Math.log((counts[a.id] || 0) + 1) * 8;
    }

    // A row, whatever the mode: kind (app / desk / file / pinpath / calc / web / hint),
    // title, sub, tag (right-hand readout), plus what launch() needs.
    function appRow(a) {
        const n = counts[a.id] || 0;
        return { kind: "app", title: a.name, sub: a.genericName || a.comment || "", tag: n > 0 ? n + "×" : "", entry: a, icon: a.icon, glyph: "" };
    }
    function pinnedAppRow(a) {
        return Object.assign(appRow(a), { tag: "PIN", pinned: true });
    }
    function deskRow(d) {
        return { kind: "desk", title: d.name, sub: d.desc, tag: "DESK", act: d.do, icon: "", glyph: d.glyph };
    }
    // A file or folder. `where` is its folder, with ~ for home.
    function fileRow(f) {
        return {
            kind: "file", title: f.name + (f.dir ? "/" : ""),
            sub: f.gone ? "gone — ctrl-s to unpin" : f.where,
            tag: f.dir ? "DIR" : (f.ext || "FILE").toUpperCase().slice(0, 4),
            file: f, pinned: true, icon: f.icon, mimeicon: f.mimeicon, generic: f.generic, glyph: "◆"
        };
    }
    // Files rank on the name (and the folder it is in, a bit lower).
    function fileScore(f, q) {
        return score({ name: f.name, desc: f.where.replace(/[~\/]+/g, " "), keywords: [] }, q);
    }
    // PINNED: apps first, then files, each in your order. A path typed here
    // (~/… or /…) offers to pin it.
    function pinnedRows(raw) {
        const p = raw.trim();
        if (/^[~\/]/.test(p))
            return [{ kind: "pinpath", title: p, sub: "enter pins this file or folder", tag: "PIN", path: p, icon: "", glyph: "+" }];
        const q = p.toLowerCase();
        const all = pinnedApps.map(pinnedAppRow).concat(pins.map(fileRow));
        if (all.length === 0)
            return [hint("nothing pinned", "APPS: ctrl-s pins an app · here: type ~/path and enter · Nautilus: Scripts → Pin to launcher")];
        if (q === "")
            return all;
        // a tie keeps your order
        return pinnedApps.map(a => ({ r: pinnedAppRow(a), s: score(a, q) }))
                   .concat(pins.map(f => ({ r: fileRow(f), s: fileScore(f, q) })))
                   .map((x, i) => Object.assign(x, { i: i }))
                   .filter(x => x.s > 0).sort((x, y) => (y.s - x.s) || (x.i - y.i)).map(x => x.r);
    }
    function hint(t, s) {
        return { kind: "hint", title: t, sub: s || "", tag: "", icon: "", glyph: "·" };
    }

    function collect(m, raw) {
        const q = raw.trim().toLowerCase();
        if (m === "calc")
            return calcRows(raw.trim(), true);
        if (m === "web")
            return webRows(raw.trim());
        if (m === "pinned")
            return pinnedRows(raw);
        if (m === "desk") {
            if (q === "")
                return desk.map(deskRow);
            return desk.map(d => ({ d: d, s: score(d, q) })).filter(x => x.s > 0)
                       .sort((x, y) => y.s - x.s).map(x => deskRow(x.d));
        }
        // apps — the ones not pinned (those live in PINNED), by use
        if (q === "")
            return mainApps.slice().sort((a, b) => ((counts[b.id] || 0) - (counts[a.id] || 0))
                                         || a.name.localeCompare(b.name)).map(appRow);
        // Desk actions join in only on a real word match (≥ 60), so typing
        // "f" doesn't bury Firefox under "Suspend". -1: an app wins a tie.
        const ranked = mainApps.map(a => ({ r: appRow(a), s: score(a, q) }))
            .concat(desk.map(d => ({ r: deskRow(d), s: score(d, q) - 1 })).filter(x => x.s >= 59))
            .filter(x => x.s > 0)
            .sort((x, y) => (y.s - x.s) || x.r.title.localeCompare(y.r.title))
            .map(x => x.r);
        // Looks like a sum? The answer goes on top.
        if (/[0-9]/.test(q) && /[-+*\/%^(]/.test(q))
            return calcRows(raw.trim(), false).concat(ranked);
        return ranked;
    }

    // ── CALC ──────────────────────────────────────────────────────────
    // Only numbers, operators and a short list of names get through to the
    // evaluator, so nothing typed here can call anything else.
    readonly property var calcNames: ({
        sqrt: "Math.sqrt", sin: "Math.sin", cos: "Math.cos", tan: "Math.tan",
        asin: "Math.asin", acos: "Math.acos", atan: "Math.atan",
        log: "Math.log10", ln: "Math.log", log2: "Math.log2", exp: "Math.exp",
        abs: "Math.abs", round: "Math.round", floor: "Math.floor", ceil: "Math.ceil",
        min: "Math.min", max: "Math.max", pow: "Math.pow", pi: "Math.PI", e: "Math.E"
    })
    function evaluate(expr) {
        const tok = /\s*(?:(\d+\.?\d*(?:e[+-]?\d+)?|\.\d+)|([a-z_][a-z0-9_]*)|(\*\*|[-+*\/%^(),]))/gi;
        let out = "", pos = 0, m;
        while ((m = tok.exec(expr)) !== null) {
            if (m.index !== pos)
                return null;
            pos = tok.lastIndex;
            if (m[1] !== undefined)
                out += m[1];
            else if (m[2] !== undefined) {
                const f = calcNames[m[2].toLowerCase()];
                if (!f)
                    return null;
                out += f;
            } else
                out += m[3] === "^" ? "**" : m[3];
        }
        if (expr.slice(pos).trim() !== "" || out === "")
            return null;
        try {
            const v = Function("return (" + out + ");")();
            return typeof v === "number" && isFinite(v) ? v : null;
        } catch (e) {
            return null;
        }
    }
    function fmt(v) {
        if (Number.isInteger(v))
            return String(v);
        return String(parseFloat(v.toPrecision(12)));
    }
    function calcRows(expr, explicit) {
        if (expr === "")
            return [hint("type a sum", "2^10 · sqrt(2) · (1200*12)/52 · 15*0.2 · ln(e)")];
        const v = evaluate(expr);
        if (v === null)
            return explicit ? [hint("…", "not a sum yet")] : [];
        const s = fmt(v);
        let sub = expr + " =";
        if (Number.isInteger(v) && v >= 0 && v < 2147483648)
            sub += "  · 0x" + v.toString(16).toUpperCase() + " · 0b" + v.toString(2);
        return [{ kind: "calc", title: s, sub: sub, tag: "COPY", value: s, icon: "", glyph: "=" }];
    }

    // ── WEB ───────────────────────────────────────────────────────────
    readonly property var engines: [
        { name: "DuckDuckGo", url: "https://duckduckgo.com/?q=", glyph: "◎" },
        { name: "YouTube",    url: "https://www.youtube.com/results?search_query=", glyph: "▶" },
        { name: "GitHub",     url: "https://github.com/search?q=", glyph: "⌥" },
        { name: "Wikipedia",  url: "https://en.wikipedia.org/w/index.php?search=", glyph: "W" }
    ]
    function webRows(q) {
        if (q === "")
            return [hint("type a search", "DuckDuckGo · YouTube · GitHub · Wikipedia — or a URL")];
        const r = [];
        // "example.com/x" or "https://…": no spaces, a dot, not starting with one.
        if (/^(https?:\/\/)?[^\s.\/]+\.[^\s]+$/.test(q))
            r.push({ kind: "web", title: q, sub: "open", tag: "URL", url: /^https?:\/\//.test(q) ? q : "https://" + q, icon: "", glyph: "↗" });
        for (const e of engines)
            r.push({ kind: "web", title: q, sub: e.name, tag: e.name.slice(0, 3).toUpperCase(), url: e.url + encodeURIComponent(q), icon: "", glyph: e.glyph });
        return r;
    }

    // ── go ────────────────────────────────────────────────────────────
    function sh(args) {
        Quickshell.execDetached(args);
    }
    function doDesk(v) {
        if (v === "patch") Ui.patchOpen = true;
        else if (v === "mixer") Media.openMixer();
        else if (v === "rig") Ui.rigOpen = true;
        else if (v === "comms") Ui.commsOpen = true;
        else if (v === "capture") Ui.captureOpen = true;
        // a beat first, so the launcher is gone from the picture
        else if (v === "shot") sh(["bash", "-c", "sleep 0.3; ~/.dotfiles/scripts/screenshot.sh"]);
        else if (v === "clip") sh(["kitty", "--class", "sanctuary-clipboard", "-e", scripts + "/clipboard.sh"]);
        else if (v === "wall") Ui.wallOpen = true;
        else if (v === "style") Ui.pickerOpen = true;
        else if (v === "notifs") Ui.centreOpen = true;
        else if (v === "dnd") sh([scripts + "/qs.sh", "call", "notifs", "dnd"]);
        else if (v === "warmer") sh([scripts + "/nightlight.sh", "warmer"]);
        else if (v === "cooler") sh([scripts + "/nightlight.sh", "cooler"]);
        else if (v === "nlreset") sh([scripts + "/nightlight.sh", "reset"]);
        else if (v === "bar") Ui.barShown = !Ui.barShown;
        else if (v === "keys") Ui.keysOpen = true;
        else if (v === "power") Ui.powerOpen = true;
        else if (v === "lock") sh(["loginctl", "lock-session"]);
        else if (v === "suspend") sh([scripts + "/power.sh", "do", "suspend"]);
    }
    function launch(i, shift) {
        const r = results[i];
        if (!r || r.kind === "hint" || (r.kind === "file" && r.file.gone))
            return;
        if (r.kind === "pinpath") {
            pinPath(r.path);
            return;
        }
        Ui.launcherOpen = false;   // first: the next overlay wants the keyboard
        if (r.kind === "app") {
            bump(r.entry.id);
            if (r.entry.runInTerminal)
                sh(["kitty", "-e"].concat(r.entry.command));
            else
                r.entry.execute();
        } else if (r.kind === "desk") {
            doDesk(r.act);
        } else if (r.kind === "calc") {
            sh(["wl-copy", r.value]);
        } else if (r.kind === "web") {
            sh(["xdg-open", r.url]);
        } else if (r.kind === "file") {
            // shift: the folder it is in (a folder: a terminal there)
            if (!shift)
                sh(["xdg-open", r.file.path]);
            else if (r.file.dir)
                sh(["kitty", "--directory", r.file.path]);
            else
                sh(["xdg-open", r.file.path.replace(/\/[^\/]*$/, "") || "/"]);
        }
    }

    // Test hooks (IPC `debug launcherType` / `launcherEnter`): drive it without
    // a keyboard. Prefixes work here too: `launcherType "=2^10"`.
    function typeText(t) {
        mode = "apps";
        field().text = t;
    }
    function enter() { launch(cursor, false); }
    Connections {
        target: Ui
        function onLauncherType(t) { win.typeText(t); }
        function onLauncherEnter() { win.enter(); }
    }

    function key(event) {
        const k = event.key, ctrl = event.modifiers & Qt.ControlModifier;
        const n = results.length;
        if (k === Qt.Key_Escape) {
            Ui.launcherOpen = false;
        } else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
            launch(cursor, event.modifiers & Qt.ShiftModifier);
        } else if (k === Qt.Key_Tab) {
            cycle(1);
        } else if (k === Qt.Key_Backtab) {
            cycle(-1);
        } else if (k === Qt.Key_Backspace && field().text === "" && mode !== "apps") {
            setMode("apps");
        } else if (ctrl && k === Qt.Key_S) {
            togglePin(results[cursor]);
        } else if (k === Qt.Key_Down || (ctrl && (k === Qt.Key_J || k === Qt.Key_N))) {
            if (n > 0)
                cursor = (cursor + 1) % n;
        } else if (k === Qt.Key_Up || (ctrl && (k === Qt.Key_K || k === Qt.Key_P))) {
            if (n > 0)
                cursor = (cursor + n - 1) % n;
        } else {
            return;
        }
        event.accepted = true;
    }

    MouseArea {   // scrim: click outside = close
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: Ui.launcherOpen = false
    }

    // The trace in the masthead: a slow carrier wave that jumps when you type
    // (kick) and settles back. Painted only while the launcher is open.
    QtObject {
        id: scope
        property real phase: 0
        property real energy: 0.35
        function kick() { energy = Math.min(1.6, energy + 0.55); }
    }
    Timer {
        running: win.visible && Theme.signal
        interval: 33
        repeat: true
        onTriggered: {
            scope.phase += 0.12;
            scope.energy = Math.max(0.18, scope.energy * 0.94);
            traceCanvas.requestPaint();
        }
    }

    // ══ Signal: a console on an instrument ═══════════════════════════
    //
    //   ┌────────────────────────────────────────────────────────────┐
    //   │ SIGNAL  ∿∿∿∿∿∿∿ live trace ∿∿∿∿∿∿∿              19:06    │  ← masthead
    //   │ SANCTUARY // CONSOLE                CITADEL · UP 3H 12M   │
    //   ├────────────────────────────────────────────────────────────┤
    //   │ APPS   * PINNED   = CALC   : DESK   ? WEB   50 APPS · 18 DESK │  ← mode tabs
    //   │ ▸ fir▌                                                     │
    //   ├────────────────────────────────────────────────────────────┤
    //   │▌01  Firefox        Web Browser                       12×   │
    //   │ enter launch · tab mode · ctrl-j/k move · esc     01/03    │
    //   └────────────────────────────────────────────────────────────┘
    Rectangle {
        id: sig
        visible: Theme.signal
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.14)
        width: 680
        height: sigCol.implicitHeight
        color: Theme.sigFill
        border.width: 1
        border.color: Theme.sigRule

        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }   // swallow

        SignalTicks {
            anchors.fill: parent
            anchors.margins: -3
        }

        Column {
            id: sigCol
            width: parent.width

            // ── masthead ──
            Item {
                width: parent.width
                height: 78
                clip: true

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
                        const mid = height / 2, w = width, ph = scope.phase, en = scope.energy;
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
                        text: Theme.word.toUpperCase()
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
                    text: "SANCTUARY // CONSOLE"
                    font.family: Theme.mono
                    font.pixelSize: 9
                    font.letterSpacing: 2
                    color: Theme.sigLabel
                }

                // clock + host
                Column {
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    y: 16
                    spacing: 5
                    Text {
                        anchors.right: parent.right
                        text: Qt.formatTime(win.now, "HH:mm")
                        font.family: Theme.mono
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        color: Theme.sigValue
                    }
                    Text {
                        anchors.right: parent.right
                        text: (win.host ? win.host.toUpperCase() + " · " : "") + "UP " + win.uptime
                        font.family: Theme.mono
                        font.pixelSize: 9
                        font.letterSpacing: 1.2
                        color: Theme.sigLabel
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.sigRule }

            // ── mode tabs ──
            Item {
                width: parent.width
                height: 30
                Row {
                    x: 8
                    height: parent.height
                    Repeater {
                        model: win.modes
                        delegate: Item {
                            id: tab
                            required property var modelData
                            readonly property bool on: modelData.id === win.mode
                            width: tabText.implicitWidth + 20
                            height: parent.height
                            Text {
                                id: tabText
                                anchors.centerIn: parent
                                text: (tab.modelData.pre ? tab.modelData.pre + " " : "") + tab.modelData.name
                                font.family: Theme.mono
                                font.pixelSize: 10
                                font.weight: tab.on ? Font.Bold : Font.Normal
                                font.letterSpacing: 1.4
                                color: tab.on ? Theme.sigHot : Theme.sigLabel
                            }
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width - 8
                                height: 2
                                color: Theme.sigHot
                                visible: tab.on
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    win.setMode(tab.modelData.id);
                                    win.field().forceActiveFocus();
                                }
                            }
                        }
                    }
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.mainApps.length + " APPS · " + win.desk.length + " DESK · " + (win.pinnedApps.length + win.pins.length) + " PIN"
                    font.family: Theme.mono
                    font.pixelSize: 9
                    font.letterSpacing: 1.4
                    color: Theme.surface2
                }
            }

            // ── prompt ──
            Rectangle {
                width: parent.width
                height: 42
                color: Theme.sigCell
                Text {
                    id: chev
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.modeNow.pre || "▸"
                    font.family: Theme.mono
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: Theme.sigHot
                }
                TextInput {
                    id: sigInput
                    anchors.left: chev.right
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    onTextChanged: win.edited(text)
                    font.family: Theme.mono
                    font.pixelSize: 15
                    color: Theme.sigValue
                    selectionColor: Theme.surface1
                    cursorDelegate: Rectangle { width: 8; color: Theme.sigHot; opacity: 0.8 }
                    Keys.onPressed: event => win.key(event)
                }
                Text {
                    anchors.left: chev.right
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    visible: sigInput.text === ""
                    text: win.mode === "apps" ? "type to find · *  =  :  ?  for the other modes"
                        : win.mode === "calc" ? "a sum"
                        : win.mode === "desk" ? "a desk action"
                        : win.mode === "pinned" ? "a pinned app or file · or ~/path to pin one"
                        : "search the web"
                    font.family: Theme.mono
                    font.pixelSize: 12
                    color: Theme.surface2
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.sigRule }

            // ── rows ──
            Repeater {
                model: Theme.signal ? win.results.slice(win.top, win.top + win.rows) : []
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool sel: win.top + index === win.cursor && modelData.kind !== "hint"
                    readonly property bool big: modelData.kind === "calc"
                    width: sigCol.width
                    height: big ? 40 : 30
                    color: sel ? Theme.sigCell : "transparent"

                    Rectangle {
                        width: 2
                        height: parent.height
                        color: Theme.sigHot
                        visible: row.sel
                    }
                    Row {
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 14
                        Text {
                            width: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.kind === "app" ? Theme.pad(win.top + row.index + 1, 2, "0") : row.modelData.glyph
                            font.family: Theme.mono
                            font.pixelSize: row.modelData.kind === "app" ? 10 : 12
                            color: row.modelData.kind === "app" ? Theme.surface2 : row.sel ? Theme.sigHot : Theme.sigLabel
                        }
                        Text {
                            width: row.big ? 300 : 230
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            text: row.modelData.title
                            font.family: Theme.mono
                            font.pixelSize: row.big ? 20 : 12
                            font.weight: row.sel || row.big ? Font.Bold : Font.Normal
                            color: row.modelData.kind === "hint" ? Theme.sigLabel : row.sel || row.big ? Theme.sigHot : Theme.sigValue
                        }
                        Text {
                            width: row.big ? 230 : 300
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            text: row.modelData.sub
                            font.family: Theme.mono
                            font.pixelSize: 10
                            color: Theme.sigLabel
                        }
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.tag
                        font.family: Theme.mono
                        font.pixelSize: 9
                        font.letterSpacing: row.modelData.kind === "app" ? 0 : 1.2
                        color: row.modelData.kind === "desk" || row.modelData.kind === "calc" || row.modelData.pinned ? Theme.sigHot : Theme.surface2
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: row.modelData.kind === "hint" ? Qt.ArrowCursor : Qt.PointingHandCursor
                        onEntered: win.cursor = win.top + row.index
                        onClicked: mouse => win.launch(win.top + row.index, mouse.modifiers & Qt.ShiftModifier)
                    }
                }
            }

            // nothing matched: say so, once, quietly
            Item {
                visible: win.results.length === 0
                width: parent.width
                height: 30
                Text {
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: "no match · tab for another mode"
                    font.family: Theme.mono
                    font.pixelSize: 11
                    color: Theme.surface2
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.sigRule }

            // ── footer ──
            Item {
                width: parent.width
                height: 28
                Text {
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.modeNow.hint + " · tab mode · ctrl-j/k move · esc close"
                    font.family: Theme.mono
                    font.pixelSize: 9
                    color: Theme.surface2
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.pad(win.results.length ? win.cursor + 1 : 0, 2, "0") + "/"
                          + Theme.pad(win.results.length, 2, "0")
                    font.family: Theme.mono
                    font.pixelSize: 9
                    color: Theme.sigLabel
                }
            }
        }
    }

    // ══ Ink / Paper: a manga page ════════════════════════════════════
    //
    //   ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    //   ┃ INK!                       ░░▒▒▓▓ 19:06 ┃  ← the style, lettered, offset-printed
    //   ┃ [APPS] [* PINNED] [= CALC] [: DESK] [? WEB] ┃  ← mode chips
    //   ┃   ╭────────────────────────────╮       ┃
    //   ┃   │ fir▌                       │       ┃  ← the query in a speech bubble
    //   ┃   ╰──╲─────────────────────────╯       ┃
    //   ┃ ┌──┐ FIREFOX   web browser           ▉┃  ← selected: hard peach shadow
    //   ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
    Item {
        id: ink
        visible: Theme.ink
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.12)
        width: 580
        height: inkCol.implicitHeight + 40

        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }   // swallow

        Rectangle {   // hard shadow
            x: 7
            y: 7
            width: parent.width
            height: parent.height
            color: Theme.mauve
        }
        Rectangle {
            anchors.fill: parent
            color: Theme.paper
            border.width: Theme.inkStroke
            border.color: Theme.inkLine
        }

        Column {
            id: inkCol
            x: 22
            y: 18
            width: parent.width - 44
            spacing: 12

            // masthead: the style's name, lettered big, on a halftone sky
            Item {
                width: parent.width
                height: 58
                InkHalftone {
                    anchors.fill: parent
                    from: 0.3
                    strength: 0.35
                    step: 6
                }
                Text {   // misregistered second print, in peach, behind
                    x: 4
                    y: 4
                    text: Theme.word.toUpperCase() + "!"
                    font.family: Theme.display
                    font.weight: Theme.displayWeight
                    font.pixelSize: Theme.hasBangers ? 54 : 42
                    font.letterSpacing: 2
                    color: Theme.peach
                }
                Text {
                    text: Theme.word.toUpperCase() + "!"
                    font.family: Theme.display
                    font.weight: Theme.displayWeight
                    font.pixelSize: Theme.hasBangers ? 54 : 42
                    font.letterSpacing: 2
                    color: Theme.inkLine
                }
                Column {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.right: parent.right
                        text: Qt.formatTime(win.now, "HH:mm")
                        font.family: Theme.display
                        font.weight: Theme.displayWeight
                        font.pixelSize: Theme.hasBangers ? 26 : 20
                        color: Theme.inkLine
                    }
                    Text {
                        anchors.right: parent.right
                        text: "UP " + win.uptime
                        font.family: Theme.sans
                        font.weight: Font.Black
                        font.pixelSize: 9
                        color: Theme.inkSoft
                    }
                }
            }

            // mode chips
            Row {
                spacing: 8
                Repeater {
                    model: win.modes
                    delegate: Item {
                        id: chip
                        required property var modelData
                        readonly property bool on: modelData.id === win.mode
                        width: chipText.implicitWidth + 18
                        height: 24
                        Rectangle {
                            x: 3
                            y: 3
                            width: parent.width
                            height: parent.height
                            color: Theme.peach
                            visible: chip.on
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: chip.on ? Theme.inkLine : Theme.paper
                            border.width: 2
                            border.color: Theme.inkLine
                        }
                        Text {
                            id: chipText
                            anchors.centerIn: parent
                            text: (chip.modelData.pre ? chip.modelData.pre + " " : "") + chip.modelData.name
                            font.family: Theme.sans
                            font.weight: Font.Black
                            font.pixelSize: 11
                            color: chip.on ? Theme.paper : Theme.inkLine
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                win.setMode(chip.modelData.id);
                                win.field().forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // the query, in a speech bubble
            Item {
                width: parent.width
                height: 46 + 12
                InkBubbleShape {
                    x: 4 + Theme.inkShadow
                    y: 12 + Theme.inkShadow
                    width: parent.width - 12
                    height: 46
                    tail: 12
                    tailX: 70
                    fill: Theme.peach
                    stroke: "transparent"
                }
                InkBubbleShape {
                    x: 4
                    y: 12
                    width: parent.width - 12
                    height: 46
                    tail: 12
                    tailX: 70
                }
                TextInput {
                    id: inkInput
                    x: 24
                    y: 12 + (46 - height) / 2
                    width: parent.width - 60
                    onTextChanged: win.edited(text)
                    font.family: Theme.sans
                    font.weight: Font.Black
                    font.pixelSize: 17
                    color: Theme.inkLine
                    selectionColor: Theme.paperShade
                    cursorDelegate: Rectangle { width: 3; color: Theme.inkLine }
                    Keys.onPressed: event => win.key(event)
                }
                Text {
                    x: 24
                    y: 12 + (46 - height) / 2
                    visible: inkInput.text === ""
                    text: win.mode === "apps" ? "what are we opening?"
                        : win.mode === "calc" ? "do the maths!"
                        : win.mode === "desk" ? "what should the desk do?"
                        : win.mode === "pinned" ? "which pin? (or ~/path to pin)"
                        : "what are we looking up?"
                    font.family: Theme.sans
                    font.weight: Font.Bold
                    font.pixelSize: 15
                    color: Theme.inkMuted
                }
            }

            // results: small panels
            Column {
                width: parent.width
                spacing: 9
                Repeater {
                    model: Theme.ink ? win.results.slice(win.top, win.top + win.rows) : []
                    delegate: Item {
                        id: irow
                        required property var modelData
                        required property int index
                        readonly property bool sel: win.top + index === win.cursor && modelData.kind !== "hint"
                        readonly property bool big: modelData.kind === "calc"
                        width: parent.width - 6
                        height: big ? 54 : 44

                        Rectangle {
                            x: irow.sel ? 5 : 2
                            y: irow.sel ? 5 : 2
                            width: parent.width
                            height: parent.height
                            color: irow.sel ? Theme.peach : Theme.paperShade
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: Theme.paper
                            border.width: irow.sel ? Theme.inkStroke : 2
                            border.color: Theme.inkLine

                            Row {
                                x: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12

                                Rectangle {   // the icon (or glyph), in its own little panel
                                    width: 30
                                    height: 30
                                    anchors.verticalCenter: parent.verticalCenter
                                    readonly property bool iconic: irow.modelData.kind === "app" || irow.modelData.kind === "file"
                                    color: iconic ? Theme.paper : Theme.inkLine
                                    border.width: 2
                                    border.color: Theme.inkLine
                                    IconImage {
                                        id: rowIcon
                                        visible: parent.iconic
                                        anchors.centerIn: parent
                                        implicitSize: 20
                                        // iconPath(…, true) answers "" for a missing icon; fall
                                        // back by hand (the string-fallback form didn't resolve).
                                        source: !parent.iconic ? ""
                                              : Quickshell.iconPath(irow.modelData.icon, true)
                                                || (irow.modelData.mimeicon ? Quickshell.iconPath(irow.modelData.mimeicon, true) : "")
                                                || Quickshell.iconPath(irow.modelData.generic || "application-x-executable", true)
                                        asynchronous: true
                                    }
                                    Text {
                                        visible: !parent.iconic || String(rowIcon.source) === ""
                                        anchors.centerIn: parent
                                        text: irow.modelData.glyph
                                        font.family: Theme.sans
                                        font.weight: Font.Black
                                        font.pixelSize: 15
                                        color: parent.iconic ? Theme.inkLine : Theme.paper
                                    }
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: irow.big ? 240 : 200
                                    elide: Text.ElideRight
                                    text: irow.big ? irow.modelData.title : irow.modelData.title.toUpperCase()
                                    font.family: irow.big ? Theme.display : Theme.sans
                                    font.weight: irow.big ? Theme.displayWeight : Font.Black
                                    font.pixelSize: irow.big ? (Theme.hasBangers ? 30 : 22) : 13
                                    font.letterSpacing: 0.4
                                    color: irow.modelData.kind === "hint" ? Theme.inkMuted : Theme.inkLine
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    // leaves room for the tag on the right
                                    width: irow.big ? 150 : 190
                                    elide: Text.ElideRight
                                    text: irow.modelData.sub
                                    font.family: Theme.sans
                                    font.weight: Font.Medium
                                    font.pixelSize: 11
                                    color: Theme.inkSoft
                                }
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: irow.modelData.kind === "app" && !irow.modelData.pinned ? "" : irow.modelData.tag
                                font.family: Theme.sans
                                font.weight: Font.Black
                                font.pixelSize: 10
                                color: irow.modelData.pinned ? Theme.inkLine : Theme.inkMuted
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: irow.modelData.kind === "hint" ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onEntered: win.cursor = win.top + irow.index
                            onClicked: mouse => win.launch(win.top + irow.index, mouse.modifiers & Qt.ShiftModifier)
                        }
                    }
                }

                Text {
                    visible: win.results.length === 0
                    text: "NOTHING BY THAT NAME."
                    font.family: Theme.display
                    font.weight: Theme.displayWeight
                    font.pixelSize: Theme.hasBangers ? 22 : 17
                    color: Theme.inkMuted
                }
            }

            Text {
                text: win.modeNow.hint.toUpperCase() + " · TAB MODE · CTRL-J/K MOVE · ESC"
                elide: Text.ElideRight
                width: parent.width
                font.family: Theme.sans
                font.weight: Font.Bold
                font.pixelSize: 10
                color: Theme.inkMuted
            }
        }
    }
}
