# oh-my-zsh with the spaceship prompt. Installed by install.sh.

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
: "${SPACESHIP_CONFIG:=$DOTFILES/config/spaceship.zsh}"
export SPACESHIP_CONFIG

if [[ -f $ZSH/oh-my-zsh.sh ]]; then
    # Skip if an earlier rc file already loaded oh-my-zsh.
    if ! (( $+functions[omz] )); then
        ZSH_THEME="spaceship/spaceship"
        DISABLE_AUTO_UPDATE="true"
        DISABLE_MAGIC_FUNCTIONS="true"

        plugins=(git git-prompt docker docker-compose sudo dotenv colorize)
        # External plugins, only when present. zsh-syntax-highlighting must be last.
        for _plugin in zsh-autosuggestions zsh-syntax-highlighting; do
            [[ -d ${ZSH_CUSTOM:-$ZSH/custom}/plugins/$_plugin ]] && plugins+=("$_plugin")
        done
        unset _plugin

        source "$ZSH/oh-my-zsh.sh"
    fi
elif ! (( $+functions[compdef] )); then
    autoload -Uz compinit && compinit -u
fi
