# Uninstall

## Remove Runtime Integrations

```bash
./install.sh --uninstall
```

제거 대상:

- LaunchAgent
- Hammerspoon symlink
- sudoers fragment
- shell rc PATH entry

보존 대상:

- `etc/profiles/*.ovpn`
- `etc/config.json`
- `log/`
- Homebrew package/tap

## Remove OpenVPN Package

```bash
brew uninstall openvpn-aws
```

로컬 tap까지 제거하려면:

```bash
brew untap seunghwanly/awsvpnctl
```

## Remove Local Data

주의: `.ovpn` profile도 삭제됩니다.

```bash
rm -rf etc/profiles/*.ovpn
rm -f etc/config.json
rm -rf log/*
rm -rf var/run/*
```

디렉터리 placeholder를 유지하려면 `.gitkeep`은 지우지 않아도 됩니다.
