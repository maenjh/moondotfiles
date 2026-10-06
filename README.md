# moondotfiles

Linux 서버와 macOS에서 같은 셸 환경을 만드는 최소 dotfiles입니다.

- **uv** 설치 (`~/.local/bin`, rc 파일은 건드리지 않음)
- **uv tools** 설치: `uv/tools.txt` 목록 (nvitop, poetry, mypy, pre-commit …)
- **PATH** 관리: 중복 없이, 존재하는 디렉터리만, 우선순위대로
- **zsh**: oh-my-zsh + spaceship 프롬프트 + autosuggestions / syntax-highlighting / completions
- **alias**: docker, cd(workspace 이동, clone 후 이동)
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
| `--no-uv` / `--no-tools` / `--no-zsh` / `--no-shell` | 해당 단계 건너뛰기 |
| `--force` | `uv tool install --force` (pipx 등이 남긴 실행 파일 덮어쓰기) |
| `--uninstall` | rc 파일에서 블록 제거 (uv tools는 그대로) |

업데이트: `dots-update` (= `git pull` 후 `install.sh` 재실행)

## 구조

```
install.sh                      설치 스크립트
uv/tools.txt                    uv tool 목록 ([linux]/[macos] 태그 지원)
config/spaceship.zsh            spaceship 프롬프트 설정
shell/init.sh                   rc 파일이 source하는 진입점
shell/rc.d/10-path.sh           PATH 함수와 기본 PATH 순서
shell/rc.d/20-env.sh            로케일, EDITOR
shell/rc.d/30-aliases.sh        gpu, dots-update, cd·docker alias
shell/rc.d/40-tools.sh          direnv 훅, bash용 uv 자동완성
shell/zsh.d/10-completions.zsh  fpath: brew, zsh-completions, 생성된 자동완성
shell/zsh.d/20-oh-my-zsh.zsh    oh-my-zsh 테마·플러그인 로드
examples/local.sh               머신별 설정 예시
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

## zsh

`install.sh`가 없을 때만 shallow clone합니다 (zsh가 없으면 건너뜀):

- `~/.oh-my-zsh` — [ohmyzsh](https://github.com/ohmyzsh/ohmyzsh)
- `custom/themes/spaceship` — [spaceship-prompt](https://github.com/spaceship-prompt/spaceship-prompt), 설정은 `config/spaceship.zsh`
- `custom/plugins/` — zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions

oh-my-zsh 플러그인: `git git-prompt docker docker-compose sudo dotenv colorize` + 위 외부 플러그인.

uv, uvx, poetry, poe 자동완성은 `~/.cache/moondotfiles/completions/`에 파일로 만들어 두고, 도구가 업그레이드됐을 때만 다시 만듭니다.

로그인 셸이 zsh가 아니면 `chsh -s "$(command -v zsh)"`. Linux에 zsh가 없으면 `sudo apt install zsh` 후 `install.sh`를 다시 실행합니다.

## alias

| cd | |
|---|---|
| `cdw` | `$WORKSPACE_HOME` (기본 `~/workspace`) |
| `cdp [이름]` / `cdr [이름]` / `cdc [이름]` | `projects/` / `references/` / `containers/` 아래로 |
| `gcdp REPO` / `gcdr REPO` | projects / references에 clone하고 이동 |
| `cddot` | 이 dotfiles 레포 |
| `mcd DIR` | `mkdir -p` 후 이동 |

| docker | |
|---|---|
| `dki` `dkls`/`dkl` `dkirm` | `docker image`, `image ls`, `image rm` |
| `dkps` `dkcls` | `docker ps`, `container ls -a` |
| `deit`/`dkx`/`dkex` | `docker exec -it` |
| `dkc` `dkcb` `dkcu` `dkcr` `dkcc` | compose, build/up/run/config (`dk-compose`가 있으면 그것을 사용) |

`WORKSPACE_*` 경로는 `local.d`에서 바꿀 수 있습니다.

## uv tools

`uv/tools.txt`에 한 줄씩 적습니다. 이름 뒤는 `uv tool install`에 그대로 전달됩니다.

```
[linux] nvitop
mypy --with setuptools
```

`[linux]` / `[macos]`로 플랫폼을 제한할 수 있습니다. nvitop은 NVIDIA GPU가 있는 Linux에서만 설치됩니다. 설치 후 업그레이드는 `uv tool upgrade --all`.
