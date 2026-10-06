# Aliases and small functions shared by zsh and bash.

alias paths="path_show"

# GPU monitor on servers; falls back to uvx when nvitop is not installed.
if command -v nvitop >/dev/null 2>&1; then
    alias gpu="nvitop"
else
    alias gpu="uvx nvitop"
fi

# refreshenv: restart the current shell to pick up config changes.
refreshenv() {
    exec "$(ps -p $$ -o comm= | sed 's/^-//')"
}

# dots-update: pull the latest dotfiles and re-run the installer.
dots-update() {
    git -C "$DOTFILES" pull --ff-only && "$DOTFILES/install.sh" "$@"
}

# --- cd -----------------------------------------------------------------

export WORKSPACE_HOME="${WORKSPACE_HOME:-$HOME/workspace}"
export WORKSPACE_PROJECT_DIR="${WORKSPACE_PROJECT_DIR:-$WORKSPACE_HOME/projects}"
export WORKSPACE_REFERENCE_DIR="${WORKSPACE_REFERENCE_DIR:-$WORKSPACE_HOME/references}"
export WORKSPACE_CONTAINER_DIR="${WORKSPACE_CONTAINER_DIR:-$WORKSPACE_HOME/containers}"

alias cdw='cd "$WORKSPACE_HOME"'
alias cddot='cd "$DOTFILES"'

# mcd DIR: mkdir -p and cd into it.
mcd() {
    mkdir -p "$1" && cd "$1" || return
}

# cdp/cdr/cdc [NAME]: cd into a project, reference, or container directory.
cdp() { cd "$WORKSPACE_PROJECT_DIR/${1:-}" || return; }
cdr() { cd "$WORKSPACE_REFERENCE_DIR/${1:-}" || return; }
cdc() { cd "$WORKSPACE_CONTAINER_DIR/${1:-}" || return; }

# _git_clone_cd PARENT REPO: clone REPO under PARENT and cd into it.
_git_clone_cd() {
    _dir="${2##*/}"
    _dir="${_dir%.git}"
    mkdir -p "$1" &&
        command git clone "$2" "$1/$_dir" &&
        cd "$1/$_dir" || return
}

# gcdp/gcdr REPO: clone into projects/references and cd into it.
gcdp() { _git_clone_cd "$WORKSPACE_PROJECT_DIR" "$1"; }
gcdr() { _git_clone_cd "$WORKSPACE_REFERENCE_DIR" "$1"; }

# --- docker -------------------------------------------------------------

alias dki="docker image"
alias dkls="docker image ls"
alias dkl="dkls"
alias dkirm="docker image rm"
alias dkps="docker ps"
alias dkcls="docker container ls -a"
alias deit="docker exec -it"
alias dkx="deit"
alias dkex="deit"

# Compose aliases use the dk-compose wrapper when installed, plain compose otherwise.
if command -v dk-compose >/dev/null 2>&1; then
    _compose="dk-compose"
else
    _compose="docker compose"
fi
# Expanding $_compose at definition time is intended.
# shellcheck disable=SC2139
{
    alias dkc="$_compose"
    alias dkcb="$_compose build"
    alias dkcu="$_compose up"
    alias dkcr="$_compose run"
    alias dkcc="$_compose config"
}
unset _compose
