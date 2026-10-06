# moondotfiles

Linux 서버와 macOS에서 같은 셸 환경을 만드는 [chezmoi](https://www.chezmoi.io/) dotfiles입니다.

- **시스템 패키지**: apt / snap (sudo 있을 때), Homebrew (macOS, 또는 쓰기 가능한 Linuxbrew)
- **uv + uv tools**: nvitop, poetry, mypy, pre-commit …
- **zsh**: oh-my-zsh + spaceship 프롬프트 + autosuggestions / syntax-highlighting / completions, 기본 셸로 설정
- **환경변수**: 이름·이메일·GitHub·workspace 경로 등 chezmoi 데이터로 렌더링
- **PATH**: 중복 없이, 존재하는 디렉터리만, 우선순위대로
- **자동완성**: uv, uvx, poetry, poe, chezmoi, gh, docker, task, yq, kubectl (zsh + bash)
- **alias**: docker, cd, chezmoi

## 설치

```sh
git clone https://github.com/maenjh/moondotfiles.git ~/moondotfiles
~/moondotfiles/install.sh
```

`install.sh`는 chezmoi가 없으면 `~/.local/bin`에 설치한 뒤 `chezmoi init --apply --source ~/moondotfiles`를 실행합니다. 처음 한 번 다음을 묻습니다 (답은 `~/.config/chezmoi/chezmoi.yaml`에 저장):

| 질문 | 데이터 키 | 기본값 |
|---|---|---|
| Full name / Email / GitHub username | `name`, `email`, `github_username` | |
| Workspace directory | `workspace_home` | `~/workspace` |
| Package scope (minimal/system/full) | `package_scope` | `minimal` |
| Can you use sudo here | `is_sudoer` | sudo/admin/wheel 그룹이면 yes |
| Make zsh the default shell | `default_zsh` | yes |

미리보기: `./install.sh --dry-run --verbose` 또는 `DOTFILES_DRY_RUN=1 chezmoi apply` (스크립트가 명령만 출력).

## 일상 사용

| 명령 | |
|---|---|
| `chezmoi update` (`dotu`) | git pull + apply |
| `chezmoi apply` (`czma`) | 레포 변경 적용 |
| `chezmoi diff` (`czmd`) | 적용 전 차이 보기 |
| `chezmoi edit ~/.zshrc` (`czme`) | 소스 파일 편집 |
| `chezmoi apply --refresh-externals` | oh-my-zsh·플러그인 즉시 갱신 (기본은 주 1회) |
| `chezmoi init` | 새로 추가된 질문에 답하기 / 데이터 다시 렌더링 |

## 구조

```
install.sh                         chezmoi 설치 + init --apply
.chezmoiroot                       소스는 home/ 아래
home/
  .chezmoi.yaml.tmpl               init 질문 → ~/.config/chezmoi/chezmoi.yaml
  .chezmoidata/packages.yaml       apt / brew / brewcask / snap 패키지 목록
  .chezmoidata/uv_tools.yaml       uv tool 목록
  .chezmoidata/completions.yaml    자동완성 생성 명령 목록
  .chezmoiexternal.yaml            oh-my-zsh, spaceship, zsh 플러그인 (주 1회 갱신)
  .chezmoiremove                   이전 entelecheia 설정의 남은 파일 정리
  .chezmoiscripts/
    run_onchange_before_00-install-prerequisites   git, curl, zsh / Xcode CLT, Homebrew
    run_onchange_after_10-install-packages         시스템 패키지
    run_onchange_after_15-default-shell            로그인 셸을 zsh로
    run_onchange_after_20-install-uv-tools         uv + uv tools
  dot_zshrc.tmpl                   ~/.config/shrc/* → ~/.config/zshrc/* 로드
  dot_bashrc.tmpl                  ~/.config/shrc/* 로드, bash-completion, (필요 시) zsh로 전환
  dot_bash_profile                 로그인 bash → ~/.profile, ~/.bashrc
  dot_config/shrc/                 zsh + bash 공통
    00-dotfiles-export.tmpl        chezmoi 데이터 → 환경변수
    10-path                        path_prepend / path_append / path_show, 기본 PATH
    20-export                      로케일, EDITOR, GITHUB_TOKEN(gh), nvm/pyenv/rbenv/sdkman
    30-aliases                     gpu, chezmoi, cd, docker
    40-tools                       direnv
    50-completions.tmpl            자동완성 파일 생성 (도구가 바뀔 때만)
  dot_config/zshrc/                zsh 전용
    10-completions                 fpath (brew, zsh-completions, 생성된 자동완성)
    20-oh-my-zsh                   테마, 플러그인, compinit, bashcompinit
  dot_config/spaceship/spaceship.zsh
```

`run_onchange_` 스크립트는 내용(패키지 목록 해시 포함)이 바뀔 때만 다시 실행됩니다.

## 시스템 패키지

`home/.chezmoidata/packages.yaml`에 추가합니다.

```yaml
- { name: ripgrep, scope: minimal, cmd: rg, apt: true, brew: true }
- { name: fd, scope: full, cmd: fd, apt: fd-find, brew: true }   # 이름이 다르면 문자열로
- { name: task, scope: full, cmd: task, snap: "task --classic", brew: go-task }
- { name: gh, scope: minimal, cmd: gh, apt: true, apt_repo: github-cli, brew: true }
```

- `scope`: `minimal` < `system` (docker) < `full`. `package_scope` 이하만 설치
- `cmd`가 이미 PATH에 있으면 건너뜀. 다른 사람이 관리하는 서버에서도 안전
- Linux: sudo가 있으면 apt(+snap), 없으면 쓰기 가능한 Homebrew, 둘 다 없으면 빠진 목록만 출력
- macOS: Homebrew formula + cask
- `apt_repo`: 같은 파일의 `apt_repos`에 정의한 저장소(키링 + source list)를 먼저 추가

## 기본 셸

`default_zsh: true`이면:

1. `chsh`로 로그인 셸을 zsh로 바꿉니다 (sudo가 있으면 `sudo chsh`, 없으면 비밀번호 입력).
2. `chsh`가 안 되는 서버(LDAP 계정, 비밀번호 없음 등)에서는 `~/.bashrc`가 **최상위 bash일 때만** `exec zsh`로 넘어갑니다. zsh 안에서 직접 `bash`를 실행하면 bash에 그대로 머뭅니다.

일시적으로 끄려면 `MOONDOTFILES_NO_ZSH=1 bash -l`.

## 환경변수

`00-dotfiles-export`가 chezmoi 데이터로 렌더링합니다: `USER_FULLNAME`, `USER_EMAIL`, `GITHUB_USERNAME`, `WORKSPACE_HOME`과 `WORKSPACE_{PROJECT,REFERENCE,CONTAINER,MODEL,DATASET}_DIR`, `DOTFILES_DIR`, `DOTFILES_OS`, `SSH_HOME`, `GNUPGHOME`, `GPG_KEY_ID`, `SSH_PUB_KEY`, `AGE_KEY_FILE`/`SOPS_AGE_*` 등.

토큰·비밀번호는 파일에 쓰지 않습니다. `GITHUB_TOKEN`/`GH_TOKEN`은 셸 시작 시 `gh auth token`에서 가져옵니다.

## PATH

우선순위 (위가 먼저):

1. `~/.local/bin` — uv, uv tools
2. `~/.cargo/bin`, `~/go/bin`, pyenv/rbenv/gem
3. Homebrew (`/opt/homebrew`, `/usr/local`, Linuxbrew)
4. 시스템 PATH
5. `/usr/local/cuda/bin` (맨 뒤)

`path_prepend DIR`, `path_append DIR`, `paths`(한 줄씩 출력, 없는 디렉터리는 `!`).

## 머신별 설정

chezmoi가 관리하지 않는 이름으로 파일을 두면 함께 로드되고 덮어쓰이지 않습니다.

```sh
# ~/.config/shrc/90-local
path_prepend /opt/some-tool/bin
export CUDA_VISIBLE_DEVICES=0
```
