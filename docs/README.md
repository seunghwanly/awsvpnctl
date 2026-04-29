# awsvpnctl

awsvpnctl은 macOS에서 AWS Client VPN(SAML SSO)을 안정적으로 연결하고 자동 재연결하기 위한 로컬 도구예요.

공식 AWS VPN Client.app을 계속 띄워두는 대신, AWS Client VPN의 SAML 인증 흐름을 OpenVPN으로 처리하고 LaunchAgent 데몬이 상태를 감시해요. AWS SSO로 로그인하면 자동 연결할 프로필을 붙이고, VPN이 끊기면 다시 연결해요.

Hammerspoon은 선택 메뉴바 통합이에요. 메뉴바는 `awsvpnctl status --json`과 같은 상태 정보를 읽어서 실제 OpenVPN process와 `utun` 연결 상태를 보여주고, 수동 connect/disconnect 액션도 제공해요.

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

`<name>`은 `~/.aws/config`의 `[sso-session ...]` 블록 이름이에요. `<profile_name>`은 `setup`에서 가져온 `.ovpn` 파일 이름을 기준으로 정해요. 예를 들어 `dev.ovpn`이면 `awsvpnctl connect dev`를 써요.

## What It Does

- `etc/profiles/*.ovpn`에서 VPN endpoint 설정을 읽어요.
- 브라우저 SSO 로그인으로 SAML 응답을 받아 OpenVPN 인증에 사용해요.
- 각 VPN profile을 독립 OpenVPN 프로세스와 `utun` 인터페이스로 실행해요.
- LaunchAgent 데몬이 AWS SSO token 변경과 VPN drop을 감지해 자동 연결해요.
- Hammerspoon 메뉴바가 setup에서 기록한 CLI 경로로 `status --json`을 polling해요.

## Requirements

- macOS
- Homebrew
- AWS Client VPN `.ovpn` profile
- AWS SSO browser session
- 선택 사항: Hammerspoon

## Key Concepts

- **Profile**: `etc/profiles/<name>.ovpn` 파일 하나가 awsvpnctl profile 하나예요.
- **auto_connect**: `etc/config.json`의 자동 연결 대상 목록이에요.
- **Daemon**: LaunchAgent로 실행되는 `awsvpnctl daemon`이에요.
- **SAML listener**: 브라우저가 POST하는 SAMLResponse를 `127.0.0.1:35001`에서 받아요.

다음 장은 [Installation](install.md)이에요. Homebrew 상세 정보만 필요하면 [Homebrew](homebrew.md)를 봐요.
