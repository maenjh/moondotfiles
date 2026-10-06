# zsh completions. Reuses compinit if oh-my-zsh or an earlier rc already ran it.

if (( $+commands[brew] )); then
    fpath+=("$(brew --prefix)/share/zsh/site-functions")
fi

if ! (( $+functions[compdef] )); then
    autoload -Uz compinit && compinit -u
fi

if (( $+commands[uv] )); then
    eval "$(uv generate-shell-completion zsh)"
    eval "$(uvx --generate-shell-completion zsh)"
fi
