# Installation

## Homebrew Install

기본 설치 경로는 Homebrew예요. 처음 쓰는 macOS 사용자는 아래 순서대로 진행해요.

```bash
aws sso login --sso-session <name>
brew tap seunghwanly/awsvpnctl https://github.com/seunghwanly/awsvpnctl.git
brew install awsvpnctl
awsvpnctl setup
awsvpnctl doctor
awsvpnctl connect <profile_name>
awsvpnctl status
```

`<name>`은 `~/.aws/config`의 `[sso-session ...]` 블록 이름이에요. `<profile_name>`은 `setup`에서 가져온 `.ovpn` 파일 이름을 기준으로 정해요.

`setup`은 첫 실행에서 필요한 시스템 구성까지 처리해요. OpenVPN, 제한된 sudoers, LaunchAgent를 확인하고, `~/Downloads`와 `~/Desktop`에서 AWS Client VPN export로 보이는 `.ovpn` 파일을 찾아 가져와요.

## What Setup Does

1. patched OpenVPN 존재 여부를 확인하고 필요하면 설치해요.
2. 제한된 passwordless sudoers를 설치해요.
3. LaunchAgent를 설치하고 로드해요.
4. 선택 시 Hammerspoon.app을 설치하고 메뉴바를 연결해요.
5. `.ovpn` profile을 선택해서 import해요.
6. `etc/config.json` 자동 연결 목록을 갱신해요.
7. source checkout이면 shell rc에 `bin/` PATH를 추가해요.

sudo가 필요한 이유는 OpenVPN이 `utun` 인터페이스와 route를 만들 때 root 권한이 필요하기 때문이에요. 설치되는 sudoers rule은 `aws-vpn-sudo-runner`만 허용하고 전체 sudo 권한을 열지 않아요.

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

정상 상태에서는 openvpn binary, passwordless sudo, auto-reconnect daemon, VPN profiles, AWS SSO config/token 상태가 보여요. 실패 항목이 있으면 `awsvpnctl setup`을 다시 실행해요.

## Development Install

소스 코드를 직접 수정하거나 기여할 때만 source checkout을 사용해요.

```bash
git clone git@github.com:seunghwanly/awsvpnctl.git ~/dev/awsvpnctl
cd ~/dev/awsvpnctl
./bin/awsvpnctl setup
./bin/awsvpnctl doctor
```

checkout 경로는 `~/dev/awsvpnctl`처럼 개발자가 직접 수정하기 좋은 위치를 권장해요. macOS는 `~/Documents`, `~/Desktop`, `~/Downloads`의 background process 접근을 더 엄격하게 막을 수 있어요.
