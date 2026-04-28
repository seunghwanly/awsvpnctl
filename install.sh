#!/usr/bin/env bash
# awsvpnctl installer.
#
# Default: dry-run preflight, then prompt for confirmation, then execute.
# Flags:
#   --yes / -y    skip confirmation
#   --check       just print the preflight report and exit
#   --uninstall   remove sudoers, LaunchAgent, hammerspoon symlink (keeps profiles)
#   --no-path     skip adding bin/ to shell rc
set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && /bin/pwd -P)"
PROJECT_ROOT="${AWSVPNCTL_ROOT:-$SCRIPT_ROOT}"
USER_NAME="$(id -un)"
HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix 2>/dev/null || echo /opt/homebrew)}"
OPENVPN_AWS_BIN="$HOMEBREW_PREFIX/opt/openvpn-aws/sbin/openvpn"
AWSVPNCTL_BIN="${AWSVPNCTL_BIN:-$PROJECT_ROOT/bin/awsvpnctl}"
CONFIG_DIR="${AWSVPNCTL_CONFIG_DIR:-$PROJECT_ROOT/etc}"
PROFILES_DIR="${AWSVPNCTL_PROFILES_DIR:-$CONFIG_DIR/profiles}"
CONFIG_FILE="${AWSVPNCTL_CONFIG_FILE:-$CONFIG_DIR/config.json}"
RUN_DIR="${AWSVPNCTL_RUN_DIR:-$PROJECT_ROOT/var/run}"
LOG_DIR="${AWSVPNCTL_LOG_DIR:-$PROJECT_ROOT/log}"
SUDO_RUNNER="${AWSVPNCTL_SUDO_RUNNER:-$PROJECT_ROOT/bin/aws-vpn-sudo-runner}"
SUDOERS_TARGET="/etc/sudoers.d/aws-vpn-connector"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_TARGET="$LAUNCH_AGENT_DIR/com.awsvpnctl.daemon.plist"
LAUNCH_AGENT_LABEL="com.awsvpnctl.daemon"
HAMMERSPOON_DIR="$HOME/.hammerspoon"
HAMMERSPOON_TARGET="$HAMMERSPOON_DIR/awsvpnctl_hammerspoon.lua"

mkdir -p "$PROFILES_DIR" "$RUN_DIR" "$LOG_DIR"

# parse args
ASSUME_YES=0
CHECK_ONLY=0
UNINSTALL=0
NO_PATH="${AWSVPNCTL_NO_PATH:-0}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--yes)    ASSUME_YES=1; shift ;;
    --check)     CHECK_ONLY=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    --no-path)   NO_PATH=1; shift ;;
    -h|--help)
      sed -n '2,11p' "$0" | sed 's/^# //; s/^#//'
      exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
done

# ── output helpers ──────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  C_R=$'\033[31m'; C_G=$'\033[32m'; C_Y=$'\033[33m'; C_B=$'\033[36m'
  C_DIM=$'\033[2m'; C_BOLD=$'\033[1m'; C_OFF=$'\033[0m'
else
  C_R= C_G= C_Y= C_B= C_DIM= C_BOLD= C_OFF=
fi
ok()    { printf "  ${C_G}✓${C_OFF} %s\n" "$*"; }
todo()  { printf "  ${C_Y}○${C_OFF} %s\n" "$*"; }
fail()  { printf "  ${C_R}✗${C_OFF} %s\n" "$*"; }
note()  { printf "    ${C_DIM}%s${C_OFF}\n" "$*"; }
title() { printf "\n${C_BOLD}${C_B}%s${C_OFF}\n" "$*"; }
step()  { printf "\n${C_BOLD}[%s]${C_OFF} %s\n" "$1" "$2"; }
die()   { printf "${C_R}error:${C_OFF} %s\n" "$*" >&2; exit 1; }

# ── shell rc detection (for PATH update) ────────────────────────────────────
detect_shell_rc() {
  local sh; sh="$(basename "${SHELL:-/bin/zsh}")"
  case "$sh" in
    zsh)  echo "$HOME/.zshrc" ;;
    bash) [[ -f "$HOME/.bash_profile" ]] && echo "$HOME/.bash_profile" || echo "$HOME/.bashrc" ;;
    *)    echo "$HOME/.profile" ;;
  esac
}
SHELL_RC="$(detect_shell_rc)"
PATH_LINE="export PATH=\"$PROJECT_ROOT/bin:\$PATH\"  # awsvpnctl"

path_in_rc() {
  [[ -f "$SHELL_RC" ]] || return 1
  /usr/bin/python3 - "$SHELL_RC" "$PROJECT_ROOT/bin" <<'PY'
import os
import re
import sys

rc, target = sys.argv[1:]
target = os.path.realpath(target)
try:
    text = open(rc, encoding="utf-8", errors="ignore").read()
except OSError:
    sys.exit(1)

for value in re.findall(r"/[^\s\"']*(?:aws-vpn-connector|awsvpnctl)/bin", text):
    try:
        if os.path.samefile(value, target):
            sys.exit(0)
    except OSError:
        pass
sys.exit(1)
PY
}

# ── individual checks ───────────────────────────────────────────────────────
check_macos()    { [[ "$(uname -s)" == "Darwin" ]]; }
check_brew()     { command -v brew >/dev/null 2>&1; }
check_openvpn()  { [[ -x "$OPENVPN_AWS_BIN" ]]; }
check_sudoers()  {
  [[ -f "$SUDOERS_TARGET" ]] || return 1
  check_sudo_works
}
check_sudo_works() {
  sudo -n "$SUDO_RUNNER" openvpn --version >/dev/null 2>&1
}
check_launchagent() {
  [[ -f "$LAUNCH_AGENT_TARGET" ]] || return 1
  grep -qF "$AWSVPNCTL_BIN" "$LAUNCH_AGENT_TARGET" || return 1
  grep -qF "$LOG_DIR/daemon.log" "$LAUNCH_AGENT_TARGET" || return 1
  launchctl print "gui/$(id -u)/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1
}
check_hammerspoon_app() { [[ -d /Applications/Hammerspoon.app ]]; }
check_hs_symlink() {
  [[ -L "$HAMMERSPOON_TARGET" ]] || return 1
  /usr/bin/python3 - "$HAMMERSPOON_TARGET" "$PROJECT_ROOT/hammerspoon/awsvpnctl_hammerspoon.lua" <<'PY'
import os
import sys

actual, expected = sys.argv[1:]
try:
    sys.exit(0 if os.path.samefile(actual, expected) else 1)
except OSError:
    sys.exit(1)
PY
}
count_profiles() { find "$PROFILES_DIR" -maxdepth 1 -name '*.ovpn' 2>/dev/null | wc -l | tr -d ' '; }
discover_desktop_profiles() {
  {
    [[ -d "$HOME/Downloads" ]] && find "$HOME/Downloads" -maxdepth 4 -name '*.ovpn' 2>/dev/null
    [[ -d "$HOME/Desktop" ]] && find "$HOME/Desktop" -maxdepth 4 -name '*.ovpn' 2>/dev/null
  } | while IFS= read -r f; do
    [[ -n "$(suggest_profile_name "$f")" ]] && printf '%s\n' "$f"
  done | sort -u
}

# Map a discovered .ovpn filename to a short profile name.
# Heuristics:
#   aws-prod-<hex>.ovpn       -> prod
#   aws-dev-<hex>.ovpn        -> dev
#   development.ovpn          -> dev
#   downloaded-client-config  -> vpn
# Unrecognized files are ignored during automatic discovery; pass them
# explicitly to `awsvpnctl setup /path/to/file.ovpn` if they should be imported.
suggest_profile_name() {
  local f base name
  f="$1"; base="$(basename "$f" .ovpn)"
  case "$base" in
    aws-prod-*)            echo "prod"; return ;;
    aws-prd-*)             echo "prod"; return ;;
    aws-dev-*)             echo "dev";  return ;;
    aws-stg-*|aws-staging-*) echo "stg"; return ;;
    development)           echo "dev";  return ;;
    production)            echo "prod"; return ;;
    downloaded-client-config|client-config) echo "vpn"; return ;;
  esac
  case "$base" in
    aws-*) ;;
    *) echo ""; return ;;
  esac
  name="${base#aws-}"
  name="$(echo "$name" | sed -E 's/-[0-9a-f]{8,}$//')"
  case "$name" in
    dev|prod|stg|staging) echo "$name" ;;
    prd) echo "prod" ;;
    *) echo "" ;;
  esac
}

# ── preflight: collect what is already done and what remains ────────────────
title "awsvpnctl  $([[ $UNINSTALL == 1 ]] && echo "(uninstall mode)" )"

if ! check_macos;    then die "macOS only"; fi
if ! check_brew;     then die "Homebrew not found — install from https://brew.sh first"; fi

ok "macOS $(sw_vers -productVersion)"
ok "Homebrew at $HOMEBREW_PREFIX"

if check_openvpn;        then ok "patched openvpn at $OPENVPN_AWS_BIN"; OPENVPN_DONE=1; else todo "patched openvpn missing"; OPENVPN_DONE=0; fi

PROFILE_COUNT="$(count_profiles)"
if [[ "$PROFILE_COUNT" -gt 0 ]]; then
  ok "$PROFILE_COUNT profile(s) in $PROFILES_DIR/"
  for p in "$PROFILES_DIR"/*.ovpn; do note "→ $(basename "$p" .ovpn)"; done
  PROFILES_DONE=1
else
  todo "no profiles in $PROFILES_DIR/"
  PROFILES_DONE=0
fi

# Check whether config.json's auto_connect list points at real profiles.
config_auto_stale() {
  local cfg="$CONFIG_FILE"
  [[ -f "$cfg" ]] || return 0
  local autos
  autos=$(/usr/bin/python3 - "$cfg" <<'PY' 2>/dev/null
import json
import sys

try:
    cfg = json.load(open(sys.argv[1]))
except Exception:
    print("")
else:
    print(" ".join(cfg.get("auto_connect", [])))
PY
)
  # If empty, count as stale (we will seed it)
  if [[ -z "$autos" ]]; then return 0; fi
  for n in $autos; do
    [[ -f "$PROFILES_DIR/${n}.ovpn" ]] || return 0
  done
  return 1
}

if [[ "$PROFILE_COUNT" -gt 0 ]] && config_auto_stale; then
  todo "config.json auto_connect list will be (re)seeded"
  CONFIG_DONE=0
else
  CONFIG_DONE=1
fi

# Discovered candidates in common download locations
DISCOVERED=()
SUGGESTED_NAMES=()
if [[ "$PROFILES_DONE" == 0 ]]; then
  while IFS= read -r f; do
    n="$(suggest_profile_name "$f")"
    [[ -z "$n" ]] && continue
    DISCOVERED+=("$f")
    SUGGESTED_NAMES+=("$n")
  done < <(discover_desktop_profiles)

  if [[ ${#DISCOVERED[@]} -gt 0 ]]; then
    note "discovered in ~/Downloads or ~/Desktop:"
    for i in "${!DISCOVERED[@]}"; do
      note "  $(basename "${DISCOVERED[$i]}")  →  ${SUGGESTED_NAMES[$i]}.ovpn"
    done
  fi
fi

if check_sudoers;        then ok "sudoers fragment installed";        SUDOERS_DONE=1; else todo "sudoers fragment missing";        SUDOERS_DONE=0; fi
if check_launchagent;    then ok "LaunchAgent loaded";                 LAUNCH_DONE=1;  else todo "LaunchAgent not loaded";          LAUNCH_DONE=0;  fi

if check_hammerspoon_app; then
  if check_hs_symlink;   then ok "Hammerspoon menubar wired up";       HS_DONE=1;     else todo "Hammerspoon menubar not wired";    HS_DONE=0;     fi
else
  fail "Hammerspoon.app not in /Applications (will skip menubar)"
  note "install with: brew install --cask hammerspoon"
  HS_DONE=skip
fi

if [[ $NO_PATH == 0 ]]; then
  if path_in_rc;          then ok "$SHELL_RC has bin/ on PATH";          PATH_DONE=1;   else todo "PATH update for $SHELL_RC";        PATH_DONE=0;   fi
else
  PATH_DONE=skip
fi

# ── uninstall path ──────────────────────────────────────────────────────────
if [[ $UNINSTALL == 1 ]]; then
  title "Uninstalling"
  if [[ -f "$LAUNCH_AGENT_TARGET" ]]; then
    launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT_TARGET" 2>/dev/null || true
    rm -f "$LAUNCH_AGENT_TARGET"
    ok "removed LaunchAgent"
  fi
  if [[ -L "$HAMMERSPOON_TARGET" ]]; then rm "$HAMMERSPOON_TARGET"; ok "removed Hammerspoon symlink"; fi
  if [[ -f "$SUDOERS_TARGET" ]]; then sudo rm -f "$SUDOERS_TARGET"; ok "removed sudoers fragment"; fi
  if [[ -f "$SHELL_RC" ]] && grep -qF "$PROJECT_ROOT/bin" "$SHELL_RC"; then
    sed -i.bak "\|$PROJECT_ROOT/bin|d" "$SHELL_RC"
    ok "removed PATH entry from $SHELL_RC (.bak kept)"
  fi
  note "leaving brew package, tap, and ovpn profiles in place — remove manually if desired:"
  note "  brew uninstall openvpn-aws && brew untap seunghwanly/awsvpnctl"
  note "  rm -rf $PROJECT_ROOT/etc/profiles/*.ovpn"
  exit 0
fi

# ── plan summary ────────────────────────────────────────────────────────────
PENDING=0
PLAN=()
[[ $OPENVPN_DONE  == 0 ]] && { PLAN+=("Build & install patched openvpn (samm-git formula)"); PENDING=$((PENDING+1)); }
[[ $PROFILES_DONE == 0 && ${#DISCOVERED[@]} -gt 0 ]] && { PLAN+=("Copy ${#DISCOVERED[@]} profile(s) into $PROFILES_DIR/"); PENDING=$((PENDING+1)); }
[[ $CONFIG_DONE   == 0 ]] && { PLAN+=("Seed $CONFIG_FILE auto_connect with installed profiles"); PENDING=$((PENDING+1)); }
[[ $SUDOERS_DONE  == 0 ]] && { PLAN+=("Install $SUDOERS_TARGET (sudo password once)"); PENDING=$((PENDING+1)); }
[[ $LAUNCH_DONE   == 0 ]] && { PLAN+=("Install + load LaunchAgent (auto-reconnect daemon)"); PENDING=$((PENDING+1)); }
[[ $HS_DONE       == 0 ]] && { PLAN+=("Symlink Hammerspoon menubar"); PENDING=$((PENDING+1)); }
[[ $PATH_DONE     == 0 ]] && { PLAN+=("Append PATH line to $SHELL_RC"); PENDING=$((PENDING+1)); }

if [[ $PENDING == 0 ]]; then
  title "Already installed"
  echo "  Everything is set up. Try:"
  echo "    awsvpnctl setup        # import/update profiles"
  echo "    awsvpnctl doctor       # verify health"
  echo "    awsvpnctl status       # show profiles"
  exit 0
fi

title "Plan ($PENDING step$([[ $PENDING -gt 1 ]] && echo "s"))"
i=1
for s in "${PLAN[@]}"; do
  printf "  ${C_BOLD}%d.${C_OFF} %s\n" "$i" "$s"
  i=$((i+1))
done

if [[ $CHECK_ONLY == 1 ]]; then
  echo
  note "(--check) not running."
  exit 0
fi

if [[ $ASSUME_YES == 0 ]]; then
  echo
  read -r -p "Proceed? [Y/n] " ans </dev/tty
  case "$ans" in
    n|N|no|NO) echo "aborted."; exit 0 ;;
  esac
fi

# ── do_* steps ──────────────────────────────────────────────────────────────
do_install_openvpn() {
  step "openvpn" "Building patched openvpn (~2 min)"
  # Modern Homebrew rejects bare-path formulae; we host ours in a local tap.
  local tap_name="seunghwanly/awsvpnctl"
  local tap_dir; tap_dir="$(brew --repository)/Library/Taps/seunghwanly/homebrew-awsvpnctl"
  if [[ ! -d "$tap_dir" ]]; then
    note "creating local tap $tap_name"
    brew tap-new --no-git "$tap_name" >/dev/null
  fi
  install -m 0644 "$PROJECT_ROOT/Formula/openvpn-aws.rb" "$tap_dir/Formula/openvpn-aws.rb"
  HOMEBREW_NO_INSTALL_FROM_API=1 brew install --build-from-source "${tap_name}/openvpn-aws"
  [[ -x "$OPENVPN_AWS_BIN" ]] || die "openvpn build failed (binary not found at $OPENVPN_AWS_BIN)"
  ok "$OPENVPN_AWS_BIN"
  note "$("$OPENVPN_AWS_BIN" --version 2>&1 | head -1)"
}

do_copy_profiles() {
  step "profiles" "Copying ${#DISCOVERED[@]} profile(s)"
  for i in "${!DISCOVERED[@]}"; do
    local src="${DISCOVERED[$i]}" name="${SUGGESTED_NAMES[$i]}"
    local dst="$PROFILES_DIR/${name}.ovpn"
    cp "$src" "$dst"
    chmod 600 "$dst"
    ok "${name}.ovpn"
  done
}

do_seed_config() {
  step "config" "Seeding etc/config.json auto_connect"
  /usr/bin/python3 - "$CONFIG_FILE" "$PROFILES_DIR" <<'PY'
import json, sys
from pathlib import Path
cfg_path = Path(sys.argv[1])
profiles_dir = Path(sys.argv[2])
profiles = sorted(p.stem for p in profiles_dir.glob("*.ovpn"))
try:
    cfg = json.loads(cfg_path.read_text())
except Exception:
    cfg = {}
cfg["auto_connect"] = profiles
cfg.setdefault("_doc", {
    "auto_connect": "Profiles auto-connected by the daemon after `aws sso login`. Edit freely.",
    "profiles": "Auto-discovered from etc/profiles/*.ovpn (basename = profile name).",
})
cfg_path.parent.mkdir(parents=True, exist_ok=True)
cfg_path.write_text(json.dumps(cfg, indent=2) + "\n")
print(f"  set auto_connect = {profiles}")
PY
}

do_install_sudoers() {
  step "sudoers" "Installing $SUDOERS_TARGET"
  local rendered; rendered="$(mktemp)"
  sed -e "s|{{USER}}|${USER_NAME}|g" \
      -e "s|{{SUDO_RUNNER}}|${SUDO_RUNNER}|g" \
      "$PROJECT_ROOT/share/sudoers.aws-vpn-connector" > "$rendered"
  sudo visudo -cf "$rendered" >/dev/null
  sudo install -m 0440 -o root -g wheel "$rendered" "$SUDOERS_TARGET"
  rm -f "$rendered"
  if check_sudo_works; then
    ok "passwordless sudo verified"
  else
    fail "sudo runner check failed — verify $SUDOERS_TARGET manually"
  fi
}

do_install_launchagent() {
  step "launchd" "Installing LaunchAgent"
  mkdir -p "$LAUNCH_AGENT_DIR"
  local rendered; rendered="$(mktemp)"
  sed -e "s|{{AWSVPNCTL_BIN}}|${AWSVPNCTL_BIN}|g" \
      -e "s|{{LOG_DIR}}|${LOG_DIR}|g" \
      "$PROJECT_ROOT/share/com.awsvpnctl.daemon.plist" > "$rendered"
  if launchctl print "gui/$(id -u)/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1; then
    launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT_TARGET" 2>/dev/null || true
  fi
  install -m 0644 "$rendered" "$LAUNCH_AGENT_TARGET"
  rm -f "$rendered"
  launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT_TARGET"
  ok "loaded — logs at $LOG_DIR/daemon.log"
}

do_install_hammerspoon() {
  step "hammerspoon" "Wiring up menubar"
  mkdir -p "$HAMMERSPOON_DIR"
  if [[ -L "$HAMMERSPOON_TARGET" ]]; then
    rm "$HAMMERSPOON_TARGET"
  elif [[ -f "$HAMMERSPOON_TARGET" ]]; then
    local backup="$HAMMERSPOON_TARGET.backup-$(date +%Y%m%d-%H%M%S)"
    mv "$HAMMERSPOON_TARGET" "$backup"
    note "backup: $backup"
  fi
  ln -s "$PROJECT_ROOT/hammerspoon/awsvpnctl_hammerspoon.lua" "$HAMMERSPOON_TARGET"
  ok "$HAMMERSPOON_TARGET → hammerspoon/awsvpnctl_hammerspoon.lua"

  if [[ ! -f "$HAMMERSPOON_DIR/init.lua" ]] || ! grep -q "awsvpnctl_hammerspoon" "$HAMMERSPOON_DIR/init.lua"; then
    echo 'require("awsvpnctl_hammerspoon")' >> "$HAMMERSPOON_DIR/init.lua"
    ok "added require() to init.lua"
  fi

  if pgrep -x Hammerspoon >/dev/null; then
    osascript -e 'tell application "Hammerspoon" to execute lua code "hs.reload()"' 2>/dev/null \
      && ok "Hammerspoon reloaded" \
      || note "could not reload via AppleScript — open Hammerspoon → Reload Config"
  else
    note "Hammerspoon is not running — open it to see the menubar item"
  fi
}

do_path_update() {
  step "PATH" "Adding bin/ to $SHELL_RC"
  echo "" >> "$SHELL_RC"
  echo "$PATH_LINE" >> "$SHELL_RC"
  ok "appended"
  note "open a new terminal (or: source $SHELL_RC) for it to take effect"
}

# ── execute ─────────────────────────────────────────────────────────────────
[[ $OPENVPN_DONE  == 0 ]] && do_install_openvpn
[[ $PROFILES_DONE == 0 && ${#DISCOVERED[@]} -gt 0 ]] && do_copy_profiles
[[ $CONFIG_DONE   == 0 ]] && do_seed_config
[[ $SUDOERS_DONE  == 0 ]] && do_install_sudoers
[[ $LAUNCH_DONE   == 0 ]] && do_install_launchagent
[[ $HS_DONE       == 0 ]] && do_install_hammerspoon
[[ $PATH_DONE     == 0 ]] && do_path_update

# ── verify ──────────────────────────────────────────────────────────────────
title "Done"
"$PROJECT_ROOT/bin/awsvpnctl" doctor || true

cat <<EOF

  Try it:
    ${C_BOLD}awsvpnctl setup${C_OFF}        # import/update .ovpn profiles and auto-connect list
    ${C_BOLD}awsvpnctl status${C_OFF}
    ${C_BOLD}awsvpnctl connect $(ls "$PROFILES_DIR" 2>/dev/null | head -1 | sed 's/\.ovpn$//')${C_OFF}
    ${C_BOLD}aws sso login --sso-session Frontend_Developer${C_OFF}     # daemon auto-connects
EOF
