#!/bin/sh
# Bootstrap: install chezmoi into ~/.local/bin if needed, then apply this repo.
#   ./install.sh                  use this checkout as the chezmoi source
#   ./install.sh --dry-run -v     preview; any extra args go to `chezmoi init --apply`
set -eu

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

if ! command -v chezmoi >/dev/null 2>&1; then
    echo "==> installing chezmoi into $BIN_DIR"
    if command -v curl >/dev/null 2>&1; then
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$BIN_DIR"
    elif command -v wget >/dev/null 2>&1; then
        sh -c "$(wget -qO- get.chezmoi.io)" -- -b "$BIN_DIR"
    else
        echo "error: curl or wget is required" >&2
        exit 1
    fi
fi

exec chezmoi init --apply --source "$REPO_DIR" "$@"
