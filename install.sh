#!/usr/bin/env bash
# Bootstrap uv, uv tools, and PATH setup on Linux servers and macOS.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_FILE="${DOTFILES_TOOLS_FILE:-$DOTFILES_DIR/uv/tools.txt}"
BLOCK_BEGIN="# >>> dotfiles >>>"
BLOCK_END="# <<< dotfiles <<<"

DRY_RUN=0
INSTALL_UV=1
INSTALL_TOOLS=1
SETUP_SHELL=1
FORCE=0
UNINSTALL=0

usage() {
    cat <<EOF
Usage: ./install.sh [options]

  --no-uv        skip installing uv
  --no-tools     skip installing tools from uv/tools.txt
  --no-shell     skip editing ~/.zshrc and ~/.bashrc
  --force        pass --force to 'uv tool install' (overwrite stale executables)
  --uninstall    remove the dotfiles block from shell rc files
  --dry-run      print what would happen without changing anything
  -h, --help     show this help
EOF
}

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '  + %s\n' "$*"
    else
        "$@"
    fi
}

detect_os() {
    case "$(uname -s)" in
        Darwin) OS=macos ;;
        Linux) OS=linux ;;
        *) die "unsupported OS: $(uname -s)" ;;
    esac
}

install_uv() {
    export PATH="$HOME/.local/bin:$PATH"
    if command -v uv >/dev/null 2>&1; then
        log "uv found: $(command -v uv) ($(uv --version))"
        return
    fi

    log "installing uv into ~/.local/bin"
    local installer="https://astral.sh/uv/install.sh"
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '  + curl -LsSf %s | UV_NO_MODIFY_PATH=1 sh\n' "$installer"
        return
    fi
    # PATH is managed by shell/path.sh, so stop the installer from editing rc files.
    if command -v curl >/dev/null 2>&1; then
        curl -LsSf "$installer" | env UV_NO_MODIFY_PATH=1 sh
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "$installer" | env UV_NO_MODIFY_PATH=1 sh
    else
        die "curl or wget is required to install uv"
    fi
    command -v uv >/dev/null 2>&1 || die "uv install finished but uv is not on PATH"
    log "uv installed: $(uv --version)"
}

install_tools() {
    [ -f "$TOOLS_FILE" ] || die "tools file not found: $TOOLS_FILE"
    if ! command -v uv >/dev/null 2>&1; then
        [ "$DRY_RUN" -eq 1 ] || die "uv is not installed; run without --no-uv"
    fi

    local line platform failed=()
    local -a args
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%%#*}"
        read -r -a args <<<"$line"
        [ "${#args[@]}" -gt 0 ] || continue

        case "${args[0]}" in
            "[linux]" | "[macos]")
                platform="${args[0]//[\[\]]/}"
                args=("${args[@]:1}")
                if [ "$platform" != "$OS" ]; then
                    log "skip ${args[0]} (only on $platform)"
                    continue
                fi
                ;;
        esac

        [ "$FORCE" -eq 1 ] && args+=(--force)
        log "uv tool install ${args[*]}"
        if ! run uv tool install "${args[@]}"; then
            warn "failed: ${args[0]}"
            failed+=("${args[0]}")
        fi
    done <"$TOOLS_FILE"

    if [ "${#failed[@]}" -gt 0 ]; then
        warn "tools that failed to install: ${failed[*]}"
        warn "if the error mentions existing executables, rerun with --force"
        return 1
    fi
}

# Print rc file contents with any existing dotfiles block removed.
strip_block() {
    awk -v begin="$BLOCK_BEGIN" -v end="$BLOCK_END" '
        $0 == begin { skip = 1; next }
        $0 == end { skip = 0; next }
        !skip { print }
    ' "$1"
}

write_rc() {
    local rc="$1" content="$2"
    if [ -f "$rc" ] && [ "$(cat "$rc")" = "$content" ]; then
        log "$rc is up to date"
        return
    fi
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '  + update %s\n' "$rc"
        return
    fi
    if [ -f "$rc" ]; then
        local backup
        backup="$rc.bak-dotfiles-$(date +%Y%m%d%H%M%S)"
        cp "$rc" "$backup"
        log "backed up $rc -> $backup"
    fi
    printf '%s\n' "$content" >"$rc"
    log "updated $rc"
}

setup_shell() {
    local rc content
    for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
        content=""
        [ -f "$rc" ] && content="$(strip_block "$rc")"
        # Append last so our PATH wins over anything set earlier in the file.
        content="${content:+$content
}$BLOCK_BEGIN
export DOTFILES=\"$DOTFILES_DIR\"
[ -f \"\$DOTFILES/shell/init.sh\" ] && . \"\$DOTFILES/shell/init.sh\"
$BLOCK_END"
        write_rc "$rc" "$content"
    done
}

uninstall_shell() {
    local rc
    for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
        [ -f "$rc" ] || continue
        if grep -qxF "$BLOCK_BEGIN" "$rc"; then
            write_rc "$rc" "$(strip_block "$rc")"
        fi
    done
}

main() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --no-uv) INSTALL_UV=0 ;;
            --no-tools) INSTALL_TOOLS=0 ;;
            --no-shell) SETUP_SHELL=0 ;;
            --force) FORCE=1 ;;
            --uninstall) UNINSTALL=1 ;;
            --dry-run) DRY_RUN=1 ;;
            -h | --help) usage; exit 0 ;;
            *) usage >&2; die "unknown option: $1" ;;
        esac
        shift
    done

    detect_os
    log "OS: $OS, dotfiles: $DOTFILES_DIR"

    if [ "$UNINSTALL" -eq 1 ]; then
        uninstall_shell
        log "removed shell setup; uv tools are untouched (see 'uv tool list')"
        return
    fi

    local status=0
    [ "$INSTALL_UV" -eq 1 ] && install_uv
    if [ "$INSTALL_TOOLS" -eq 1 ]; then
        install_tools || status=1
    fi
    [ "$SETUP_SHELL" -eq 1 ] && setup_shell

    log "done. open a new shell or run: exec \$SHELL"
    return "$status"
}

main "$@"
