# Entry point sourced from ~/.zshrc and ~/.bashrc (see install.sh).
# Loads, in filename order:
#   shell/rc.d/*.sh                     every shell (zsh + bash)
#   shell/zsh.d/*.zsh                   zsh only
#   ~/.config/dotfiles/local.d/*.sh     machine-specific, not tracked in git
#
# Files are sourced at top level, not inside a function, so that `typeset`
# in sourced scripts (oh-my-zsh, plugins) does not create function-local variables.

: "${DOTFILES:=$HOME/moondotfiles}"
: "${DOTFILES_LOCAL:=${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/local.d}"

# Loop variables are prefixed so sourced files cannot clobber them.
for __df_entry in "$DOTFILES/shell/rc.d:.sh" "$DOTFILES/shell/zsh.d:.zsh" "$DOTFILES_LOCAL:.sh"; do
    __df_dir="${__df_entry%:*}"
    __df_ext="${__df_entry##*:}"
    [ "$__df_ext" = .zsh ] && [ -z "${ZSH_VERSION:-}" ] && continue
    [ -d "$__df_dir" ] || continue
    # ls instead of a glob: an empty directory must not trigger zsh's "no matches found".
    # shellcheck disable=SC2045
    for __df_name in $(env -u CLICOLOR_FORCE ls -1 "$__df_dir"); do
        case "$__df_name" in
            *"$__df_ext")
                [ "${DOTFILES_VERBOSE:-}" = true ] && echo "* loading $__df_dir/$__df_name"
                # shellcheck source=/dev/null
                . "$__df_dir/$__df_name"
                ;;
        esac
    done
done
unset __df_entry __df_dir __df_ext __df_name
