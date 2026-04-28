# Hammerspoon Menu Bar

Hammerspoon integration은 메뉴바에서 실제 VPN 연결 상태를 보여주고 connect/disconnect 액션을 제공합니다.

## Setup

`install.sh`는 `/Applications/Hammerspoon.app`이 설치되어 있어야만 메뉴바를 연결합니다. 앱이 없으면 메뉴바 단계는 자동으로 건너뛰어집니다.

### Option 1. installer가 한 번에 설치

source checkout:

```bash
./install.sh --with-hammerspoon
```

Homebrew:

```bash
awsvpnctl-install --with-hammerspoon
```

`Hammerspoon.app`이 없으면 `brew install --cask hammerspoon`을 실행해 설치한 뒤, 메뉴바 symlink와 `init.lua` 등록까지 자동으로 진행합니다. 이미 설치되어 있으면 cask 단계는 건너뜁니다.

### Option 2. Hammerspoon만 먼저 설치

```bash
brew install --cask hammerspoon
./install.sh                  # 또는 awsvpnctl-install
```

`install.sh`가 두 번째 실행에서 메뉴바 symlink와 `init.lua` 항목을 추가합니다.

### Skip menubar setup

이미 Hammerspoon을 다른 용도로 쓰고 있어 awsvpnctl 메뉴바를 붙이고 싶지 않다면:

```bash
./install.sh --no-hammerspoon
```

### What gets installed

`install.sh`가 메뉴바를 연결할 때 만드는 것:

```text
~/.hammerspoon/awsvpnctl_hammerspoon.lua -> hammerspoon/awsvpnctl_hammerspoon.lua
```

그리고 `~/.hammerspoon/init.lua`에 다음 줄을 추가합니다 (이미 있으면 건너뜁니다).

```lua
require("awsvpnctl_hammerspoon")
```

설치 직후 `osascript`로 Hammerspoon에 reload 신호를 보냅니다. AppleScript 권한이 막혀 있으면 사용자가 직접 Hammerspoon → `Reload Config`를 실행해야 합니다.

### Permissions

Hammerspoon은 첫 실행 시 macOS Accessibility 권한을 요청합니다. `시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용`에서 Hammerspoon을 허용해야 메뉴바와 reload가 정상 동작합니다.

### Verify

```bash
awsvpnctl doctor
```

`hammerspoon menubar` 항목이 `→ /.../hammerspoon/awsvpnctl_hammerspoon.lua`로 표시되면 연결이 성공한 상태입니다.

## Status Source

메뉴바는 `awsvpnctl status --json`을 polling합니다. AWS config나 profile 파일 존재 여부가 아니라 실제 OpenVPN process와 `utun` 상태를 봅니다.

## Menu Title

예:

```text
DEV PRD      # 연결됨
VPN          # 모두 끊김
connect dev  # 작업 중
```

실제 화면에서는 연결/끊김/작업 중 상태를 구분하는 아이콘도 함께 표시됩니다.

## Actions

- Connect dev
- Connect prd
- Connect dev + prd
- Connect all
- Disconnect all
- Refresh
- Tail daemon log
- Reload Hammerspoon

## Reload

AppleScript reload가 막혀 있으면 Hammerspoon 앱에서 직접 `Reload Config`를 실행합니다.

```bash
killall Hammerspoon
open -a Hammerspoon
```
