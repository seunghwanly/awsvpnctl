# SAML Flow

awsvpnctl은 AWS Client VPN의 SAML federated auth 흐름을 OpenVPN management interface로 처리합니다.

## High-Level Flow

```text
awsvpnctl connect <profile>
  -> .ovpn에서 endpoint 추출
  -> random subdomain DNS resolve
  -> OpenVPN challenge 시작
  -> AUTH_FAILED,CRV1 challenge에서 SAML URL/SID 획득
  -> browser open
  -> localhost:35001에서 SAMLResponse 수신
  -> management interface로 CRV1 응답 전달
  -> Initialization Sequence Completed
```

## Local Listener

브라우저 SSO 완료 후 IdP가 다음 주소로 SAMLResponse를 POST합니다.

```text
http://127.0.0.1:35001
```

방화벽이나 네트워크 필터가 localhost POST를 막으면 인증이 완료되지 않습니다.

## Parallel Profiles

runtime connection은 profile별 독립 OpenVPN process로 병렬 실행됩니다.

단, SAML 인증 단계는 `127.0.0.1:35001` 한 포트를 쓰므로 `var/run/saml.lock`으로 직렬화합니다. 예를 들어 dev 인증이 끝난 뒤 prod 인증이 진행됩니다.

## Session Expiry

AWS Client VPN endpoint의 SAML session duration이 만료되면 OpenVPN 인증이 실패하고 연결이 종료될 수 있습니다. 데몬은 이를 감지해 다시 연결을 시도합니다.

IdP browser session이 살아 있으면 사용자가 다시 입력하지 않아도 통과할 수 있습니다. IdP session도 만료되었으면 브라우저에서 다시 로그인해야 합니다.
