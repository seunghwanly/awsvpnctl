# Hammerspoon Menu Bar

Hammerspoon integration은 선택 기능이에요. 메뉴바에서 실제 VPN 연결 상태를 보여주고 connect/disconnect 액션을 제공해요.

## Setup

`awsvpnctl setup`은 Hammerspoon 메뉴바를 선택적으로 연결해요.

### Option 1. setup이 한 번에 설치

```bash
awsvpnctl setup --with-hammerspoon
```

`Hammerspoon.app`이 없으면 `brew install --cask hammerspoon`을 실행해 설치한 뒤, 메뉴바 symlink와 `init.lua` 등록까지 자동으로 진행해요. 이미 설치되어 있으면 cask 단계는 건너뛰어요.

### Option 2. Hammerspoon만 먼저 설치

```bash
brew install --cask hammerspoon
awsvpnctl setup
```

`setup`이 이미 설치된 Hammerspoon에 메뉴바 symlink와 `init.lua` 항목을 추가해요.

### Skip menubar setup

이미 Hammerspoon을 다른 용도로 쓰고 있어 awsvpnctl 메뉴바를 붙이고 싶지 않다면 아래 옵션을 써요.

```bash
awsvpnctl setup --no-hammerspoon
```

### What gets installed

`setup`이 메뉴바를 연결할 때 만드는 파일이에요.

```text
~/.hammerspoon/awsvpnctl_hammerspoon.lua -> hammerspoon/awsvpnctl_hammerspoon.lua
~/.hammerspoon/awsvpnctl_config.lua
```

그리고 `~/.hammerspoon/init.lua`에 다음 줄을 추가해요. 이미 있으면 건너뛰어요.

```lua
require("awsvpnctl_hammerspoon")
```

설치 직후 Hammerspoon CLI IPC 또는 AppleScript로 reload 신호를 보내요. 둘 다 비활성화되어 있으면 Hammerspoon에서 직접 `Reload Config`를 실행해야 해요.

### Permissions

Hammerspoon은 첫 실행 시 macOS Accessibility 권한을 요청해요. `시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용`에서 Hammerspoon을 허용해야 메뉴바와 reload가 정상 동작해요.

### Verify

```bash
awsvpnctl doctor
```

`hammerspoon menubar` 항목이 `-> /.../hammerspoon/awsvpnctl_hammerspoon.lua; ctl=/.../awsvpnctl`처럼 보이면 연결이 성공한 상태예요.

## Status Source

메뉴바는 `~/.hammerspoon/awsvpnctl_config.lua`에 기록된 `awsvpnctl`로 `status --json`을 polling해요. `setup`은 현재 checkout, shell `PATH`, Homebrew 후보 중 profile 상태를 실제로 반환하는 CLI를 config에 기록해요. AWS config나 profile 파일 존재 여부가 아니라 실제 OpenVPN process와 `utun` 상태를 봐요.

## Menu Title

예:

```text
DEV PRD      # 연결됨
VPN          # 모두 끊김
connect dev  # 작업 중
```

실제 화면에서는 연결/끊김/작업 중 상태를 구분하는 아이콘도 함께 보여요.

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

AppleScript reload가 막혀 있으면 Hammerspoon 앱에서 직접 `Reload Config`를 실행해요.

```bash
killall Hammerspoon
open -a Hammerspoon
```
