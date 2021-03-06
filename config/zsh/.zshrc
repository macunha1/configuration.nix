#!/usr/bin/env zsh

plugins=(
    aws
    git
    helm
    kubectl
)

source "${HOME}/.config/zsh/env.zsh"
source "${ZSH}/oh-my-zsh.sh"
source "${ANTIGEN_HOME}/antigen.zsh"

antigen bundles <<EOFBUNDLES
    zsh-users/zsh-autosuggestions
    zsh-users/zsh-syntax-highlighting
    macunha1/zsh-terraform
EOFBUNDLES

antigen apply

# Some personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Keep on mind that aliases fit
# better in the ${ZSH_CUSTOM}/plugins/${TOOL} folder.

alias o=ouroboros

command -v pbcopy >/dev/null && {
    alias clipbc='pbcopy'
    alias clipbp='pbpaste'
} || {
    alias clipbc='xclip -in -selection clipboard < "${1:-/dev/stdin}"'
    alias clipbp='xclip -out -selection clipboard'
}

alias urlencode='python3 -c "import sys, urllib.parse as ul; print(ul.quote_plus(sys.argv[1]))"'
alias urldecode='python3 -c "import sys, urllib.parse as ul; print(ul.unquote_plus(sys.argv[1]))"'

# Bind keys for "Kill line" i.e.: remove everything before or after the cursor.
bindkey \^U backward-kill-line # before
# Ctrl+K is the original kill-line on Bash/Zsh, it was changed to avoid
# conflicts with Tmux Vim navigation keybindings. The key Y was selected because
# it stays close to the above U (on a QWERTY keyboard)
bindkey \^Y kill-line # after

autoload -U +X bashcompinit && bashcompinit

source "${HOME}/.config/zsh/init.zsh"

for CLI_TOOL in kubectl minikube helm; do
    CLI_BIN_PATH=$(which ${CLI_TOOL}) && \
        source <("${CLI_BIN_PATH}" completion zsh)
done

eval "$(starship init zsh)"
eval "$(keychain --dir "${XDG_CONFIG_HOME}/keychain" -q --eval || ssh-agent)" >/dev/null
