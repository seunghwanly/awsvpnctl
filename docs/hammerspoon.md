# Hammerspoon Menu Bar

Hammerspoon integration은 메뉴바에서 실제 VPN 연결 상태를 보여주고 connect/disconnect 액션을 제공합니다.

## Install

`install.sh`가 다음 symlink를 만듭니다.

```text
~/.hammerspoon/awsvpnctl_hammerspoon.lua -> hammerspoon/awsvpnctl_hammerspoon.lua
```

그리고 `~/.hammerspoon/init.lua`에 다음 줄을 추가합니다.

```lua
require("awsvpnctl_hammerspoon")
```

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
