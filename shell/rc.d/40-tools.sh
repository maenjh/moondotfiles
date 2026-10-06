# Shell hooks for tools that support both zsh and bash.

if [ -n "${ZSH_VERSION:-}" ]; then
    _shell=zsh
elif [ -n "${BASH_VERSION:-}" ]; then
    _shell=bash
fi

if [ -n "${_shell:-}" ]; then
    if command -v direnv >/dev/null 2>&1; then
        eval "$(direnv hook "$_shell")"
    fi

    # zsh completions are set up in zsh.d/ once compinit has run.
    if [ "$_shell" = bash ] && command -v uv >/dev/null 2>&1; then
        eval "$(uv generate-shell-completion bash)"
        eval "$(uvx --generate-shell-completion bash)"
    fi
fi
unset _shell
