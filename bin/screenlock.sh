#!/usr/bin/env sh

CACHEFILE=${HOME}/.cache/screenlock.tmp
TMPDIR=$(cat ${CACHEFILE} 2>/dev/null || touch ${CACHEFILE})
[[ -d ${TMPDIR} ]] || TMPDIR=$(mktemp -d)
TMPIMAGE=${TMPDIR}/screen_lock.png

RESOLUTION=$(xdpyinfo | awk '/dimensions/{print $2}')
FILTERS='noise=alls=10,scale=iw*.05:-1,scale=iw*20:-1:flags=neighbor'

ffmpeg -y -loglevel 0 \
	-s "${RESOLUTION}" \
	-f x11grab -i "${DISPLAY}" \
	-vframes 1 \
	-vf "${FILTERS}" \
	"${TMPIMAGE}"

i3lock -e -i "${TMPIMAGE}"
echo "${TMPIMAGE}" > "${CACHEFILE}"
