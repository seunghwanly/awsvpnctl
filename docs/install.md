# Installation

## Homebrew Install

권장 설치 방법입니다.

```bash
brew tap seunghwanly/awsvpnctl https://github.com/seunghwanly/awsvpnctl.git
brew install awsvpnctl
awsvpnctl-install
awsvpnctl setup
awsvpnctl doctor
```

자세한 내용은 [Homebrew](homebrew.md)를 봅니다.

## Source Checkout

```bash
git clone git@github.com:seunghwanly/awsvpnctl.git ~/dev/awsvpnctl
cd ~/dev/awsvpnctl
```

`~/dev/awsvpnctl` 경로를 권장합니다. macOS는 `~/Documents`, `~/Desktop`, `~/Downloads`에 대해 background process 접근을 더 엄격하게 막을 수 있습니다.

## Run Source Installer

```bash
./install.sh
```

설치 스크립트는 사전 점검을 출력하고, 필요한 작업 계획을 보여준 뒤 확인을 받고 진행합니다. 다시 실행해도 이미 완료된 단계는 건너뜁니다.

## Installer Options

```bash
./install.sh --check       # 점검만 실행
./install.sh --yes         # 확인 프롬프트 생략
./install.sh --no-path     # shell rc PATH 추가 생략
./install.sh --uninstall   # sudoers, LaunchAgent, Hammerspoon symlink 제거
```

## What Install Does

1. OpenVPN AWS SAML patch 빌드 또는 확인
2. AWS Client VPN export로 보이는 `.ovpn` profile 자동 탐색 및 복사
3. `etc/config.json` 생성 또는 갱신
4. 제한된 passwordless sudoers 설치
5. LaunchAgent 설치 및 로드
6. Hammerspoon 메뉴바 symlink 연결
7. shell rc에 `bin/` PATH 추가

## Homebrew Caveats

Homebrew formula는 설치 완료 후 다음 흐름을 콘솔에 안내합니다.

```bash
cd /path/to/awsvpnctl
./install.sh
awsvpnctl setup
awsvpnctl doctor
```

## Verify

```bash
awsvpnctl doctor
```

정상 상태에서는 openvpn binary, passwordless sudo, auto-reconnect daemon, VPN profiles, AWS SSO config/token 상태가 표시됩니다.
