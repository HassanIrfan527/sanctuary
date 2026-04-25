#!/usr/bin/env python3

import subprocess
from datetime import date, datetime
import random

FILE = "/mnt/PERSONAL/Obsidian/Personal/01-Identity/Journal/.journal.md"

placeholders = [
    "Any good thing?",
    "Can be something small",
    "What's going on?",
    "Write something positive",
    "Something happened today?",
]


def fuzzel_menu():

    selected_placeholder = random.choice(placeholders)
    # Run fuzzel and capture output
    process = subprocess.run(
        [
            "fuzzel",
            "--dmenu",
            "--prompt",
            "🌱  ",
            "--placeholder",
            selected_placeholder,
            "--lines",
            "0",
            "--width",
            "40",
            "-o",
            "border.radius=20",
            "-o",
            "border.width=2",
            "-o",
            "horizontal-pad=24",
            "-o",
            "vertical-pad=18",
            "-o",
            "inner-pad=12",
        ],
        text=True,
        input="\n",
        capture_output=True,
        check=False,
    )

    # If I press Escape or closed the window, exit
    if process.returncode != 0:
        return None

    return process.stdout.strip()


def store_data(text):
    # Only write if there is actual content
    if not text:
        return False

    with open(FILE, "a") as f:
        current_date = date.today()
        current_time = datetime.now().strftime("%I:%M %p")
        note = f"# {current_date} - {current_time}\n{text}\n"

        f.write(note)

    return True


entry = fuzzel_menu()

if entry:  # This only runs if input is not None and not empty
    if store_data(entry):
        print("Entry saved!")
else:
    print("No entry created.")
