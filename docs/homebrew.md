# Homebrew

awsvpnctl은 Homebrew tap으로 설치할 수 있습니다.

## Install

현재 repository 이름이 `homebrew-awsvpnctl`이 아니므로 tap을 추가할 때 URL을 명시합니다.

```bash
brew tap seunghwanly/awsvpnctl https://github.com/seunghwanly/awsvpnctl.git
brew install awsvpnctl
```

설치가 끝나면 post-install 설정을 실행합니다.

```bash
awsvpnctl-install
awsvpnctl setup
awsvpnctl doctor
```

## Why awsvpnctl-install Exists

`brew install awsvpnctl`은 파일을 Cellar에 설치하는 단계만 처리합니다. macOS 권한이 필요한 작업은 사용자가 명시적으로 실행해야 합니다.

`awsvpnctl-install`이 처리하는 것:

- passwordless sudoers fragment 설치
- LaunchAgent 설치 및 로드
- Hammerspoon 메뉴바 symlink 연결
- 기존 설치 상태 점검

## Installed Layout

Homebrew 설치에서는 코드와 사용자 데이터가 분리됩니다.

```text
Code:     $(brew --prefix)/opt/awsvpnctl/libexec
Profiles: $(brew --prefix)/etc/awsvpnctl/profiles
Config:   $(brew --prefix)/etc/awsvpnctl/config.json
Logs:     $(brew --prefix)/var/log/awsvpnctl
State:    $(brew --prefix)/var/run/awsvpnctl
```

이렇게 해야 `brew upgrade awsvpnctl`을 해도 profile과 로그가 Cellar version directory에 묶이지 않습니다.

## Upgrade

```bash
brew update
brew upgrade awsvpnctl
awsvpnctl-install
awsvpnctl doctor
```

upgrade 후 `awsvpnctl-install`을 다시 실행하는 이유는 LaunchAgent와 sudoers가 현재 `opt` 경로를 가리키는지 확인하기 위해서입니다.

## Uninstall

```bash
awsvpnctl-install --uninstall
brew uninstall awsvpnctl
```

OpenVPN dependency까지 제거하려면:

```bash
brew uninstall openvpn-aws
```

tap 제거:

```bash
brew untap seunghwanly/awsvpnctl
```

## Standard Tap Shortcut

다음처럼 URL 없는 짧은 명령을 쓰려면 GitHub repository 이름이 `homebrew-awsvpnctl`이어야 합니다.

```bash
brew tap seunghwanly/awsvpnctl
brew install awsvpnctl
```

현재 repository를 그대로 쓰는 동안은 URL을 붙인 tap 명령을 사용합니다.
