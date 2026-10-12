#!/usr/bin/env python3
"""Keep the session awake while you're plainly still here, just not on the
keyboard or mouse: playing with a controller, or watching/listening to
something.

    awake.py            run forever (idle.sh starts it next to swayidle)
    awake.py --no-audio only the controller counts, not playing audio
    awake.py --status   print what it would decide right now, then exit

── Why this exists ──────────────────────────────────────────────────────
swayidle's 30-minute lock counts "idle" the way niri does: no input through
libinput. libinput only handles keyboards, mice, touchpads, tablets —
gamepads are opened by the game itself (SDL/Steam), so niri never sees them.
An hour of controller play looks exactly like an empty room.

Video is the same story: Firefox and mpv tell the compositor "don't sleep"
while playing, but plenty of apps (qutebrowser's QtWebEngine, some games
under XWayland) never do.

── How ──────────────────────────────────────────────────────────────────
niri implements org.freedesktop.ScreenSaver on the session bus. Calling
Inhibit on it makes niri report "not idle" to swayidle until we UnInhibit,
or until this process's bus connection dies — so a crash can never leave
the screen stuck awake.

Inhibit is held while either:
  - a gamepad was used within PAD_GRACE seconds, or
  - an app is actively playing audio (a PipeWire output stream in state
    "running"; browsers and players stop the stream on pause).
Released otherwise, and swayidle's 30 minutes start counting from then.
"""
import json
import os
import selectors
import subprocess
import sys
import time

import evdev
from evdev import ecodes as E
from gi.repository import Gio, GLib

PAD_GRACE = 300      # s after the last controller input that we stay awake
RESCAN = 5           # s between looks for newly plugged controllers
AUDIO_EVERY = 15     # s between PipeWire checks
STICK_DEADZONE = 0.25  # fraction of an axis' half-range; ignores stick drift
# Chat apps hold an output stream open (often silent) for pings and calls, so
# they'd keep the screen awake forever. Their audio doesn't count.
AUDIO_IGNORE = {"vesktop", "discord", "webcord", "signal", "slack"}


def is_gamepad(dev):
    # BTN_SOUTH (A / cross) is what every gamepad has. Plain "joystick" isn't
    # enough: keyd's virtual pointer registers as one (it's /dev/input/js0).
    return E.BTN_SOUTH in dev.capabilities().get(E.EV_KEY, [])


class Pads:
    """Watches every connected gamepad; .last is the time of the last real input."""

    def __init__(self):
        self.sel = selectors.DefaultSelector()
        self.devs = {}        # path -> InputDevice
        self.ranges = {}      # (path, code) -> (centre, half-range)
        self.last = 0.0

    def rescan(self):
        present = set(evdev.list_devices())
        for path in list(self.devs):
            if path not in present:
                self._drop(path)
        for path in present - set(self.devs):
            try:
                dev = evdev.InputDevice(path)
            except OSError:
                continue
            if not is_gamepad(dev):
                dev.close()
                continue
            self.devs[path] = dev
            for code, info in dev.capabilities().get(E.EV_ABS, []):
                half = (info.max - info.min) / 2 or 1
                self.ranges[(path, code)] = (info.min + half, half)
            self.sel.register(dev, selectors.EVENT_READ, path)
            log(f"watching {dev.name} ({path})")

    def _drop(self, path):
        dev = self.devs.pop(path)
        try:
            self.sel.unregister(dev)
            dev.close()
        except (KeyError, OSError, ValueError):
            pass
        log(f"lost {path}")

    def _counts(self, path, ev):
        if ev.type == E.EV_KEY:
            return True
        if ev.type != E.EV_ABS:
            return False
        if E.ABS_HAT0X <= ev.code <= E.ABS_HAT3Y:   # d-pad: any press
            return ev.value != 0
        centre, half = self.ranges.get((path, ev.code), (0, 1))
        # Triggers rest at min, not centre: measure from min for those.
        if ev.code in (E.ABS_Z, E.ABS_RZ, E.ABS_BRAKE, E.ABS_GAS) and centre - half >= 0:
            return (ev.value - (centre - half)) / (2 * half) > STICK_DEADZONE
        return abs(ev.value - centre) / half > STICK_DEADZONE

    def poll(self, timeout):
        for key, _ in self.sel.select(timeout):
            path = key.data
            try:
                for ev in key.fileobj.read():
                    if self._counts(path, ev):
                        self.last = time.monotonic()
                        break
            except BlockingIOError:
                pass
            except OSError:          # unplugged mid-read
                self._drop(path)

    def active(self):
        return self.last and time.monotonic() - self.last < PAD_GRACE


def audio_playing():
    try:
        out = subprocess.run(["pw-dump"], capture_output=True, timeout=5).stdout
        nodes = json.loads(out or b"[]")
    except (OSError, subprocess.SubprocessError, ValueError):
        return False
    for n in nodes:
        info = n.get("info") or {}
        props = info.get("props") or {}
        app = (props.get("application.name") or "").lower()
        if (props.get("media.class") == "Stream/Output/Audio"
                and info.get("state") == "running"
                and not any(name in app for name in AUDIO_IGNORE)):
            return True
    return False


class Inhibitor:
    """Holds (or not) an org.freedesktop.ScreenSaver inhibit on niri."""

    def __init__(self):
        self.bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
        self.cookie = None

    def _call(self, method, args):
        return self.bus.call_sync(
            "org.freedesktop.ScreenSaver", "/org/freedesktop/ScreenSaver",
            "org.freedesktop.ScreenSaver", method, args, None,
            Gio.DBusCallFlags.NONE, 2000, None)

    def set(self, on, why=""):
        if on and self.cookie is None:
            try:
                self.cookie = self._call("Inhibit", GLib.Variant("(ss)", ("awake", why))).unpack()[0]
                log(f"awake: {why}")
            except GLib.Error as e:
                log(f"inhibit failed: {e.message}")
        elif not on and self.cookie is not None:
            try:
                self._call("UnInhibit", GLib.Variant("(u)", (self.cookie,)))
            except GLib.Error as e:
                log(f"uninhibit failed: {e.message}")
            self.cookie = None
            log("idle allowed again")


def log(msg):
    print(time.strftime("%H:%M:%S"), msg, flush=True)


def main():
    use_audio = "--no-audio" not in sys.argv
    pads = Pads()
    pads.rescan()

    if "--status" in sys.argv:
        print("gamepads:", [d.name for d in pads.devs.values()] or "none")
        print("audio playing:", audio_playing())
        return

    inhib = Inhibitor()
    next_scan = next_audio = 0.0
    audio = False
    while True:
        now = time.monotonic()
        if now >= next_scan:
            pads.rescan()
            next_scan = now + RESCAN
        if use_audio and now >= next_audio:
            audio = audio_playing()
            next_audio = now + AUDIO_EVERY

        if pads.active():
            inhib.set(True, "controller in use")
        elif audio:
            inhib.set(True, "media playing")
        else:
            inhib.set(False)

        pads.poll(1.0)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
