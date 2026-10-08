pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The machine's vital signs: CPU / memory (1s, with history for the Signal
// traces), CPU temperature (1s) and disk space (60s).
//
// It also decides what counts as ABNORMAL. Two outputs come from that:
//   exceptions  readouts that only exist while something is off (TEMP, DISK) —
//               normal state renders nothing (§2), so these are the cells and
//               panels that appear and disappear
//   alarms      the subset bad enough to light Master Caution (Caution.qml)
//
// Thresholds live here, in one block, so they are tuned in one place.
Singleton {
    id: root

    // ── thresholds ────────────────────────────────────────────────────
    readonly property real tempWarn: 80      // °C — TEMP cell appears
    readonly property real tempAlarm: 90     // °C — and goes red + caution
    readonly property real diskWarn: 0.90    // used — DISK cell appears
    readonly property real diskAlarm: 0.95   // used — red + caution
    readonly property real cpuAlarm: 0.90    // averaged over cpuWindow samples, so a
    readonly property int cpuWindow: 5       //   compile spike doesn't cry wolf
    readonly property real memAlarm: 0.90

    readonly property int depth: 40   // samples kept = seconds of history drawn

    property real cpu: 0              // 0..1
    property real mem: 0              // 0..1
    property real temp: -1            // °C, -1 = no sensor found
    property var disks: []            // [{ mount, used }] — real filesystems only
    property var cpuHist: []
    property var memHist: []

    readonly property real cpuSustained: {
        const h = cpuHist.slice(-cpuWindow);
        return h.length < cpuWindow ? 0 : h.reduce((a, b) => a + b, 0) / h.length;
    }

    // [{ key, label, value, level: "warn" | "alarm" }]
    readonly property var exceptions: {
        const out = [];
        if (temp >= tempWarn)
            out.push({ key: "temp", label: "TEMP", value: Math.round(temp) + "°",
                       level: temp >= tempAlarm ? "alarm" : "warn" });
        for (const d of disks)
            if (d.used >= diskWarn)
                out.push({ key: "disk:" + d.mount, label: "DISK",
                           value: d.mount + " " + Math.round((1 - d.used) * 100) + "% free",
                           level: d.used >= diskAlarm ? "alarm" : "warn" });
        return out;
    }

    // Short names, one per alarm — what the caution lamp prints.
    readonly property var alarms: {
        const out = [];
        if (cpuSustained >= cpuAlarm)
            out.push("CPU");
        if (mem >= memAlarm)
            out.push("MEM");
        for (const e of exceptions)
            if (e.level === "alarm")
                out.push(e.label);
        return out.filter((v, i, a) => a.indexOf(v) === i);
    }

    property var _prev: null
    property string _tempPath: ""
    // Test hook (IPC `debug fakeTemp`): pretend the sensor reads this. -1 = off.
    // The only honest way to see the TEMP cell and caution without cooking the CPU.
    property real tempOverride: -1

    function _push(arr, v) {
        const a = arr.slice(-(depth - 1));
        a.push(v);
        return a;
    }

    function _parse(out) {
        let idle = 0, total = 0, memTotal = 0, memAvail = 0, t = -1;
        for (const l of out.split("\n")) {
            if (l.startsWith("cpu ")) {
                const f = l.trim().split(/\s+/).slice(1).map(Number);
                total = f.reduce((a, b) => a + b, 0);
                idle = f[3] + (f[4] || 0); // idle + iowait
            } else if (l.startsWith("MemTotal:")) {
                memTotal = parseInt(l.split(/\s+/)[1]);
            } else if (l.startsWith("MemAvailable:")) {
                memAvail = parseInt(l.split(/\s+/)[1]);
            } else if (/^\d+$/.test(l.trim())) {
                // The hwmon file: a bare number in millidegrees. Nothing else in
                // /proc/stat or meminfo is a line of digits alone.
                t = parseInt(l.trim()) / 1000;
            }
        }

        if (_prev) {
            const dTotal = total - _prev.total;
            cpu = dTotal > 0 ? Math.max(0, Math.min(1, 1 - (idle - _prev.idle) / dTotal)) : 0;
            cpuHist = _push(cpuHist, cpu);
        }
        mem = memTotal > 0 ? 1 - memAvail / memTotal : 0;
        memHist = _push(memHist, mem);
        temp = tempOverride >= 0 ? tempOverride : t;
        _prev = { idle: idle, total: total };
    }

    function pct(v) {
        return Theme.pad(Math.round(v * 100) + "%", 4, " ");
    }

    // ── sampling ──────────────────────────────────────────────────────
    Process {
        id: probe
        command: ["cat", "/proc/stat", "/proc/meminfo"]
                 .concat(root._tempPath !== "" ? [root._tempPath] : [])
        stdout: StdioCollector {
            id: collected
            onStreamFinished: root._parse(collected.text)
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!probe.running) probe.running = true
    }

    // The CPU sensor. hwmonN numbers are handed out at boot and can change, so
    // find it by driver name: coretemp (Intel, "Package id 0"), k10temp /
    // zenpower (AMD, "Tctl"/"Tdie"). Falls back to that driver's temp1.
    Process {
        id: findSensor
        running: true
        command: ["sh", "-c",
            "for d in /sys/class/hwmon/hwmon*; do " +
            "  case \"$(cat $d/name 2>/dev/null)\" in coretemp|k10temp|zenpower|cpu_thermal) ;; *) continue ;; esac; " +
            "  for l in $d/temp*_label; do " +
            "    case \"$(cat $l 2>/dev/null)\" in 'Package id 0'|Tctl|Tdie) echo ${l%_label}_input; exit ;; esac; " +
            "  done; " +
            "  [ -r $d/temp1_input ] && { echo $d/temp1_input; exit; }; " +
            "done"]
        stdout: StdioCollector {
            id: sensorOut
            onStreamFinished: root._tempPath = sensorOut.text.trim()
        }
    }

    // Disks. Real filesystems only, one row per device (/ and /home are often
    // the same partition), and not /boot — it is small and full by design.
    Process {
        id: df
        command: ["df", "-P", "-x", "tmpfs", "-x", "devtmpfs", "-x", "efivarfs",
                  "-x", "squashfs", "-x", "overlay", "-x", "fuse.portal"]
        stdout: StdioCollector {
            id: dfOut
            onStreamFinished: {
                const seen = {};
                const out = [];
                for (const l of dfOut.text.split("\n").slice(1)) {
                    const f = l.trim().split(/\s+/);
                    if (f.length < 6 || seen[f[0]])
                        continue;
                    const mount = f.slice(5).join(" ");
                    if (mount.startsWith("/boot"))
                        continue;
                    seen[f[0]] = true;
                    const size = Number(f[1]), used = Number(f[2]);
                    if (size > 0)
                        out.push({ mount: mount, used: used / size });
                }
                root.disks = out;
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!df.running) df.running = true
    }

    // ── actions ───────────────────────────────────────────────────────
    // Right-click on CPU / MEM / TEMP: btop as a floating kitty. A toggle — if
    // it is already open, the same click closes it.
    function btop() {
        Niri.toggleApp("sanctuary-btop", ["kitty", "--class", "sanctuary-btop", "-e", "btop"]);
    }
}
