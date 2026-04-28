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

탐색은 하되 import는 건너뛰기:

```bash
awsvpnctl setup --skip-import
```

`--skip-import`는 후보 `.ovpn`을 출력만 하고 `etc/profiles/`로 복사하지 않습니다. 기존 profile의 자동 연결 설정만 갱신하고 싶을 때 사용합니다. 같은 동작으로 `--no-import`도 사용할 수 있습니다.

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

## AWS SSO Session

자동 연결과 daemon trigger는 AWS SSO token이 발급되어야 동작합니다.

```bash
aws sso login --sso-session <name>
```

`<name>`은 `~/.aws/config`의 `[sso-session ...]` 블록 이름입니다. 사용 가능한 이름을 확인하려면:

```bash
grep '^\[sso-session' ~/.aws/config
# 예: [sso-session frontend-developer]
```

블록이 비어 있으면 `aws configure sso`로 먼저 등록합니다. `awsvpnctl doctor`도 `~/.aws/config`에서 발견된 sso-session 이름을 함께 출력합니다.

## Next Step

```bash
awsvpnctl doctor
awsvpnctl connect dev
```
