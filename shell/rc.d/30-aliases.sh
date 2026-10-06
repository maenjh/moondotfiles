# Aliases and small functions shared by zsh and bash.

alias paths="path_show"

# GPU monitor on servers; falls back to uvx when nvitop is not installed.
if command -v nvitop >/dev/null 2>&1; then
    alias gpu="nvitop"
else
    alias gpu="uvx nvitop"
fi

# mcd DIR: mkdir -p and cd into it.
mcd() {
    mkdir -p "$1" && cd "$1" || return
}

# refreshenv: restart the current shell to pick up config changes.
refreshenv() {
    exec "$(ps -p $$ -o comm= | sed 's/^-//')"
}

# dots-update: pull the latest dotfiles and re-run the installer.
dots-update() {
    git -C "$DOTFILES" pull --ff-only && "$DOTFILES/install.sh" "$@"
}
