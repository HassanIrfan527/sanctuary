#!/usr/bin/env python3
"""Japanese active-recall engine for the right-edge cozy drawer.

No due dates: each card holds a mastery LEVEL (0..MASTERED). Grading nudges the
level (Again->0, Hard->hold, Good->+1, Easy->+2). Cards are never "locked until
tomorrow" — they're just ordered. A session always serves the highest-priority
deck that still has un-mastered cards, lowest level first, least-recently-shown
to break ties (so you rotate through a level instead of hammering one card).

CSV sources are READ-ONLY. All progress lives in sidecar JSON keyed by a stable
per-card key, so the decks can be hand-grown freely without bookkeeping.

Usage:
    japanese.py next   [--exclude KEY]      -> one card as JSON, or {} if empty
    japanese.py grade  --deck D --key K -q N
    japanese.py stats                       -> per-deck counts as JSON
"""

import argparse
import csv
import json
import os
import sys

SRC = os.path.expanduser("~/.japanese/src")
PROGRESS = os.path.expanduser("~/.japanese/progress")

MASTERED = 5  # level at/above which a card drops out of the active queue

# Priority order is significant: index 0 is served first while it has work.
# front  : the prompt shown (what you must recall from)
# reading: the kana/romaji answer
# meaning: english gloss ("" when the card is pure kana)
# key    : column name, or a tuple of columns joined by "|" for a stable id
DECKS = [
    {"name": "hiragana", "file": "hiragana.csv",
     "front": "character", "reading": "romaji", "meaning": None, "key": ("character",)},
    {"name": "words", "file": "words.csv",
     "front": "word", "reading": "romaji", "kana": "hiragana", "meaning": "meaning",
     "key": ("word", "hiragana")},
    {"name": "katakana", "file": "katakana.csv",
     "front": "character", "reading": "romaji", "meaning": None, "key": ("character",)},
    {"name": "kanji", "file": "kanji.csv",
     "front": "kanji", "reading": "reading", "romaji": "romaji", "meaning": "meaning",
     "key": ("kanji",)},
]
DECK_BY_NAME = {d["name"]: d for d in DECKS}


def card_key(deck, row):
    return "|".join(row[c] for c in deck["key"])


def load_rows(deck):
    path = os.path.join(SRC, deck["file"])
    if not os.path.exists(path):
        return []
    with open(path, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def progress_path(deck):
    return os.path.join(PROGRESS, deck["name"] + ".json")


def load_progress(deck):
    path = progress_path(deck)
    if not os.path.exists(path):
        return {"_counter": 0, "cards": {}}
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except (json.JSONDecodeError, OSError):
        return {"_counter": 0, "cards": {}}
    data.setdefault("_counter", 0)
    data.setdefault("cards", {})
    return data


def save_progress(deck, data):
    os.makedirs(PROGRESS, exist_ok=True)
    tmp = progress_path(deck) + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=0)
    os.replace(tmp, progress_path(deck))  # atomic


def card_state(prog, key):
    """A card unseen so far is level 0, ord 0 (front of the queue)."""
    return prog["cards"].get(key, {"level": 0, "seen": 0, "ord": 0})


def build_payload(deck, row, key, state):
    # reading = the kana answer; romaji kept separate so the UI can distinguish
    # it from the english meaning. For kana decks the romaji *is* the answer,
    # so reading holds it and romaji stays empty.
    if deck.get("kana"):                       # words: front kanji, answer kana
        reading = row[deck["kana"]]
        romaji = row[deck["reading"]]
    elif deck.get("romaji"):                   # kanji: reading col is kana
        reading = row[deck["reading"]]
        romaji = row[deck["romaji"]]
    else:                                      # hiragana / katakana
        reading = row[deck["reading"]]
        romaji = ""
    meaning = row[deck["meaning"]] if deck["meaning"] else ""
    return {
        "deck": deck["name"],
        "key": key,
        "front": row[deck["front"]],
        "reading": reading,
        "romaji": romaji,
        "meaning": meaning,
        "level": state["level"],
    }


def cmd_next(args):
    """Highest-priority deck with un-mastered cards; lowest (level, ord) wins.

    If every deck is fully mastered, fall back to reviewing the globally
    least-recently-shown card so the loop never dead-ends.
    """
    fallback = None  # (ord, level, deck, row, key, state)
    for deck in DECKS:
        rows = load_rows(deck)
        if not rows:
            continue
        prog = load_progress(deck)
        best = None  # (level, ord, row, key, state)
        for row in rows:
            key = card_key(deck, row)
            if key == args.exclude:
                continue
            st = card_state(prog, key)
            cand = (st["level"], st["ord"], row, key, st)
            if st["level"] < MASTERED and (best is None or cand[:2] < best[:2]):
                best = cand
            fb = (st["ord"], st["level"], deck, row, key, st)
            if fallback is None or fb[:2] < fallback[:2]:
                fallback = fb
        if best is not None:
            print(json.dumps(build_payload(deck, best[2], best[3], best[4]),
                             ensure_ascii=False))
            return
    if fallback is not None:
        _, _, deck, row, key, st = fallback
        print(json.dumps(build_payload(deck, row, key, st), ensure_ascii=False))
        return
    print("{}")


def cmd_grade(args):
    deck = DECK_BY_NAME.get(args.deck)
    if deck is None:
        sys.exit(f"unknown deck: {args.deck}")
    prog = load_progress(deck)
    st = dict(card_state(prog, args.key))
    q = args.q
    if q <= 0:        # Again
        st["level"] = 0
    elif q == 3:      # Hard — hold
        pass
    elif q == 4:      # Good
        st["level"] += 1
    else:             # Easy
        st["level"] += 2
    st["level"] = max(0, min(MASTERED, st["level"]))
    st["seen"] = st.get("seen", 0) + 1
    prog["_counter"] += 1
    st["ord"] = prog["_counter"]
    prog["cards"][args.key] = st
    save_progress(deck, prog)
    print(json.dumps({"key": args.key, "level": st["level"]}, ensure_ascii=False))


def cmd_stats(args):
    out = {}
    for deck in DECKS:
        rows = load_rows(deck)
        if not rows:
            continue
        prog = load_progress(deck)
        total = mastered = learning = new = 0
        for row in rows:
            st = card_state(prog, card_key(deck, row))
            total += 1
            if st["seen"] == 0:
                new += 1
            elif st["level"] >= MASTERED:
                mastered += 1
            else:
                learning += 1
        out[deck["name"]] = {"total": total, "new": new,
                             "learning": learning, "mastered": mastered}
    print(json.dumps(out, ensure_ascii=False))


def main():
    p = argparse.ArgumentParser(description="Japanese recall engine")
    sub = p.add_subparsers(dest="cmd", required=True)

    pn = sub.add_parser("next")
    pn.add_argument("--exclude", default=None)
    pn.set_defaults(func=cmd_next)

    pg = sub.add_parser("grade")
    pg.add_argument("--deck", required=True)
    pg.add_argument("--key", required=True)
    pg.add_argument("-q", type=int, required=True)
    pg.set_defaults(func=cmd_grade)

    ps = sub.add_parser("stats")
    ps.set_defaults(func=cmd_stats)

    args = p.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
