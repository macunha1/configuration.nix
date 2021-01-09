#!/usr/bin/env bash

# Randomize a wallpaper selection. This script could be used in a CRON job to
# keep changing the wallpaper from time to time.
#
# Define WALLPAPERS_DIR as the root for wallpapers at your disk (multi-level dir
# structure is supported) so this script can search for wallpapers in there.

find "${WALLPAPERS_DIR:-$HOME/Pictures/.wallpapers}" -type f \
	\( -name '*.jpg' -o -name '*.png' \) -print0 |
	shuf -n1 -z |
	xargs -0 feh --no-fehbg --bg-fill
