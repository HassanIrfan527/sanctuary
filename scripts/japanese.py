import csv
import random

# we'll use ollama to generate a sentence based on the word we selected.
# import ollama

SOURCES = [
    "/home/anonymous/.japanese/src/hiragana.csv",
    "/home/anonymous/.japanese/src/words.csv",
]

source = random.choice(SOURCES)


def get_random_word():
    """Chooses a random word from the list of csv files."""
    priority_order = ["new", "fail", "almost", "pass", "pro"]
    with open(source, mode="r") as file:
        reader = csv.DictReader(file)

        word_list = list(reader)

    matches = []
    for status in priority_order:
        matches = [row for row in word_list if row["status"] == status]
    if matches:
        random_word = random.choice(matches)
        return random_word
    return random.choice(word_list) if word_list else None


print(get_random_word())
