# Homebrew

awsvpnctl은 Homebrew tap으로 설치해요.

## Install

현재 repository 이름이 `homebrew-awsvpnctl`이 아니므로 tap을 추가할 때 URL을 명시해요.

```bash
brew tap seunghwanly/awsvpnctl https://github.com/seunghwanly/awsvpnctl.git
brew install awsvpnctl
awsvpnctl setup
awsvpnctl doctor
```

`brew install`은 파일을 Cellar에 설치해요. macOS 권한이 필요한 OpenVPN, sudoers, LaunchAgent 구성은 사용자가 직접 실행한 `awsvpnctl setup`에서 설명과 확인 후 처리해요.

## Installed Layout

Homebrew 설치에서는 코드와 사용자 데이터가 분리돼요.

```text
Code:     $(brew --prefix)/opt/awsvpnctl/libexec
Profiles: $(brew --prefix)/etc/awsvpnctl/profiles
Config:   $(brew --prefix)/etc/awsvpnctl/config.json
Logs:     $(brew --prefix)/var/log/awsvpnctl
State:    $(brew --prefix)/var/run/awsvpnctl
```

이렇게 해야 `brew upgrade awsvpnctl`을 해도 profile과 로그가 Cellar version directory에 묶이지 않아요.

## Upgrade

```bash
brew update
brew upgrade awsvpnctl
awsvpnctl setup --skip-import
awsvpnctl doctor
```

upgrade 후 `setup --skip-import`를 다시 실행하는 이유는 LaunchAgent와 sudoers가 현재 `opt` 경로를 가리키는지 확인하기 위해서예요.

## Uninstall

```bash
awsvpnctl uninstall
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

다음처럼 URL 없는 짧은 명령을 쓰려면 GitHub repository 이름이 `homebrew-awsvpnctl`이어야 해요.

```bash
brew tap seunghwanly/awsvpnctl
brew install awsvpnctl
```

현재 repository를 그대로 쓰는 동안은 URL을 붙인 tap 명령을 사용해요.
