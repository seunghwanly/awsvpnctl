# Initial Setup

첫 설치와 사용자 설정은 `awsvpnctl setup`으로 처리해요.

```bash
awsvpnctl setup
```

이 명령은 필요한 시스템 구성(OpenVPN, 제한된 sudoers, LaunchAgent)을 확인/설치한 뒤 `~/Downloads`와 `~/Desktop` 아래에서 AWS Client VPN export로 보이는 `.ovpn` 파일을 찾아요. 대화형 터미널에서는 Spacebar로 가져올 파일을 선택하고, profile 이름과 자동 연결 대상을 설정해요.

sudo가 필요한 단계에서는 이유를 먼저 설명하고 건너뛸지 물어요. 건너뛰면 import는 계속할 수 있지만 `connect`, daemon, `doctor` 일부 항목은 실패할 수 있어요.

자동 탐색은 `aws-dev-*`, `aws-prod-*`, `downloaded-client-config.ovpn`처럼 AWS에서 받은 파일명만 후보로 잡아요. 그 외 이름의 `.ovpn`은 직접 경로를 지정해서 가져와요.

## Common Flows

자동 탐색:

```bash
awsvpnctl setup
```

파일 직접 지정:

```bash
awsvpnctl setup ~/Downloads/downloaded-client-config.ovpn
```

자동 탐색에서 제외된 파일도 직접 지정하면 가져올 수 있어요.

탐색은 하되 import는 건너뛰기:

```bash
awsvpnctl setup --skip-import
```

`--skip-import`는 후보 `.ovpn`을 출력만 하고 `etc/profiles/`로 복사하지 않아요. 기존 profile의 자동 연결 설정만 갱신하고 싶을 때 사용해요. 같은 동작으로 `--no-import`도 사용할 수 있어요.

profile 이름 지정:

```bash
awsvpnctl setup ~/Downloads/dev.ovpn --name dev
```

비대화형 설정:

```bash
awsvpnctl setup --yes
```

시스템 설치 생략:

```bash
awsvpnctl setup --skip-system-install
```

Hammerspoon 메뉴바까지 설치:

```bash
awsvpnctl setup --with-hammerspoon
```

자동 연결 비활성:

```bash
awsvpnctl setup --auto none
```

자동 연결 대상 지정:

```bash
awsvpnctl setup --auto dev,prd
```

`prd`는 `prod` alias로 처리돼요.

## Generated Files

```text
etc/profiles/<name>.ovpn
etc/config.json
```

이 파일들은 사용자별 로컬 설정이에요. `.ovpn`과 `etc/config.json`은 git에 올리지 않아요.

## AWS SSO Session

자동 연결과 daemon trigger는 AWS SSO token이 발급되어야 동작해요.

```bash
aws sso login --sso-session <name>
```

`<name>`은 `~/.aws/config`의 `[sso-session ...]` 블록 이름이에요. 사용 가능한 이름은 아래처럼 확인해요.

```bash
grep '^\[sso-session' ~/.aws/config
# 예: [sso-session frontend-developer]
```

블록이 비어 있으면 `aws configure sso`로 먼저 등록해요. `awsvpnctl doctor`도 `~/.aws/config`에서 발견된 sso-session 이름을 함께 출력해요.

## First Connection Check

```bash
awsvpnctl doctor
awsvpnctl connect <profile_name>
awsvpnctl status
```

`<profile_name>`은 setup에서 가져온 `.ovpn` 이름이에요. 예를 들어 `dev.ovpn`으로 가져왔으면 `awsvpnctl connect dev`를 써요.
