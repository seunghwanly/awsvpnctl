# Auto Reconnect

자동 재연결은 LaunchAgent로 실행되는 `awsvpnctl daemon`이 담당합니다.

## LaunchAgent

설치 후 다음 plist가 만들어집니다.

```text
~/Library/LaunchAgents/com.awsvpnctl.daemon.plist
```

실행되는 명령:

```bash
awsvpnctl daemon --interval 15
```

## Trigger

데몬은 `~/.aws/sso/cache/*.json`의 변경 시간을 감시합니다.

```bash
aws sso login --sso-session <name>
```

SSO token이 갱신되면 `etc/config.json`의 `auto_connect` 목록을 보고 필요한 profile을 연결합니다.

## Drop Recovery

VPN이 끊기면 `utun` interface가 사라지거나 OpenVPN process가 종료됩니다. 데몬은 이를 감지하고 다시 연결합니다.

재시도에는 60초 backoff가 있습니다. 인증 세션이 살아 있으면 브라우저가 자동으로 통과할 수 있고, 아니면 사용자가 다시 로그인해야 합니다.

## Manual Disconnect

```bash
awsvpnctl disconnect dev
```

사용자가 직접 끊은 profile은 disabled sentinel이 생기며 데몬이 바로 되살리지 않습니다.

다음 SSO refresh 또는 수동 connect가 있으면 sentinel이 해제됩니다.

## Check Daemon

```bash
awsvpnctl doctor
launchctl print gui/$(id -u)/com.awsvpnctl.daemon
```

## Reload Daemon

```bash
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.awsvpnctl.daemon.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.awsvpnctl.daemon.plist
```
