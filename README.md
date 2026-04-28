# aws-vpn-connector

`aws sso login` 한 번으로 AWS Client VPN(SAML SSO) 을 자동으로 띄우고, 화면 잠금/유휴와 무관하게 SAML 세션 만료(약 12시간)까지 끊김 없이 유지하는 macOS 도구.

공식 **AWS VPN Client.app** 을 대체합니다 (lock disconnect, 시간 제한 disconnect 가 발생하는 그 앱). 대신 SAML federated auth (`auth-federate`) 를 지원하도록 패치된 OpenVPN 바이너리를 직접 사용합니다.

## 동작 방식

```
┌─ aws sso login ──────────────────────────────────────────────────────┐
│                                                                       │
│  1. 사용자가 `aws sso login --sso-session Frontend_Developer`         │
│  2. ~/.aws/sso/cache/*.json 갱신                                      │
│  3. LaunchAgent 데몬이 변경 감지 → 자동 connect 트리거                │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─ awsvpnctl connect <profile> ────────────────────────────────────────┐
│                                                                       │
│  1. .ovpn 에서 endpoint hostname 추출, random 서브도메인 + DNS 해석   │
│  2. patched openvpn 1차 실행 (N/A + ACS::35001) → AUTH_FAILED 응답   │
│     로부터 SAML URL + SID 추출                                        │
│  3. 브라우저 자동 오픈 → IdP 에서 사용자 인증                         │
│  4. 로컬 127.0.0.1:35001 에서 SAMLResponse POST 수신                  │
│  5. patched openvpn 2차 실행 (sudo, --daemon) — CRV1::SID::Response  │
│     로 인증, utun 인터페이스 생성                                     │
│  6. 종료 시까지 데몬 유지. 화면 잠금/sleep 무관 (openvpn 자체는      │
│     keepalive ping 으로 살아 있음)                                    │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─ ~12h 후 SAML 세션 만료 ──────────────────────────────────────────────┐
│                                                                       │
│  1. openvpn 프로세스 종료 → utun 사라짐                              │
│  2. 데몬이 감지 → 다시 connect (단계 1~6 반복)                        │
│  3. IdP 에 브라우저 세션이 살아 있으면 자동 통과, 아니면 재로그인    │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
```

## 디렉토리 구조

```
aws-vpn-connector/
├── README.md
├── install.sh                              # 한 방 설치 스크립트
├── bin/
│   ├── awsvpnctl                           # 메인 CLI (Python)
│   └── aws-vpn-sudo-runner                 # 제한된 sudo 진입점 (bash)
├── etc/
│   ├── config.json                         # auto_connect 등
│   ├── config.example.json                 # repo 기본 예시
│   └── profiles/                           # <profile>.ovpn 사본 (600 perm)
├── share/
│   ├── com.awsvpnctl.daemon.plist          # LaunchAgent 템플릿
│   └── sudoers.aws-vpn-connector           # sudoers fragment 템플릿
├── hammerspoon/
│   └── awsvpnctl_hammerspoon.lua           # 메뉴바 (실시간 utun 상태)
├── var/run/                                # PID, iface, lock, runtime conf
└── log/                                    # daemon.log, <profile>.log
```

## 설치

```bash
git clone git@github.com:seunghwanly/awsvpnctl.git ~/dev/awsvpnctl
cd ~/dev/awsvpnctl
./install.sh
```

설치 스크립트는 **사전 점검 리포트 → 실행 계획 → 한 번만 확인 → 자동 진행** 방식입니다. 끝나면 `awsvpnctl doctor` 로 상태를 자동 검증합니다. 다시 실행해도 이미 된 단계는 건너뜁니다 (idempotent).

설치 후 사용자 설정은 한 명령으로 끝냅니다:

```bash
awsvpnctl setup
```

`setup` 은 `~/Downloads` 와 `~/Desktop` 에 있는 `.ovpn` 파일을 찾아 `etc/profiles/` 로 가져오고, 어떤 프로필을 자동 연결할지 물어본 뒤 `etc/config.json` 을 갱신합니다. 새 VPN 프로필을 추가할 때도 같은 명령을 다시 실행하면 됩니다.

옵션:

```bash
./install.sh --check       # 점검만 하고 종료 (실제 변경 없음)
./install.sh --yes         # 확인 프롬프트 생략
./install.sh --no-path     # PATH 자동 추가 비활성
./install.sh --uninstall   # sudoers / LaunchAgent / Hammerspoon symlink 제거 (프로필은 유지)
```

`install.sh` 가 처리하는 것:

1. **patched openvpn 빌드 / 설치** — `share/openvpn-aws.rb` (자체 formula, OpenVPN 2.6.12 + samm-git AWS SAML 패치 + system openssl@3) 을 로컬 tap (`seunghwanly/awsvpnctl`) 에 등록 후 `--build-from-source` 로 컴파일 (~2 분). `/opt/homebrew/opt/openvpn-aws/sbin/openvpn` 에 설치. 빌드 의존성: `autoconf`, `automake`, `libtool`, `pkg-config`, `docutils`. 런타임 의존성: `lzo`, `lz4`, `pkcs11-helper`, `openssl@3`.
2. **프로필 복사** — `~/Downloads` / `~/Desktop` 하위에서 `aws-prod-*.ovpn` / `aws-dev-*.ovpn` / `downloaded-client-config.ovpn` / 비슷한 이름 자동 감지 후 짧은 이름 (`prod`, `dev`, `vpn`)으로 `etc/profiles/` 에 복사. 이미 직접 넣어두셨으면 이 단계는 자동 스킵.
3. **config.json 시드** — `etc/profiles/*.ovpn` 의 모든 프로필 이름을 `auto_connect` 에 자동 등록. 기존에 손댔으면 그대로 유지.
4. **passwordless sudoers** — `/etc/sudoers.d/aws-vpn-connector` 에 fragment 설치. `aws-vpn-sudo-runner` 한 경로에만 NOPASSWD 부여 (이 wrapper 는 `openvpn` 실행과 PID 신호만 허용). 1회 sudo 비밀번호 입력 필요.
5. **LaunchAgent 등록** — `~/Library/LaunchAgents/com.awsvpnctl.daemon.plist` 에 설치 후 `launchctl bootstrap` 으로 즉시 로드. 데몬은 `awsvpnctl daemon` 을 영구 실행.
6. **Hammerspoon 메뉴바 연결** — `~/.hammerspoon/awsvpnctl_hammerspoon.lua` 를 이 repo 의 lua 로 symlink (init.lua 의 require 도 자동으로 추가). 기존 파일이 있으면 백업.
7. **PATH 추가** — 사용 중인 셸 (`$SHELL`) 에 맞춰 `~/.zshrc` (또는 `.bashrc` 등)에 `bin/` 경로를 자동 append.

## 사용법

```bash
awsvpnctl setup                 # .ovpn 가져오기 + auto_connect 설정
awsvpnctl list                  # 사용 가능한 프로필 (auto 표시)
awsvpnctl connect dev           # 수동 연결 — 브라우저가 열리고 SSO 인증
awsvpnctl connect prod          # 두 번째 프로필도 동시에 (별도 utun)
awsvpnctl status                # 텍스트 표
awsvpnctl status --json         # JSON (Hammerspoon 이 사용)
awsvpnctl status -w 2           # 2초마다 갱신
awsvpnctl disconnect dev
awsvpnctl logs dev -f           # openvpn 로그 follow
awsvpnctl doctor                # 설치 / 설정 / 토큰 / 연결 상태 한 번에 진단
```

자동 흐름:

```bash
aws sso login --sso-session Frontend_Developer
# 데몬이 SSO 캐시 변경을 감지하고 etc/config.json 의 auto_connect 프로필을 연결
```

## 설정

`etc/config.json`:

```json
{
  "auto_connect": ["dev"]
}
```

- `etc/config.json` 은 사용자별 로컬 설정이라 git에는 올리지 않습니다. 없으면 `install.sh` 또는 `awsvpnctl setup` 이 생성합니다.
- `auto_connect` 에 들어 있는 프로필은 `aws sso login` 후 자동 연결되고, 끊기면 데몬이 다시 연결합니다.
- 둘 다 자동 연결을 원하면 `["dev", "prod"]`.
- 빈 배열 `[]` 이면 자동 연결 비활성 (수동 `awsvpnctl connect` 만 사용).
- `awsvpnctl disconnect <profile>` 로 직접 끊은 프로필은 데몬이 다시 살리지 않습니다 (`var/run/<profile>.disabled` sentinel). 다음 `aws sso login` 또는 `awsvpnctl connect` 가 sentinel 을 해제합니다.

프로필 추가는 `awsvpnctl setup ~/Downloads/<file>.ovpn` 이 가장 편합니다. 수동으로는 `etc/profiles/<name>.ovpn` 만 떨어뜨리면 됩니다 — basename 이 곧 프로필 이름입니다.

비대화형 설정 예:

```bash
awsvpnctl setup --yes                         # 발견한 .ovpn 가져오고 모든 프로필 자동 연결
awsvpnctl setup ~/Downloads/dev.ovpn --name dev --auto dev
awsvpnctl setup --auto none                   # 자동 연결 비활성, 수동 connect만 사용
awsvpnctl setup --auto dev,prd                # prd는 prod alias로 처리
```

## Hammerspoon 메뉴바

```
🥝DEV 🥝PRD              ← 두 프로필 모두 연결됨
🥝DEV                   ← dev 만 연결됨
💥 VPN                  ← 모두 끊김
🏃 connect dev          ← 작업 진행 중 (잠시 표시)
```

드롭다운에서 각 프로필 connect/disconnect, all-on/all-off, refresh, 데몬 로그 열기 가능. `Cmd+Alt+Ctrl+R` 로 reload.

## SAML 동시 연결 정책

각 프로필은 독립된 openvpn 프로세스 + 독립된 utun 인터페이스로 돌아갑니다 (런타임은 병렬). 다만 SAML challenge listener 가 `127.0.0.1:35001` 한 포트만 쓰므로 **SAML 인증 단계는 프로필 단위로 직렬화** 됩니다 (`var/run/saml.lock`). dev 가 SAML 응답 받고 connect 완료되면 prod 가 진행하는 식.

## 보안 모델 (passwordless sudo 의 범위)

`/etc/sudoers.d/aws-vpn-connector` 는 설치된 repo의 제한 runner 한 경로만 허용합니다:

```
seunghwanly ALL=(root) NOPASSWD: /path/to/awsvpnctl/bin/aws-vpn-sudo-runner
```

`aws-vpn-sudo-runner` 는 두 가지 동작만 받습니다:

- `openvpn <args...>` → patched openvpn 바이너리 실행
- `kill <pid|signal>` → 검증된 인자만 통과

위험 한계:
- 이 wrapper 자체가 실수/악의로 변조되면 root 권한 획득 가능합니다. 변조 위험을 줄이려면 `sudo chown root:wheel bin/aws-vpn-sudo-runner && sudo chmod 555 bin/aws-vpn-sudo-runner` 를 적용하세요 (옵션).
- `openvpn` 은 임의 config 를 읽을 수 있으므로 root 권한으로 임의 라우팅/스크립트가 가능합니다. 개인 노트북 사용을 전제로 한 트레이드오프입니다.

## 트러블슈팅

**`openvpn` 빌드 실패** — `share/openvpn-aws.rb` 가 OpenVPN 2.6.12 와 system openssl@3 을 사용합니다 (Homebrew 가 `openssl@1.1` formula 를 제거함에 따른 변경). 그래도 실패하면 `~/Library/Logs/Homebrew/openvpn-aws/*.log` 확인. AWS 가 향후 SAML 프로토콜을 변경해서 패치가 안 맞으면 samm-git 측 새 패치 수동 적용 필요.

**브라우저가 SSO 인증 후 멈춤** — 브라우저가 `localhost:35001` 로 SAMLResponse 를 POST 해야 합니다. 방화벽/Little Snitch 가 차단하면 한 번 허용해주세요.

**`AUTH_FAILED` 메시지가 안 잡힘** — `awsvpnctl logs <profile>` 로 openvpn 로그 확인. .ovpn 파일이 정말로 `auth-federate` 를 포함하는지 확인.

**12시간 안 채우고 끊김** — VPN endpoint 의 SAML session duration 설정에 따라 다름 (관리자가 8h 로 설정했으면 8h 후 끊김). 데몬이 자동 재연결 시도합니다 — 브라우저 IdP 세션이 살아 있으면 사용자 개입 없이 재연결됩니다.

**데몬이 너무 자주 시도함** — 백오프 60초 적용되어 있음. `log/daemon.log` 확인.

**LaunchAgent 재로드** —

```bash
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.awsvpnctl.daemon.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.awsvpnctl.daemon.plist
```

## 제거

```bash
./install.sh --uninstall   # sudoers / LaunchAgent / Hammerspoon symlink / PATH 항목 제거
brew uninstall openvpn-aws # patched openvpn 도 제거하려면
```

프로필 (`etc/profiles/`) 과 로그 (`log/`) 는 보존됩니다. 필요하면 수동 삭제.

## 관련

- 패치된 OpenVPN 출처: <https://github.com/samm-git/aws-vpn-client>
- 패치 본체: AWS 가 공개한 <https://amazon-source-code-downloads.s3.amazonaws.com/aws/clientvpn/openvpn-2.5.1-aws-1.tar.gz>
