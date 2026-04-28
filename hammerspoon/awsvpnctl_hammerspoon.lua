-- awsvpnctl_hammerspoon.lua
-- Menubar item for awsvpnctl. Polls `awsvpnctl status --json` and
-- exposes per-profile connect/disconnect actions in the dropdown.
--
-- Replaces the legacy AWS-config-watching variant: this one shows ACTUAL VPN
-- tunnel state (utun + openvpn pid), not whether profiles exist in ~/.aws/config.

_G.AWSVPNCTL_HAMMERSPOON = _G.AWSVPNCTL_HAMMERSPOON or {}
local M = _G.AWSVPNCTL_HAMMERSPOON

if M.cleanup then
  M.cleanup()
end

local HOME = os.getenv("HOME")

local function detectProjectRoot()
  local candidates = {
    HOME .. "/dev/awsvpnctl",
    HOME .. "/Dev/awsvpnctl",
    HOME .. "/Documents/awsvpnctl",
    HOME .. "/dev/aws-vpn-connector",
    HOME .. "/Dev/aws-vpn-connector",
    HOME .. "/Documents/aws-vpn-connector",
  }
  for _, root in ipairs(candidates) do
    if hs.fs.attributes(root .. "/bin/awsvpnctl") then
      return root
    end
  end
  return HOME .. "/dev/awsvpnctl"
end

local function detectCtl(projectRoot)
  local candidates = {
    "/opt/homebrew/bin/awsvpnctl",
    "/usr/local/bin/awsvpnctl",
    projectRoot .. "/bin/awsvpnctl",
  }
  for _, path in ipairs(candidates) do
    if hs.fs.attributes(path) then
      return path
    end
  end
  return projectRoot .. "/bin/awsvpnctl"
end

local function detectDaemonLog(projectRoot)
  local candidates = {
    "/opt/homebrew/var/log/awsvpnctl/daemon.log",
    "/usr/local/var/log/awsvpnctl/daemon.log",
    projectRoot .. "/log/daemon.log",
  }
  for _, path in ipairs(candidates) do
    if hs.fs.attributes(path) then
      return path
    end
  end
  return projectRoot .. "/log/daemon.log"
end

local PROJECT_ROOT = detectProjectRoot()

local CONFIG = {
  PROJECT_ROOT = PROJECT_ROOT,
  CTL = detectCtl(PROJECT_ROOT),
  DAEMON_LOG = detectDaemonLog(PROJECT_ROOT),
  POLL_INTERVAL = 5,        -- seconds between status polls
  ACTION_FLASH_SECONDS = 0.4,
  QUICK_PROFILES = { "dev", "prd" },
  DISPLAY_NAMES = {
    prod = "prd",
  },
  COMMAND_NAMES = {
    prod = "prd",
  },
  ICONS = {
    CONNECTED = "🥝",
    DISCONNECTED = "💥",
    BUSY = "🏃",
    NO_CONFIG = "❓",
  },
}

local CTL = CONFIG.CTL

local function displayProfile(profile)
  return CONFIG.DISPLAY_NAMES[profile] or profile
end

local function commandProfile(profile)
  return CONFIG.COMMAND_NAMES[profile] or profile
end

local function shellQuote(s)
  return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function fmtDuration(sec)
  if not sec or sec < 1 then return "" end
  if sec < 60 then return sec .. "s" end
  if sec < 3600 then return math.floor(sec / 60) .. "m" end
  local h = math.floor(sec / 3600)
  local m = math.floor((sec % 3600) / 60)
  return string.format("%dh%02dm", h, m)
end

local function buildTitle(rows)
  if not rows or #rows == 0 then
    return CONFIG.ICONS.NO_CONFIG .. " VPN"
  end
  local parts = {}
  local anyUp = false
  for _, r in ipairs(rows) do
    if r.connected then
      anyUp = true
      table.insert(parts, CONFIG.ICONS.CONNECTED .. string.upper(displayProfile(r.profile)))
    end
  end
  if not anyUp then
    return CONFIG.ICONS.DISCONNECTED .. " VPN"
  end
  return table.concat(parts, " ")
end

local function runCtl(args, callback)
  local cmd = CTL .. " " .. args
  local task = hs.task.new("/bin/sh", function(rc, out, errOut)
    if callback then callback(rc, out or "", errOut or "") end
  end, { "-c", cmd })
  task:start()
  return task
end

-- Force the menubar to update immediately based on a snapshot of rows.
local function setMenu(rows)
  if not M.menuBar then
    M.menuBar = hs.menubar.new()
  end
  local title = buildTitle(rows)
  M.menuBar:setTitle(title)

  local items = {}
  if not rows or #rows == 0 then
    table.insert(items, { title = "No profiles in etc/profiles/", disabled = true })
  else
    for _, r in ipairs(rows) do
      local labelProfile = displayProfile(r.profile)
      local label
      if r.connected then
        local up = r.connected_at and (os.time() - r.connected_at) or nil
        label = string.format("● %s — connected (%s, up %s)",
          labelProfile, r.iface or "?", fmtDuration(up))
      else
        label = string.format("○ %s — disconnected", labelProfile)
      end
      table.insert(items, { title = label, disabled = true })

      if r.connected then
        table.insert(items, {
          title = "      Disconnect " .. labelProfile,
          fn = function() M.actionDisconnect(r.profile) end,
        })
      else
        table.insert(items, {
          title = "      Connect " .. labelProfile,
          fn = function() M.actionConnect(r.profile) end,
        })
      end
    end
  end

  table.insert(items, { title = "-" })
  for _, profile in ipairs(CONFIG.QUICK_PROFILES) do
    table.insert(items, {
      title = "Connect " .. profile,
      fn = function() M.actionConnect(profile) end,
    })
  end
  table.insert(items, {
    title = "Connect dev + prd",
    fn = function() M.actionConnectProfiles(CONFIG.QUICK_PROFILES) end,
  })
  table.insert(items, { title = "-" })
  table.insert(items, {
    title = "Connect all",
    fn = function() M.actionConnectAll() end,
  })
  table.insert(items, {
    title = "Disconnect all",
    fn = function() M.actionDisconnectAll() end,
  })
  table.insert(items, { title = "-" })
  table.insert(items, {
    title = "Refresh",
    fn = function() M.refreshNow() end,
  })
  table.insert(items, {
    title = "Tail daemon log",
    fn = function()
      hs.execute("/usr/bin/open -a Console " ..
                 shellQuote(CONFIG.DAEMON_LOG))
    end,
  })
  table.insert(items, {
    title = "Reload Hammerspoon",
    fn = function() hs.reload() end,
  })

  M.menuBar:setMenu(items)
end

local function setBusyTitle(label)
  if not M.menuBar then
    M.menuBar = hs.menubar.new()
  end
  M.menuBar:setTitle(CONFIG.ICONS.BUSY .. " " .. (label or "…"))
end

function M.refreshNow()
  runCtl("status --json", function(rc, out, errOut)
    if rc ~= 0 then
      print("[awsvpn] status rc=" .. rc .. " err=" .. errOut)
      setMenu({})
      return
    end
    local ok, parsed = pcall(hs.json.decode, out)
    if not ok or not parsed then
      print("[awsvpn] failed to parse status: " .. tostring(out))
      setMenu({})
      return
    end
    setMenu(parsed)
  end)
end

function M.actionConnect(profile)
  local cmdProfile = commandProfile(profile)
  local labelProfile = displayProfile(profile)
  setBusyTitle("connect " .. labelProfile)
  hs.notify.new({
    title = "AWS VPN",
    informativeText = "Connecting " .. labelProfile .. " — browser may open for SSO.",
  }):send()
  runCtl("connect " .. shellQuote(cmdProfile), function(rc, _, errOut)
    if rc ~= 0 then
      hs.notify.new({
        title = "AWS VPN",
        informativeText = "Connect " .. labelProfile .. " failed (rc=" .. rc .. ")",
      }):send()
      print("[awsvpn] connect " .. labelProfile .. " failed: " .. errOut)
    else
      hs.notify.new({
        title = "AWS VPN",
        informativeText = labelProfile .. " connected",
      }):send()
    end
    M.refreshNow()
  end)
end

function M.actionDisconnect(profile)
  local cmdProfile = commandProfile(profile)
  local labelProfile = displayProfile(profile)
  setBusyTitle("disconnect " .. labelProfile)
  runCtl("disconnect " .. shellQuote(cmdProfile), function(_, _, _)
    M.refreshNow()
  end)
end

function M.actionConnectProfiles(profiles)
  for _, profile in ipairs(profiles) do
    M.actionConnect(profile)
  end
end

function M.actionConnectAll()
  -- Use the daemon's auto-connect list via `list` and connect each that is down.
  runCtl("status --json", function(rc, out)
    if rc ~= 0 then return end
    local ok, parsed = pcall(hs.json.decode, out)
    if not ok or not parsed then return end
    for _, r in ipairs(parsed) do
      if not r.connected then
        M.actionConnect(r.profile)
      end
    end
  end)
end

function M.actionDisconnectAll()
  runCtl("status --json", function(rc, out)
    if rc ~= 0 then return end
    local ok, parsed = pcall(hs.json.decode, out)
    if not ok or not parsed then return end
    for _, r in ipairs(parsed) do
      if r.connected then
        M.actionDisconnect(r.profile)
      end
    end
  end)
end

local function setupCaffeineWatcher()
  M.caffeineWatcher = hs.caffeinate.watcher.new(function(eventType)
    local W = hs.caffeinate.watcher
    if eventType == W.screensDidUnlock
        or eventType == W.systemDidWake
        or eventType == W.screensDidWake then
      M.refreshNow()
    end
  end)
  M.caffeineWatcher:start()
end

local function setupReloadHotkey()
  M.reloadHotkey = hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "R", function()
    hs.notify.new({
      title = "Hammerspoon",
      informativeText = "Reloading…",
    }):send()
    hs.reload()
  end)
end

local function initialize()
  if not hs.fs.attributes(CTL) then
    if not M.menuBar then
      M.menuBar = hs.menubar.new()
    end
    M.menuBar:setTitle(CONFIG.ICONS.NO_CONFIG .. " VPN")
    M.menuBar:setMenu({
      { title = "awsvpnctl not installed at " .. CTL, disabled = true },
      { title = "Run awsvpnctl-install or install.sh", disabled = true },
    })
    return
  end

  M.refreshNow()
  M.timer = hs.timer.new(CONFIG.POLL_INTERVAL, M.refreshNow)
  M.timer:start()

  setupCaffeineWatcher()
  setupReloadHotkey()

  print("[awsvpn] menubar initialized (project=" .. CONFIG.PROJECT_ROOT .. ")")
end

function M.cleanup()
  if M.timer then M.timer:stop(); M.timer = nil end
  if M.menuBar then M.menuBar:delete(); M.menuBar = nil end
  if M.caffeineWatcher then M.caffeineWatcher:stop(); M.caffeineWatcher = nil end
  if M.reloadHotkey then M.reloadHotkey:delete(); M.reloadHotkey = nil end
end

initialize()
