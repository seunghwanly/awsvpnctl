# Profiles

awsvpnctl의 profile은 `etc/profiles/<name>.ovpn` 파일입니다. 별도의 profile 등록 DB는 없습니다.

## Naming

```text
etc/profiles/dev.ovpn   -> awsvpnctl connect dev
etc/profiles/prod.ovpn  -> awsvpnctl connect prod
```

기본 alias:

```text
prd -> prod
```

따라서 `prod.ovpn`이 있으면 다음 명령도 동작합니다.

```bash
awsvpnctl connect prd
```

## Add a Profile

권장:

```bash
awsvpnctl setup ~/Downloads/client-vpn.ovpn --name staging
```

수동:

```bash
cp ~/Downloads/client-vpn.ovpn etc/profiles/staging.ovpn
chmod 600 etc/profiles/staging.ovpn
awsvpnctl list
```

## Remove a Profile

```bash
awsvpnctl remove staging
```

이 명령은 `etc/profiles/staging.ovpn`을 삭제하고 `etc/config.json`의 `auto_connect`에서도 `staging`을 제거합니다. 연결 중이면 먼저 끊습니다.

## Auto Connect

자동 연결 목록은 `etc/config.json`에 있습니다.

```json
{
  "auto_connect": ["dev"]
}
```

여러 profile:

```json
{
  "auto_connect": ["dev", "prod"]
}
```

수동 연결만 사용:

```json
{
  "auto_connect": []
}
```

`awsvpnctl setup --auto ...`를 쓰면 직접 JSON을 편집하지 않아도 됩니다.

## What Must Be in the OVPN

`.ovpn`에는 최소한 다음 정보가 있어야 합니다.

- `remote` directive
- `proto` directive 또는 기본 UDP 사용 가능 상태
- AWS Client VPN용 인증 설정
- `auth-federate`
- 인증서/CA 관련 설정

`auth-federate`가 없으면 AWS SAML 흐름이 동작하지 않을 수 있습니다.
