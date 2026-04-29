# awsvpnctl

awsvpnctl은 macOS에서 AWS Client VPN(SAML SSO)을 안정적으로 연결하고 자동 재연결하기 위한 로컬 도구입니다.

공식 AWS VPN Client.app을 직접 띄워두는 대신, AWS Client VPN의 SAML 인증 흐름을 OpenVPN으로 처리하고 LaunchAgent 데몬이 상태를 감시합니다. Hammerspoon 메뉴바를 쓰면 연결 상태를 실시간으로 보고 수동 connect/disconnect도 할 수 있습니다.

## What It Does

- `etc/profiles/*.ovpn`에서 VPN endpoint 설정을 읽습니다.
- 브라우저 SSO 로그인으로 SAML 응답을 받아 OpenVPN 인증에 사용합니다.
- 각 VPN profile을 독립 OpenVPN 프로세스와 `utun` 인터페이스로 실행합니다.
- LaunchAgent 데몬이 AWS SSO token 변경과 VPN drop을 감지해 자동 연결합니다.
- Hammerspoon 메뉴바가 setup에서 기록한 같은 `awsvpnctl status --json`을 읽어 실제 연결 상태를 보여줍니다.

## Quick Start

```bash
brew tap seunghwanly/awsvpnctl https://github.com/seunghwanly/awsvpnctl.git
brew install awsvpnctl
awsvpnctl setup
awsvpnctl doctor
```

이후 수동 연결:

```bash
awsvpnctl connect dev
```

자동 연결:

```bash
aws sso login --sso-session <name>
```

## Requirements

- macOS
- Homebrew
- AWS Client VPN `.ovpn` profile
- AWS SSO browser session
- 선택 사항: Hammerspoon

## Key Concepts

- **Profile**: `etc/profiles/<name>.ovpn` 파일 하나가 awsvpnctl profile 하나입니다.
- **auto_connect**: `etc/config.json`의 자동 연결 대상 목록입니다.
- **Daemon**: LaunchAgent로 실행되는 `awsvpnctl daemon`입니다.
- **SAML listener**: 브라우저가 POST하는 SAMLResponse를 `127.0.0.1:35001`에서 받습니다.

다음 장은 [Installation](install.md)입니다. Homebrew 설치만 필요하면 [Homebrew](homebrew.md)를 봅니다.
