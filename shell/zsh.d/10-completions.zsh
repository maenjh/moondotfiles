# Completion search paths. Must run before compinit (oh-my-zsh calls it in 20-oh-my-zsh.zsh).

if (( $+commands[brew] )); then
    fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
fi

# zsh-completions is added to fpath directly instead of as an oh-my-zsh plugin.
# https://github.com/zsh-users/zsh-completions/issues/603
_zsh_completions_src="${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}/plugins/zsh-completions/src"
[[ -d $_zsh_completions_src ]] && fpath=("$_zsh_completions_src" $fpath)
unset _zsh_completions_src

# Generated completions, rebuilt only when missing or when the tool is upgraded,
# so startup does not run every tool on each new shell.
_dotfiles_comp_dir="${XDG_CACHE_HOME:-$HOME/.cache}/moondotfiles/completions"
[[ -d $_dotfiles_comp_dir ]] || mkdir -p "$_dotfiles_comp_dir"

# _dotfiles_gen_completion NAME COMMAND...: write COMMAND's output to _NAME.
_dotfiles_gen_completion() {
    local name=$1 bin=${commands[$2]}
    shift
    [[ -n $bin ]] || return 0
    local file="$_dotfiles_comp_dir/_$name"
    if [[ ! -s $file || $bin -nt $file ]]; then
        "$@" >| "$file" 2>/dev/null || rm -f "$file"
    fi
}

_dotfiles_gen_completion uv uv generate-shell-completion zsh
_dotfiles_gen_completion uvx uvx --generate-shell-completion zsh
_dotfiles_gen_completion poetry poetry completions zsh
_dotfiles_gen_completion poe poe _zsh_completion

fpath=("$_dotfiles_comp_dir" $fpath)
unset -f _dotfiles_gen_completion
unset _dotfiles_comp_dir
