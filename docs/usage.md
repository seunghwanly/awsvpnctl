# Usage

## List Profiles

```bash
awsvpnctl list
```

출력 예:

```text
  dev (auto)
  prod (alias: prd)
```

## Connect

```bash
awsvpnctl connect <profile_name>
```

브라우저가 열리면 SSO 로그인을 완료해요. 성공하면 `utun` 인터페이스가 만들어져요. 예를 들어 setup에서 `dev.ovpn`을 가져왔다면 `awsvpnctl connect dev`를 써요.

이미 같은 profile이 연결 중이어도 `connect`는 기존 OpenVPN process를 먼저 끊고 새 연결을 만들어요. 연결이 없으면 그대로 새로 연결해요.

## Connect Multiple Profiles

각 profile은 별도 OpenVPN process와 별도 `utun` interface로 실행돼요.

```bash
awsvpnctl connect dev
awsvpnctl connect prod
```

## Status

```bash
awsvpnctl status
```

처음 연결을 확인할 때는 `connect` 직후 `status`를 봐요.

JSON:

```bash
awsvpnctl status --json
```

Watch:

```bash
awsvpnctl status -w 2
```

## Disconnect

```bash
awsvpnctl disconnect dev
```

수동 disconnect는 해당 profile에 disabled sentinel을 남겨요. 데몬은 사용자가 직접 끊은 profile을 즉시 다시 연결하지 않아요.

다음 동작 중 하나가 있으면 다시 연결 대상이 돼요.

- `awsvpnctl connect <profile>`
- 새 `aws sso login`

## Exit Daemon

```bash
awsvpnctl exit
```

`exit`은 LaunchAgent 데몬을 내리고 `var/run/.daemon-paused` sentinel을 남겨 자동 재연결과 interval connect 재시도를 멈춰요. 현재 연결된 VPN profile은 끊지 않아요.

다시 자동 재연결을 켜려면:

```bash
awsvpnctl daemon restart
```

## Remove a Profile

```bash
awsvpnctl remove dev
```

`remove`는 해당 profile을 먼저 disconnect하고, `.ovpn` 파일을 삭제한 뒤 `auto_connect` 목록에서도 제거해요. 해당 profile의 runtime 파일도 같이 정리해요.

로그까지 지우고 싶으면:

```bash
awsvpnctl remove dev --purge-logs
```

## Logs

```bash
awsvpnctl logs dev
awsvpnctl logs dev -f
```

로그 파일은 `log/<profile>.log`에 저장돼요.

## Doctor

```bash
awsvpnctl doctor
```

설치, sudoers, LaunchAgent, Hammerspoon, profile, AWS SSO token, live VPN state를 한 번에 확인해요.
