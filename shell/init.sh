# Entry point sourced from ~/.zshrc and ~/.bashrc (see install.sh).
# Loads, in filename order:
#   shell/rc.d/*.sh                     every shell (zsh + bash)
#   shell/zsh.d/*.zsh                   zsh only
#   ~/.config/dotfiles/local.d/*.sh     machine-specific, not tracked in git

: "${DOTFILES:=$HOME/moondotfiles}"
: "${DOTFILES_LOCAL:=${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/local.d}"

_dotfiles_source_dir() {
    [ -d "$1" ] || return 0
    # An empty directory must not trigger zsh's "no matches found" error.
    [ -n "${ZSH_VERSION:-}" ] && setopt localoptions nullglob
    for _file in "$1"/*"$2"; do
        [ -f "$_file" ] || continue
        [ "${DOTFILES_VERBOSE:-}" = true ] && echo "* loading $_file"
        # shellcheck source=/dev/null
        . "$_file"
    done
    unset _file
}

_dotfiles_source_dir "$DOTFILES/shell/rc.d" .sh
[ -n "${ZSH_VERSION:-}" ] && _dotfiles_source_dir "$DOTFILES/shell/zsh.d" .zsh
_dotfiles_source_dir "$DOTFILES_LOCAL" .sh

unset -f _dotfiles_source_dir
