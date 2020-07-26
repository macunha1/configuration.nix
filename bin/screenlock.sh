#!/usr/bin/env sh

TMPDIR=$(mktemp -d)
TMPIMAGE=${TMPDIR}/screenlock.png

RESOLUTION=$(xdpyinfo | awk '/dimensions/{print $2}')
FILTERS='noise=alls=10,scale=iw*.05:-1,scale=iw*20:-1:flags=neighbor'

ffmpeg -y -loglevel 0 \
	-s "${RESOLUTION}" \
	-f x11grab -i "${DISPLAY}" \
	-vframes 1 \
	-vf "${FILTERS}" \
	"${TMPIMAGE}"

i3lock -e -i "${TMPIMAGE}"
rm -rf "${TMPDIR}"
