# Installation

## Homebrew Install

권장 설치 방법입니다.

```bash
brew tap seunghwanly/awsvpnctl https://github.com/seunghwanly/awsvpnctl.git
brew install awsvpnctl
awsvpnctl setup
awsvpnctl doctor
```

`setup`은 첫 실행에서 필요한 시스템 구성까지 처리합니다.

## Source Checkout

```bash
git clone git@github.com:seunghwanly/awsvpnctl.git ~/dev/awsvpnctl
cd ~/dev/awsvpnctl
./bin/awsvpnctl setup
awsvpnctl doctor
```

`~/dev/awsvpnctl` 경로를 권장합니다. macOS는 `~/Documents`, `~/Desktop`, `~/Downloads`에 대해 background process 접근을 더 엄격하게 막을 수 있습니다.

## What Setup Does

1. patched OpenVPN 존재 여부 확인 및 설치
2. 제한된 passwordless sudoers 설치
3. LaunchAgent 설치 및 로드
4. 선택 시 Hammerspoon.app 설치 및 메뉴바 연결
5. `.ovpn` profile 선택 import
6. `etc/config.json` 자동 연결 목록 갱신
7. source checkout이면 shell rc에 `bin/` PATH 추가

sudo가 필요한 이유는 OpenVPN이 `utun` 인터페이스와 route를 만들 때 root 권한이 필요하기 때문입니다. 설치되는 sudoers rule은 `aws-vpn-sudo-runner`만 허용하며 전체 sudo 권한을 열지 않습니다.

## Setup Options

```bash
awsvpnctl setup --yes                   # 기본값으로 비대화형 진행
awsvpnctl setup --skip-system-install   # OpenVPN/sudoers/LaunchAgent/PATH 설치 생략
awsvpnctl setup --with-hammerspoon      # Hammerspoon.app 설치 후 메뉴바 연결
awsvpnctl setup --no-hammerspoon        # Hammerspoon 설치/연결 생략
awsvpnctl setup --skip-import           # .ovpn 후보만 확인하고 import 생략
```

## Verify

```bash
awsvpnctl doctor
```

정상 상태에서는 openvpn binary, passwordless sudo, auto-reconnect daemon, VPN profiles, AWS SSO config/token 상태가 표시됩니다. 실패 항목이 있으면 `awsvpnctl setup`을 다시 실행합니다.
