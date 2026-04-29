# awsvpnctl

macOS에서 AWS Client VPN(SAML SSO)을 CLI, LaunchAgent, Hammerspoon 메뉴바로 제어하는 도구예요.

공식 AWS VPN Client.app을 계속 띄워두는 대신 OpenVPN을 직접 실행하고, LaunchAgent 데몬이 AWS SSO 로그인과 VPN 상태를 보고 자동으로 연결해요. 화면 잠금이나 유휴 상태에서도 연결 유지가 더 예측 가능하도록 구성해요.

Hammerspoon을 쓰면 선택 메뉴바 통합도 붙일 수 있어요. 메뉴바는 `awsvpnctl status --json`과 같은 상태 정보를 읽어서 실제 연결 상태와 connect/disconnect 액션을 보여줘요.

## Quick Start

처음 쓰는 macOS 사용자는 Homebrew 설치 흐름을 기준으로 시작해요.

```bash
aws sso login --sso-session <name>
brew tap seunghwanly/awsvpnctl https://github.com/seunghwanly/awsvpnctl.git
brew install awsvpnctl
awsvpnctl setup
awsvpnctl doctor
awsvpnctl connect <profile_name>
awsvpnctl status
```

`<name>`은 `~/.aws/config`의 `[sso-session ...]` 블록 이름이에요. `<profile_name>`은 `setup`에서 가져온 `.ovpn` 파일 이름을 기준으로 정해요. 예를 들어 `dev.ovpn`으로 가져오면 `awsvpnctl connect dev`를 써요.

`awsvpnctl setup`은 필요한 OpenVPN, 제한된 sudoers, LaunchAgent를 설치한 뒤 `~/Downloads`와 `~/Desktop`에서 AWS Client VPN export로 보이는 `.ovpn` 파일을 찾아 `etc/profiles/`로 가져와요. 자동 연결할 프로필도 이때 설정해요.

파일 후보만 확인하고 가져오지 않으려면 `awsvpnctl setup --skip-import`를 사용해요.

## Basic Usage

```bash
awsvpnctl list
awsvpnctl connect <profile_name>
awsvpnctl status
awsvpnctl disconnect <profile_name>
awsvpnctl remove <profile_name>
awsvpnctl logs <profile_name> -f
```

자동 연결은 AWS SSO 로그인 후 동작해요.

```bash
aws sso login --sso-session <name>
```

사용 가능한 SSO session 이름은 아래처럼 확인해요.

```bash
grep '^\[sso-session' ~/.aws/config
```

## Development Checkout

소스 코드를 직접 수정하거나 기여할 때만 git checkout으로 설치해요.

```bash
git clone git@github.com:seunghwanly/awsvpnctl.git ~/dev/awsvpnctl
cd ~/dev/awsvpnctl
./bin/awsvpnctl setup
./bin/awsvpnctl doctor
```

개발용 checkout은 `~/dev/awsvpnctl`처럼 macOS privacy 제한을 덜 받는 경로를 권장해요.

## Documentation

자세한 설치, 설정, 보안 모델, 트러블슈팅은 GitBook 문서 구조의 [docs/](docs/README.md)를 봐요.

시작점:

- [Installation](docs/install.md)
- [Homebrew](docs/homebrew.md)
- [Initial Setup](docs/setup.md)
- [Profiles](docs/profiles.md)
- [Auto Reconnect](docs/auto-reconnect.md)
- [Troubleshooting](docs/troubleshooting.md)

## Repository Layout

```text
awsvpnctl/
├── bin/                         # CLI and restricted sudo runner
├── docs/                        # GitBook documentation
├── etc/                         # local config example and profiles directory
├── Formula/                     # Homebrew tap formulae
├── hammerspoon/                 # menu bar integration
├── share/                       # LaunchAgent and sudoers templates
├── var/run/                     # local runtime state, ignored by git
└── log/                         # local logs, ignored by git
```

## Safety

User VPN profiles, generated runtime configs, logs, and `etc/config.json` are ignored by git. `.ovpn` 파일은 커밋하지 않아요.
