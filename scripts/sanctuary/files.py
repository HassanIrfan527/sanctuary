#!/usr/bin/env python3
# Pinned files and folders for the launcher (Launcher.qml: FILES mode, and on
# top of APPS). Only what you pin — nothing is collected on its own.
#
# The list: ~/.local/state/sanctuary/pins.json — a JSON list of paths, in your
# order. Edit it by hand if you like; ~ is fine.
#
#   files.py                  print { "pins": [ { path, name, where, dir, icon,
#                             mimeicon, generic, ext, gone } ] } — the launcher runs this
#   files.py pin <path>…      add (a path already pinned stays where it is)
#   files.py unpin <path>…    remove
#   files.py toggle <path>…   pin what isn't, unpin what is (Nautilus script)
#   files.py list             the paths, one per line
import json, mimetypes, os, subprocess, sys

HOME = os.path.expanduser("~")
PINS = os.path.join(HOME, ".local/state/sanctuary/pins.json")


def tilde(p):
    return "~" + p[len(HOME):] if p == HOME or p.startswith(HOME + "/") else p


# The icon of the app that will open it (Papers for a PDF, Files for a
# folder): Qt here has no icon theme set, so it finds app icons (hicolor) but
# not mime-type ones like application-pdf.
_apps = {}
def app_icon(mime):
    if mime not in _apps:
        icon = ""
        try:
            desk = subprocess.run(["xdg-mime", "query", "default", mime], capture_output=True,
                                  text=True, timeout=2).stdout.strip()
        except (OSError, subprocess.TimeoutExpired):
            desk = ""
        dirs = [os.path.join(HOME, ".local/share")] + os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")
        for d in dirs if desk else []:
            f = os.path.join(d, "applications", desk)
            if os.path.isfile(f):
                with open(f, errors="replace") as fh:
                    for line in fh:
                        if line.startswith("Icon="):
                            icon = line[5:].strip()
                            break
                break
        _apps[mime] = icon
    return _apps[mime]


def entry(path):
    isdir = os.path.isdir(path)
    name = os.path.basename(path.rstrip("/")) or path
    mime = "inode/directory" if isdir else mimetypes.guess_type(name)[0] or "text/plain"
    top = mime.split("/")[0]
    return {
        "path": path,
        "name": name,
        "where": tilde(os.path.dirname(path.rstrip("/"))),
        "dir": isdir,
        "icon": app_icon(mime),
        # application/pdf -> application-pdf; tried if there is no app icon,
        # then the family's generic icon
        "mimeicon": mime.replace("/", "-"),
        "generic": "folder" if isdir else top + "-x-generic" if top in ("audio", "video", "image", "text") else "application-x-generic",
        "ext": "" if isdir else os.path.splitext(name)[1].lstrip(".").lower(),
        "gone": not os.path.exists(path),   # kept, so you can unpin it
    }


def load():
    try:
        with open(PINS) as f:
            raw = json.load(f)
    except (OSError, ValueError):
        return []
    return [os.path.expanduser(p) for p in raw if isinstance(p, str)] if isinstance(raw, list) else []


def save(paths):
    os.makedirs(os.path.dirname(PINS), exist_ok=True)
    tmp = PINS + ".tmp"
    with open(tmp, "w") as f:
        json.dump(paths, f, indent=1)
    os.replace(tmp, PINS)


def notify(msg):
    os.system("notify-send -a sanctuary '[ pins ]' " + json.dumps(msg) + " 2>/dev/null")


cmd, args = (sys.argv[1], sys.argv[2:]) if len(sys.argv) > 1 else ("json", [])
paths = load()
if cmd == "json":
    json.dump({"pins": [entry(p) for p in paths]}, sys.stdout)
elif cmd == "list":
    print("\n".join(paths))
elif cmd in ("pin", "unpin", "toggle"):
    added, removed = [], []
    for a in args:
        p = os.path.abspath(os.path.expanduser(a))
        if p in paths and cmd != "pin":
            paths.remove(p)
            removed.append(os.path.basename(p))
        elif p not in paths and cmd != "unpin":
            paths.append(p)
            added.append(os.path.basename(p))
    save(paths)
    if cmd == "toggle":   # Nautilus has no terminal to print to
        notify(("pinned: " + ", ".join(added) if added else "")
               + ("  " if added and removed else "")
               + ("unpinned: " + ", ".join(removed) if removed else ""))
    for n in added:
        print("pinned  ", n)
    for n in removed:
        print("unpinned", n)
else:
    sys.exit("usage: files.py [pin|unpin|toggle <path>…|list]")
