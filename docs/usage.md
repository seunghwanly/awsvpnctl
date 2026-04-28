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
awsvpnctl connect dev
```

브라우저가 열리면 SSO 로그인을 완료합니다. 성공하면 `utun` 인터페이스가 만들어집니다.

## Connect Multiple Profiles

각 profile은 별도 OpenVPN process와 별도 `utun` interface로 실행됩니다.

```bash
awsvpnctl connect dev
awsvpnctl connect prod
```

## Status

```bash
awsvpnctl status
```

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

수동 disconnect는 해당 profile에 disabled sentinel을 남깁니다. 데몬은 사용자가 직접 끊은 profile을 즉시 다시 연결하지 않습니다.

다음 동작 중 하나가 있으면 다시 연결 대상이 됩니다.

- `awsvpnctl connect <profile>`
- 새 `aws sso login`

## Logs

```bash
awsvpnctl logs dev
awsvpnctl logs dev -f
```

로그 파일은 `log/<profile>.log`에 저장됩니다.

## Doctor

```bash
awsvpnctl doctor
```

설치, sudoers, LaunchAgent, Hammerspoon, profile, AWS SSO token, live VPN state를 한 번에 확인합니다.
