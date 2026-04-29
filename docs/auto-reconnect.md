# Auto Reconnect

자동 재연결은 LaunchAgent로 실행되는 `awsvpnctl daemon`이 담당해요.

## LaunchAgent

설치 후 다음 plist가 만들어져요.

```text
~/Library/LaunchAgents/com.awsvpnctl.daemon.plist
```

실행되는 명령:

```bash
awsvpnctl daemon --interval 15
```

## Trigger

데몬은 `~/.aws/sso/cache/*.json`의 변경 시간을 감시해요.

```bash
aws sso login --sso-session <name>
```

`<name>`은 `~/.aws/config`에 정의된 `[sso-session ...]` 블록 이름이에요. 사용 가능한 이름은 아래처럼 확인해요.

```bash
grep '^\[sso-session' ~/.aws/config
# [sso-session frontend-developer]
# [sso-session backend-developer]
```

위 예에서는 `aws sso login --sso-session frontend-developer`처럼 사용해요. `~/.aws/config`에 `[sso-session ...]` 블록이 없다면 먼저 `aws configure sso`로 추가해야 해요. `awsvpnctl doctor`도 발견된 sso-session 이름을 같이 출력해요.

SSO token이 갱신되면 `etc/config.json`의 `auto_connect` 목록을 보고 필요한 profile을 연결해요.

## Drop Recovery

VPN이 끊기면 `utun` interface가 사라지거나 OpenVPN process가 종료돼요. 데몬은 이를 감지하고 다시 연결해요.

재시도에는 60초 backoff가 있어요. 인증 세션이 살아 있으면 브라우저가 자동으로 통과할 수 있고, 아니면 사용자가 다시 로그인해야 해요.

## Screen Lock

화면 잠금 자체는 VPN을 끊지 않아요. 다만 macOS가 잠금 뒤 idle sleep에 들어가면 Wi-Fi와 `utun` interface가 내려가면서 VPN이 끊길 수 있어요.

`awsvpnctl daemon`은 awsvpnctl로 연결된 profile이 하나라도 있으면 `/usr/bin/caffeinate -i`를 실행해 idle system sleep을 막아요. display sleep과 화면 잠금은 그대로 허용하고, VPN이 모두 끊기면 sleep guard도 종료해요.

사용자가 직접 Sleep을 누르거나 배터리/MDM 정책으로 강제 sleep이 걸리는 경우는 막지 못해요. 그런 경우에는 wake 후 drop recovery가 다시 연결해요.

## Manual Disconnect

```bash
awsvpnctl disconnect dev
```

사용자가 직접 끊은 profile은 disabled sentinel이 생기며 데몬이 바로 되살리지 않아요.

다음 SSO refresh 또는 수동 connect가 있으면 sentinel이 해제돼요.

## Check Daemon

```bash
awsvpnctl doctor
launchctl print gui/$(id -u)/com.awsvpnctl.daemon
```

## Reload Daemon

```bash
awsvpnctl daemon restart
```
