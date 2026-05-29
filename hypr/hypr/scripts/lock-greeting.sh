#!/usr/bin/env bash
# Time-aware cozy greeting for the lock screen: Japanese · English.
h=$(date +%H)
if   (( 10#$h >= 5  && 10#$h < 11 )); then echo "おはよう · good morning"
elif (( 10#$h >= 11 && 10#$h < 17 )); then echo "こんにちは · good afternoon"
elif (( 10#$h >= 17 && 10#$h < 22 )); then echo "こんばんは · good evening"
else                                        echo "おやすみ · rest well"
fi
