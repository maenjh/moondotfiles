# moondotfiles

Linux 서버와 macOS에서 같은 셸 환경을 만드는 최소 dotfiles입니다.

- **uv** 설치 (`~/.local/bin`, rc 파일은 건드리지 않음)
- **uv tools** 설치: `uv/tools.txt` 목록 (nvitop, poetry, mypy, pre-commit …)
- **PATH** 관리: 중복 없이, 존재하는 디렉터리만, 우선순위대로
- zsh/bash 공통 설정 조각(`shell/rc.d/`) + zsh 전용(`shell/zsh.d/`)

## 설치

```sh
git clone https://github.com/maenjh/moondotfiles.git ~/moondotfiles
~/moondotfiles/install.sh
exec $SHELL
```

`install.sh`는 여러 번 실행해도 안전합니다. `~/.zshrc`와 `~/.bashrc` 끝에 아래 블록 하나만 추가하고(이미 있으면 갱신), 바꾸기 전에 `*.bak-dotfiles-<시각>` 백업을 만듭니다.

```sh
# >>> dotfiles >>>
export DOTFILES="/path/to/dotfiles"
[ -f "$DOTFILES/shell/init.sh" ] && . "$DOTFILES/shell/init.sh"
# <<< dotfiles <<<
```

| 옵션 | 설명 |
|---|---|
| `--dry-run` | 바꾸지 않고 할 일만 출력 |
| `--no-uv` / `--no-tools` / `--no-shell` | 해당 단계 건너뛰기 |
| `--force` | `uv tool install --force` (pipx 등이 남긴 실행 파일 덮어쓰기) |
| `--uninstall` | rc 파일에서 블록 제거 (uv tools는 그대로) |

업데이트: `dots-update` (= `git pull` 후 `install.sh` 재실행)

## 구조

```
install.sh                 설치 스크립트
uv/tools.txt               uv tool 목록 ([linux]/[macos] 태그 지원)
shell/init.sh              rc 파일이 source하는 진입점
shell/rc.d/10-path.sh      PATH 함수와 기본 PATH 순서
shell/rc.d/20-env.sh       로케일, EDITOR
shell/rc.d/30-aliases.sh   gpu, mcd, refreshenv, dots-update, paths
shell/rc.d/40-tools.sh     direnv 훅, bash용 uv 자동완성
shell/zsh.d/10-completions.zsh  compinit, zsh용 uv 자동완성
examples/local.sh          머신별 설정 예시
```

## PATH

우선순위 (위가 먼저 검색됨):

1. `~/.config/dotfiles/local.d/*.sh`에서 추가한 경로
2. `~/.local/bin` — uv, uv tools
3. `~/.cargo/bin`, `~/go/bin`
4. Homebrew (`/opt/homebrew`, `/usr/local`, Linuxbrew)
5. 기존 시스템 PATH
6. `/usr/local/cuda/bin` (맨 뒤에 추가)

함수:

- `path_prepend DIR...` — 맨 앞으로 (이미 있으면 앞으로 이동)
- `path_append DIR...` — 없을 때만 맨 뒤에 추가
- `paths` — PATH를 한 줄씩 출력, 없는 디렉터리는 `!` 표시

머신별 경로는 git에 넣지 말고 `~/.config/dotfiles/local.d/`에 둡니다:

```sh
mkdir -p ~/.config/dotfiles/local.d
cp ~/moondotfiles/examples/local.sh ~/.config/dotfiles/local.d/50-local.sh
```

## uv tools

`uv/tools.txt`에 한 줄씩 적습니다. 이름 뒤는 `uv tool install`에 그대로 전달됩니다.

```
[linux] nvitop
mypy --with setuptools
```

`[linux]` / `[macos]`로 플랫폼을 제한할 수 있습니다. nvitop은 NVIDIA GPU가 있는 Linux에서만 설치됩니다. 설치 후 업그레이드는 `uv tool upgrade --all`.
