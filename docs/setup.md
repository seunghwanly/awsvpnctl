# Initial Setup

설치 후 사용자 설정은 `awsvpnctl setup`으로 처리합니다.

```bash
awsvpnctl setup
```

이 명령은 `~/Downloads`와 `~/Desktop` 아래에서 AWS Client VPN export로 보이는 `.ovpn` 파일을 찾고, profile 이름을 제안한 뒤, `etc/profiles/`로 복사합니다. 마지막으로 어떤 profile을 자동 연결할지 묻고 `etc/config.json`을 갱신합니다.

자동 탐색은 `aws-dev-*`, `aws-prod-*`, `downloaded-client-config.ovpn`처럼 AWS에서 받은 파일명만 후보로 잡습니다. 그 외 이름의 `.ovpn`은 자동으로 가져오지 않습니다.

## Common Flows

자동 탐색:

```bash
awsvpnctl setup
```

파일 직접 지정:

```bash
awsvpnctl setup ~/Downloads/downloaded-client-config.ovpn
```

자동 탐색에서 제외된 파일도 직접 지정하면 가져올 수 있습니다.

profile 이름 지정:

```bash
awsvpnctl setup ~/Downloads/dev.ovpn --name dev
```

비대화형 설정:

```bash
awsvpnctl setup --yes
```

자동 연결 비활성:

```bash
awsvpnctl setup --auto none
```

자동 연결 대상 지정:

```bash
awsvpnctl setup --auto dev,prd
```

`prd`는 `prod` alias로 처리됩니다.

## Generated Files

```text
etc/profiles/<name>.ovpn
etc/config.json
```

이 파일들은 사용자별 로컬 설정입니다. `.ovpn`과 `etc/config.json`은 git에 올리지 않습니다.

## Next Step

```bash
awsvpnctl doctor
awsvpnctl connect dev
```
