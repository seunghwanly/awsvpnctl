# Security Model

awsvpnctl은 VPN 연결을 위해 root 권한으로 OpenVPN을 실행해야 해요. 이를 위해 제한된 sudo runner를 사용해요.

## Sudoers Scope

설치 후 `/etc/sudoers.d/aws-vpn-connector`에 repo의 runner 한 경로만 허용돼요.

```text
<user> ALL=(root) NOPASSWD: /path/to/awsvpnctl/bin/aws-vpn-sudo-runner
```

## Allowed Runner Actions

`bin/aws-vpn-sudo-runner`는 제한된 action만 받아요.

```bash
openvpn <args...>
kill <pid|signal>
cat <path-under-log-dir>
chown-log <path-under-log-dir>
```

로그 읽기와 ownership 복구는 `log/` 하위로 제한돼요.

## Local Sensitive Files

다음 파일은 git에 올리지 않아요.

```text
etc/config.json
etc/profiles/*.ovpn
log/*
var/run/*
```

`.ovpn`에는 endpoint와 certificate material이 포함될 수 있으므로 저장소에 커밋하지 않아요.

## Risk Boundary

- runner 자체가 변조되면 root 권한 실행 경로가 될 수 있어요.
- OpenVPN config는 root로 읽히므로 신뢰할 수 없는 `.ovpn`을 넣으면 안 돼요.
- 이 도구는 개인 macOS workstation에서 쓴다는 전제의 tradeoff예요.

## Hardening Option

runner 변조 위험을 줄이려면 root-owned로 고정할 수 있어요.

```bash
sudo chown root:wheel bin/aws-vpn-sudo-runner
sudo chmod 555 bin/aws-vpn-sudo-runner
```

다만 repo update workflow와 충돌할 수 있으므로 운영 방식에 맞춰 선택해요.
