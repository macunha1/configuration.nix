#!/usr/bin/env zsh

declare -A ZSH_HIGHLIGHT_HIGHLIGHTERS=(
	main
	brackets
	line
	cursor
)

declare -A ZSH_HIGHLIGHT_STYLES=(
	[bracket-level-1]='fg=14'
	[bracket-level-2]='fg=13,bold'
	[bracket-level-3]='fg=4'
	[bracket-level-4]='fg=10,bold'

	[alias]='fg=14'
	[command]='fg=10,bold'
	[function]='fg=10'
	[arg0]='fg=10,bold'

	[autodirectory]='fg=4,underline'
	[bracket-error]='fg=9,bold'
	[dollar-quoted-argument]='fg=9'
	[double-quoted-argument]='fg=9,bold'
	[precommand]='fg=14,underline'
	[redirection]='fg=10'
	[reserved-word]='fg=10'
	[single-quoted-argument]='fg=10'
	[suffix-alias]='fg=14,underline'
)

# source profiles
if [[ -d "${HOME}/.profile.d" ]]; then
	for i in ${HOME}/.profile.d/*.sh ; do
		[[ -x "${i}" ]] && source "${i}"
	done
fi
