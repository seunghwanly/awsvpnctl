# Troubleshooting

## Doctor First

대부분은 먼저 doctor를 보면 돼요. 설치, sudoers, LaunchAgent, Hammerspoon, profile, AWS SSO token, live VPN state를 한 번에 확인해요.

```bash
awsvpnctl doctor
```

## openvpn Build Failed

`Formula/openvpn-aws.rb`는 OpenVPN 2.6.12와 system `openssl@3`를 사용해요.

Homebrew build log:

```bash
ls ~/Library/Logs/Homebrew/openvpn-aws
```

AWS가 SAML patch와 맞지 않는 방식으로 protocol을 바꾸면 upstream patch 갱신이 필요할 수 있어요.

## Browser Login Hangs

브라우저가 SSO 완료 후 아래 주소로 POST해야 해요.

```text
http://127.0.0.1:35001
```

방화벽, Little Snitch, 보안 도구가 localhost callback을 막는지 확인해요.

## SAML Response Rejected

증상:

```text
openvpn authentication failed: SAML response was rejected
```

확인:

```bash
awsvpnctl logs dev
```

가능한 원인:

- 오래된 SAML response 재사용
- 잘못된 `.ovpn`
- AWS Client VPN endpoint 설정 변경
- IdP session/token 만료

다시 시도:

```bash
awsvpnctl connect dev
```

## AUTH_FAILED,Invalid username or password

`.ovpn`에 `auth-federate`가 있는지 확인해요.

```bash
grep auth-federate etc/profiles/dev.ovpn
```

## LaunchAgent Not Loaded

```bash
launchctl print gui/$(id -u)/com.awsvpnctl.daemon
```

재로드:

```bash
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.awsvpnctl.daemon.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.awsvpnctl.daemon.plist
```

source checkout 프로젝트가 `~/Documents`, `~/Desktop`, `~/Downloads` 아래 있으면 macOS privacy policy 때문에 background access가 막힐 수 있어요. 개발용 checkout은 `~/dev/awsvpnctl` 같은 경로를 권장해요.

## Status Says Connected But VPN Is Down

최신 버전은 process 존재만으로 connected라고 보지 않고 `utun` 상태까지 확인해요.

상태가 꼬였으면:

```bash
awsvpnctl reconcile
awsvpnctl status
```

## Log Permission Denied

이전 버전에서 root-owned log가 생긴 경우가 있어요.

```bash
awsvpnctl logs dev
```

최신 버전은 sudo runner로 log ownership을 복구하거나 fallback read를 시도해요.

## Hammerspoon Menu Not Updated

Hammerspoon에서 `Reload Config`를 실행하거나 앱을 재시작해요.

```bash
killall Hammerspoon
open -a Hammerspoon
```
