#!/usr/bin/env bash
# Prints one random calm kanji glyph for the zen-mode center watermark.
kanji=(静 無 空 禅 風 月 心 夢 道 和 寂 幽 雅 凪 灯)
echo "${kanji[RANDOM % ${#kanji[@]}]}"
