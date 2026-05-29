#!/usr/bin/env bash
# kanji-quote.sh — print a random kanji phrase for the bottom waybar.
# format: kanji|reading|english
#
# emits JSON; tooltip shows reading + meaning.

set -euo pipefail

phrases=(
    "虚無|kyomu|void"
    "静寂|seijaku|silence"
    "月夜|tsukiyo|moonlit night"
    "桜|sakura|cherry blossom"
    "紫|murasaki|purple"
    "影|kage|shadow"
    "夢|yume|dream"
    "闇|yami|darkness"
    "光|hikari|light"
    "道|michi|the path"
    "心|kokoro|heart, mind"
    "無心|mushin|no-mind"
    "侘寂|wabi-sabi|imperfect beauty"
    "山月|sangetsu|mountain moon"
    "命|inochi|life"
    "静|shizuka|quiet"
    "禅|zen|zen"
    "雪月花|setsugekka|snow, moon, flowers"
    "朧月|oborozuki|hazy moon"
    "木漏れ日|komorebi|sunlight through leaves"
    "浮世|ukiyo|the floating world"
    "物の哀れ|mono no aware|the pathos of things"
    "幽玄|yugen|mysterious profundity"
    "風花|kazahana|snow flurries"
    "風林火山|fuurinkazan|wind, forest, fire, mountain"
    "一期一会|ichi-go ichi-e|once in a lifetime"
    "刹那|setsuna|a fleeting moment"
    "魂|tamashii|soul"
    "刀|katana|blade"
    "黒|kuro|black"
)

pick=${phrases[$RANDOM % ${#phrases[@]}]}
IFS='|' read -r kanji reading english <<<"$pick"

# escape JSON
tooltip="${reading} — ${english}"
printf '{"text":"  %s","tooltip":"%s","class":""}\n' "$kanji" "$tooltip"
