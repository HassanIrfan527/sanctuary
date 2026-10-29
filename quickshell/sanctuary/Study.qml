pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The VU study portal's data, for STUDY (StudyCard.qml). This only READS one
// file and RUNS one command; every number is already worked out:
//
//   reads  ~/Development/pixiecode/personal/study/portal.json   (study_export.py)
//   runs   ~/.local/bin/study mark | submit | plan --budget | export
//
// The markdown in personal/study/ is the truth and only the `study` CLI writes
// it; each write re-exports portal.json, which this reloads. No colours, no
// style words.
Singleton {
    id: root

    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/study"
    readonly property string path: Quickshell.env("HOME") + "/Development/pixiecode/personal/study/portal.json"

    property var data: null
    readonly property bool ready: data !== null
    readonly property bool busy: proc.running
    property string error: ""       // the last command's complaint, until the next one

    readonly property var plan: ready ? data.plan : null
    readonly property var planNow: ready ? data.plan_now : null
    readonly property var courses: ready ? data.courses.filter(c => c.released !== null) : []
    readonly property var urgent: ready ? data.urgent : []

    // Today's list: the morning plan's done blocks, then what's left of it,
    // re-scored (plan.rest) once something is ticked. Planned vs done stays visible.
    readonly property var today: {
        if (!plan)
            return [];
        const done = plan.blocks.filter(b => b.done);
        const rest = plan.rest ? plan.rest.blocks : plan.blocks.filter(b => !b.done);
        return done.concat(rest);
    }

    // The rest of this week (Mon–Sun), from now: not over yet, or live.
    readonly property var week: {
        if (!ready)
            return [];
        const now = new Date();
        const mon = new Date(now.getFullYear(), now.getMonth(), now.getDate() - (now.getDay() + 6) % 7);
        const next = new Date(mon.getFullYear(), mon.getMonth(), mon.getDate() + 7);
        return data.events.filter(e => {
            const d = new Date(e.date);
            return d < next && (e.state === "live" || (e.state === "upcoming" && (e.end ? new Date(e.end) : d) >= now));
        });
    }

    // Quiz-like assessments live now or due within two weeks (announced or not),
    // plus ones already submitted, until their window closes.
    readonly property var quizzes: {
        if (!ready)
            return [];
        const now = Date.now(), soon = now + 14 * 86400000;
        return data.assessments.filter(a => ["quiz", "attendance", "gdb", "assignment"].indexOf(a.kind) >= 0
            && (a.state === "live" || (a.state === "upcoming" && new Date(a.due).getTime() < soon)
                || (a.deadline_status === "submitted" && new Date(a.due).getTime() > now)))
            .sort((x, y) => x.due < y.due ? -1 : 1);
    }

    // QUIZZES tab: every quiz-like assessment plus midterms and finals, by date.
    readonly property var allAssessments: ready ? data.assessments.slice().sort((x, y) => (x.due || "") < (y.due || "") ? -1 : 1) : []
    function isQuizLike(a) {
        return ["quiz", "attendance", "gdb", "assignment"].indexOf(a.kind) >= 0;
    }
    // Where the QUIZZES cursor starts: the first one whose window hasn't closed.
    readonly property int firstOpenAssessment: Math.max(0, allAssessments.findIndex(a => !a.due || new Date(a.due).getTime() > Date.now()))

    // A course's items in order (its syllabus), optionally only n in [lo, hi].
    function items(code, lo, hi) {
        if (!ready)
            return [];
        return data.lectures.filter(l => l.course === code && (lo === undefined || (l.n >= lo && l.n <= hi)));
    }
    function assessmentsOf(code) {
        return allAssessments.filter(a => a.course === code);
    }
    // The rules for this quiz (its course's section, when that section is about
    // this very quiz: ENG101's is "Quiz 1"), then the ones for every course.
    function rulesFor(a) {
        if (!ready || !data.quiz_rules)
            return "";
        const own = data.quiz_rules[a.course] || "";
        const mine = own.split("\n")[0].indexOf(a.title.split(" — ")[0]) >= 0 ? own : "";
        return [mine, data.quiz_rules.ALL].filter(t => !!t).join("\n\n").replace(/\*\*/g, "");
    }

    // WEEK tab: semester week N (1 = Mon 2026-10-12) and what's in it.
    function weekStart(n) {
        const w1 = new Date(data.semester.week1 + "T00:00");
        return new Date(w1.getFullYear(), w1.getMonth(), w1.getDate() + 7 * (n - 1));
    }
    function eventsOfWeek(n) {
        if (!ready)
            return [];
        const a = weekStart(n), b = weekStart(n + 1);
        return data.events.filter(e => {
            const d = new Date(e.date);
            return d >= a && d < b;
        });
    }
    readonly property int weeksShown: ready ? Math.max(data.semester.teaching_weeks, 18) : 16

    // ── words ─────────────────────────────────────────────────────────
    function range(a) {   // "Nov 2–4", "Dec 7"
        if (!a.due)
            return "no date";
        const d = new Date(a.due);
        if (!a.opens)
            return Qt.formatDateTime(d, "MMM d");
        const o = new Date(a.opens);
        return Qt.formatDateTime(o, "MMM d") + "–" + (o.getMonth() === d.getMonth() ? Qt.formatDateTime(d, "d") : Qt.formatDateTime(d, "MMM d"));
    }
    function pct(x) {
        return Math.floor(x * 100 + 0.5) + "%";
    }
    function hm(min) {
        const h = Math.floor(min / 60), m = Math.round(min % 60);
        return h > 0 ? h + " h " + (m < 10 ? "0" : "") + m + " m" : m + " m";
    }
    function day(iso) {
        return Qt.formatDateTime(new Date(iso), "ddd d");
    }
    function time(iso) {
        return iso.length > 10 && !iso.endsWith("T00:00") ? Qt.formatDateTime(new Date(iso), "HH:mm") : "";
    }
    // "Lessons 2–3", "Lecture 1", "Attempt Quiz 1"
    function blockItems(b) {
        if (!b.ns || b.ns.length < 2)
            return b.items.join(", ");
        const word = b.items[0].split(" ")[0];
        return word + "s " + b.ns[0] + "–" + b.ns[b.ns.length - 1];
    }

    // ── commands ──────────────────────────────────────────────────────
    // Tick a plan block: its items → watched (ticked again → back to todo);
    // an "Attempt" block marks its deadline submitted. A quiz row (an
    // assessment) that's open or submitted toggles submitted too.
    function submitted(a) {
        return a.deadline_status === "submitted";
    }
    function tickable(a) {
        return a.deadline_status === undefined || a.state === "live" || submitted(a);
    }
    function tick(b) {
        if (b.deadline_status !== undefined) {
            if (tickable(b))
                run(["submit", b.id].concat(submitted(b) ? ["--undo"] : []));
        } else if (b.kind === "attempt")
            run(["submit", b.assessment].concat(b.done ? ["--undo"] : []));
        else
            run(["mark", b.course, b.ns.join(","), b.done ? "todo" : "watched"]);
    }
    // One item up or down the ladder: todo → watched → noted → revised.
    readonly property var ladder: ["todo", "watched", "noted", "revised"]
    function step(item, dir) {
        const i = Math.max(0, ladder.indexOf(item.status)) + dir;
        if (i >= 0 && i < ladder.length)
            run(["mark", item.course, String(item.n), ladder[i]]);
    }
    function budget(min) {
        run(["plan", "--budget", String(min)]);
    }
    function refresh() {
        run(["export"]);
    }

    property var queue: []
    function run(args) {
        if (proc.running) {
            queue = queue.concat([args]);
            return;
        }
        error = "";
        proc.command = [bin].concat(args);
        proc.running = true;
    }

    Process {
        id: proc
        stderr: StdioCollector {
            id: err
        }
        onExited: code => {
            if (code !== 0)
                root.error = (err.text.trim().split("\n").pop() || ("study exited " + code));
            file.reload();
            if (root.queue.length > 0) {
                const next = root.queue[0];
                root.queue = root.queue.slice(1);
                root.run(next);
            }
        }
    }

    FileView {
        id: file
        path: root.path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.data = JSON.parse(file.text());
            } catch (e) {
                root.error = "portal.json unreadable — run `study export`";
            }
        }
        onLoadFailed: root.error = "no portal.json — run `study export`"
    }
}
