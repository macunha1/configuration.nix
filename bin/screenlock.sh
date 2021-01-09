#!/usr/bin/env sh

# Takes a screenshot, blur it using ffmpeg and use the screenshot as screen
# lock. Which creates a feeling of blurred desktop when locked.
# 
# Similar to i3lock-fancy, but (significantly) faster and focused on privacy, as
# the blurring + pixelation make it hard to see what was there before locking
# the screen.
# Ref: https://github.com/meskarune/i3lock-fancy

# Use a temp dir to store the screenshot
TMPDIR=$(mktemp -d)
TMPIMAGE=${TMPDIR}/screenlock.png

# Define image size based on displays dimension (all displays are considered)
RESOLUTION=$(xdpyinfo | awk '/dimensions/{print $2}')
# Define ffmpeg filters to apply on the screenshot to create the blur effect
FILTERS='noise=alls=10,scale=iw*.05:-1,scale=iw*20:-1:flags=neighbor'

ffmpeg -y -loglevel 0 \
	-s "${RESOLUTION}" \
	-f x11grab -i "${DISPLAY}" \
	-vframes 1 \
	-vf "${FILTERS}" \
	"${TMPIMAGE}"

# Lock the screen with i3lock passing the blurred screenshot
i3lock -e -i "${TMPIMAGE}"
rm -rf "${TMPDIR}"
