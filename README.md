# awsvpnctl

macOS에서 AWS Client VPN(SAML SSO)을 CLI, LaunchAgent, Hammerspoon 메뉴바로 제어하는 도구입니다.

`aws sso login` 후 자동 연결하고, VPN이 끊기면 데몬이 다시 연결합니다. 공식 AWS VPN Client.app 대신 OpenVPN을 직접 실행해 화면 잠금/유휴 상태에서도 연결 유지가 더 예측 가능하도록 구성합니다.

## Quick Start

Homebrew:

```bash
brew tap seunghwanly/awsvpnctl https://github.com/seunghwanly/awsvpnctl.git
brew install awsvpnctl
awsvpnctl-install
awsvpnctl setup
awsvpnctl doctor
```

Source checkout:

```bash
git clone git@github.com:seunghwanly/awsvpnctl.git ~/dev/awsvpnctl
cd ~/dev/awsvpnctl
./install.sh
awsvpnctl setup
awsvpnctl doctor
```

`awsvpnctl setup`은 `~/Downloads`와 `~/Desktop`에서 AWS Client VPN export로 보이는 `.ovpn` 파일을 찾아 `etc/profiles/`로 가져오고, 자동 연결할 프로필을 설정합니다.
파일 후보만 확인하고 가져오지 않으려면 `awsvpnctl setup --skip-import`를 사용합니다.

## Basic Usage

```bash
awsvpnctl list
awsvpnctl connect dev
awsvpnctl status
awsvpnctl disconnect dev
awsvpnctl remove dev
awsvpnctl logs dev -f
```

자동 연결은 AWS SSO 로그인 후 동작합니다.

```bash
aws sso login --sso-session <name>
```

`<name>`은 `~/.aws/config`의 `[sso-session ...]` 블록 이름입니다. `grep '^\[sso-session' ~/.aws/config`로 사용 가능한 이름을 확인합니다.

## Documentation

자세한 설치, 설정, 보안 모델, 트러블슈팅은 GitBook 문서 구조의 [docs/](docs/README.md)를 봅니다.

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

User VPN profiles, generated runtime configs, logs, and `etc/config.json` are ignored by git. Do not commit `.ovpn` files.
