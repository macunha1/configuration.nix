#!/usr/bin/env bash

find "${WALLPAPERS_DIR:-$HOME/Pictures/.wallpapers}" -type f \
	\( -name '*.jpg' -o -name '*.png' \) -print0 |
	shuf -n1 -z |
	xargs -0 feh --bg-scale
