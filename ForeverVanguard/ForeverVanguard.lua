-- One physical hotkey click per mouseover mark. No synthetic clicks.
local addonName = ...
local V = { status = "Hover an enemy and click Mouse 4.", controls = {} }
ForeverVanguard = V
local defaults = {8, 7, 6, 5, 4, 3, 2, 1}
local names = {"Star", "Circle", "Diamond", "Triangle", "Moon", "Square", "Cross", "Skull"}
local command = "CLICK ForeverVanguardCycle:LeftButton"
local function locked() return InCombatLockdown() end
local function public(fn, ...)
  if type(fn) ~= "function" then return false end
  local ok, value = pcall(fn, ...)
  if not ok or (issecretvalue and issecretvalue(value)) then return false end
  return true, value
end
local function message(text, notify)
  V.status = text
  if V.statusText then V.statusText:SetText(text) end
  if notify and UIErrorsFrame and (not V.lastNotice or GetTime() - V.lastNotice > 2) then
    UIErrorsFrame:AddMessage("Vanguard: " .. text, 1, 0.8, 0.2)
    V.lastNotice = GetTime()
  end
end
local function validKey(key)
  if type(key) ~= "string" then return false end
  local rest = key:gsub("ALT%-", ""):gsub("CTRL%-", ""):gsub("SHIFT%-", "")
  return rest == "BUTTON3" or rest == "BUTTON4" or rest == "BUTTON5"
end
local function keyLabel(key)
  return key and (GetBindingText(key, "KEY_") or key) or "Not bound"
end
function V.ApplyBinding()
  if not V.button then return end
  if locked() then V.pendingBinding = true; return end
  V.pendingBinding = nil
  ClearOverrideBindings(V.button)
  V.activeKey = nil
  local key = ForeverVanguardDB.key
  if key then
    local existing = GetBindingAction(key, true)
    if existing and existing ~= "" and existing ~= command then
      message(keyLabel(key) .. " is already bound. Choose another key in Vanguard settings.")
    else
      V.activeKey = key
      SetOverrideBindingClick(V.button, true, key, "ForeverVanguardCycle", "LeftButton")
      message("Hover an enemy and click " .. keyLabel(key) .. ". Safe cycling is out of combat only.")
    end
  else
    message("Choose a marking key.")
  end
  if not ForeverVanguardDB.enabled then message("Marking disabled. Open /fv report for any blocked-action details.") end
  V.RefreshSettings()
end
function V.SetKey(key)
  if locked() then return false, "Change the key after combat." end
  if key ~= false and not validKey(key) then return false, "Use Mouse 3, 4 or 5, optionally with Alt/Ctrl/Shift." end
  if key then
    local existing = GetBindingAction(key, true)
    if existing and existing ~= "" and existing ~= command then
      return false, keyLabel(key) .. " is already bound. Your existing binding was kept."
    end
  end
  ForeverVanguardDB.key = key
  V.ApplyBinding()
  return true
end
function V.MoveIcon(position, delta)
  if locked() then return end
  local order = ForeverVanguardDB.order
  local other = position + delta
  if not order[position] or not order[other] then return end
  order[position], order[other] = order[other], order[position]
  V.RefreshSettings()
end
function V.SetIconEnabled(icon, enabled)
  if locked() or not names[icon] then return end
  ForeverVanguardDB.disabled[icon] = not enabled or nil
  V.RefreshSettings()
end
function V.NewBatch()
  if locked() then return false end
  ForeverVanguardCycleDB.reserved = {}
  message("New batch. Icons still in use will be skipped.")
  V.RefreshSettings()
  return true
end
-- Fail closed on secrets, missing APIs and errors. Never infer success from a
-- RAID_TARGET_UPDATE event: another player may have caused it.
function V.Plan()
  if not ForeverVanguardDB.enabled then return nil, "Marking is disabled." end
  local unit = "mouseover"
  local existsKnown, exists = public(UnitExists, unit)
  if not existsKnown then return nil, "Mouseover existence is unreadable." end
  if not exists then return nil, "No mouseover unit." end
  local attackKnown, attackable = public(UnitCanAttack, "player", unit)
  if not attackKnown then return nil, "Mouseover hostility is unreadable." end
  if not attackable then return nil, "Mouseover is not attackable." end
  local deadKnown, dead = public(UnitIsDeadOrGhost, unit)
  if not deadKnown then return nil, "Mouseover life state is unreadable." end
  if dead then return nil, "Mouseover is dead." end
  if IsInRaid() and not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
    return nil, "Raid marking requires leader or assistant."
  end
  local readable, mark = public(GetRaidTargetIndex, unit)
  if not readable then return nil, "This mob is marked or its marker is hidden; left unchanged." end
  if mark ~= nil then return nil, "Already marked; left unchanged." end
  local eligible = false
  for _, icon in ipairs(ForeverVanguardDB.order) do
    if not ForeverVanguardDB.disabled[icon] then
      eligible = true
      if not ForeverVanguardCycleDB.reserved[icon] then
        -- No wrap, no reuse of dead mobs' marks; equality means THIS icon is free.
        local known, available = public(GetNextAvailableRaidTargetMarkerIndex, icon, false, false, false)
        if not known then return nil, "Forever is hiding available icons here; marking paused." end
        if type(available) ~= "number" or available < 0 or available > 8 or available % 1 ~= 0 then
          return nil, "Available icons could not be checked; marking paused."
        end
        if available == icon then return icon end
      end
    end
  end
  return nil, eligible and "No unused icons left. Start a new batch in settings after clearing old marks."
    or "Enable at least one icon in Vanguard settings."
end
function V.Log(value)
  if not ForeverVanguardCycleDB then return end
  local log = ForeverVanguardCycleDB.log
  log[#log + 1] = string.format("%.2f combat=%s %s", GetTime(), tostring(locked()), value)
  if #log > 200 then table.remove(log, 1) end
end
function V.StopBlocked(reason)
  ForeverVanguardDB.enabled = false
  V.Log("BLOCKED " .. reason)
  message("Forever blocked secure marking. Disabled; /fv report has details.", true)
  V.RefreshSettings()
end
local function completeAttempt()
  local attempt = V.pending
  if not attempt then return end
  V.pending = nil
  local known, guid = public(UnitGUID, "mouseover")
  if not known or guid ~= attempt.guid then V.Log("UNVERIFIED: mouseover changed"); return end
  local readable, mark = public(GetRaidTargetIndex, "mouseover")
  if not readable then V.Log("UNVERIFIED: marker hidden"); return end
  if mark == attempt.icon then
    V.Log("CONFIRMED icon=" .. attempt.icon)
    message(names[attempt.icon] .. " confirmed.")
  else
    V.Log("NOT APPLIED icon=" .. attempt.icon)
    -- A silent rejection must not burn through the other seven icons.
    V.StopBlocked("secure request did not apply")
  end
end
-- Only PreClick on a hardware-bound secure button prepares a mark. The
-- inherited Blizzard handler performs it; addon Lua never invokes Click().
function V.PreClick(self)
  V.attempting = false
  if locked() then
    message("Safe icon cycling is unavailable in combat.", true)
    V.Log("SKIP combat: safe cycling unavailable")
    return
  end
  self:SetAttribute("type", nil)
  completeAttempt()
  if V.capturing or V.panel:IsVisible() then return end
  local icon, reason = V.Plan()
  if not icon then message(reason); V.Log("SKIP " .. reason); return end
  local known, guid = public(UnitGUID, "mouseover")
  if not known or not guid then message("Mouseover GUID is unreadable."); return end
  ForeverVanguardCycleDB.reserved[icon] = true
  V.pending = {guid = guid, icon = icon, at = GetTime()}
  self:SetAttribute("marker", icon)
  self:SetAttribute("type", "raidtarget")
  V.attempting = true
  V.Log("ATTEMPT route=hardware-click icon=" .. icon)
end
function V.PostClick(self)
  V.attempting = false
  if not locked() then self:SetAttribute("type", nil) end
end
local function text(parent, value, x, y, width, font)
  local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
  label:SetPoint("TOPLEFT", x, y); label:SetWidth(width); label:SetJustifyH("LEFT"); label:SetText(value)
  return label
end
local function control(parent, title, x, y, width, callback)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetPoint("TOPLEFT", x, y); b:SetSize(width, 24); b:SetText(title); b:SetScript("OnClick", callback)
  V.controls[#V.controls + 1] = b
  return b
end
function V.RefreshSettings()
  if not V.panel then return end
  local db = ForeverVanguardDB
  for _, c in ipairs(V.controls) do c:SetEnabled(not locked()) end
  V.enabledButton:SetEnabled(true)
  V.enabledButton:SetText(db.enabled and "Enabled" or "Disabled")
  V.keyButton:SetText(V.capturing and "Press Mouse 3 / 4 / 5…" or keyLabel(db.key))
  for i, row in ipairs(V.rows) do
    local icon = db.order[i]
    row.label:SetText(i .. ".  |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_" .. icon .. ":18|t " .. names[icon])
    row.toggle:SetText(db.disabled[icon] and "Off" or "On")
    row.up:SetEnabled(not locked() and i > 1)
    row.down:SetEnabled(not locked() and i < 8)
  end
  V.statusText:SetText(V.status)
end
function V.StopCapture()
  V.capturing = false
  if V.panel then V.panel:EnableKeyboard(false); V.panel:EnableMouse(false) end
  V.RefreshSettings()
end
function V.CaptureKey(key)
  if not V.capturing then return end
  if key == "ESCAPE" then V.StopCapture(); return end
  if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then return end
  local prefix = (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "") .. (IsShiftKeyDown() and "SHIFT-" or "")
  local ok, reason = V.SetKey(prefix .. key)
  V.StopCapture()
  if not ok then message(reason) end
end
local function settings()
  local p = CreateFrame("Frame"); p.name = "Forever Vanguard"; p:Hide(); V.panel = p
  text(p, "Forever Vanguard", 16, -16, 500, "GameFontNormalLarge")
  text(p, "Hover a living enemy, then click your mouse button once to mark it.", 16, -48, 560)
  text(p, "One click per mob. Safe icon cycling is out of combat only.\nSkips occupied/hidden icons; stops if Forever rejects marking.", 16, -72, 570)
  V.enabledButton = control(p, "Enabled", 16, -116, 100, function()
    ForeverVanguardDB.enabled = not ForeverVanguardDB.enabled; V.RefreshSettings()
  end)
  text(p, "Marking key", 16, -156, 100)
  V.keyButton = control(p, "", 130, -150, 250, function()
    if locked() then return end
    V.capturing = true; p:EnableKeyboard(true); p:SetPropagateKeyboardInput(false); p:EnableMouse(true)
    message("Press Mouse 3, 4 or 5 with optional modifiers. Escape cancels."); V.RefreshSettings()
  end)
  control(p, "Unbind", 390, -150, 85, function() V.SetKey(false) end)
  p:SetScript("OnKeyDown", function(_, key) V.CaptureKey(key) end)
  p:SetScript("OnMouseDown", function(_, button)
    local key = button:match("^Button(%d+)$")
    if key then V.CaptureKey("BUTTON" .. key)
    elseif V.capturing then message("Use a side button or keyboard key. Escape cancels.") end
  end)
  p:SetScript("OnHide", V.StopCapture)
  p:SetScript("OnShow", V.RefreshSettings)
  text(p, "Icon order", 16, -196, 500, "GameFontNormal")
  text(p, "Turn icons off or move them up/down. Used icons are never moved to a new mob.", 16, -218, 570)
  V.rows = {}
  for i = 1, 8 do
    local y = -244 - (i - 1) * 29
    local row = {label = text(p, "", 20, y - 3, 200)}
    row.toggle = control(p, "", 230, y, 60, function()
      local icon = ForeverVanguardDB.order[i]; V.SetIconEnabled(icon, ForeverVanguardDB.disabled[icon] == true)
    end)
    row.up = control(p, "Up", 300, y, 60, function() V.MoveIcon(i, -1) end)
    row.down = control(p, "Down", 370, y, 60, function() V.MoveIcon(i, 1) end)
    V.rows[i] = row
  end
  control(p, "Start new batch", 16, -484, 145, V.NewBatch)
  text(p, "Does not clear marks. Releases reserved icons; live marks are still skipped.", 175, -488, 400)
  V.statusText = text(p, V.status, 16, -525, 570)
  V.recoveryButton = control(p, "Restore old attack buttons", 16, -562, 230, function()
    if V.RestoreLegacy then local _, result = V.RestoreLegacy(); message(result) end
  end)
  V.recoveryButton:SetShown(type(ForeverVanguardActionsDB) == "table" and next(ForeverVanguardActionsDB) ~= nil)
  V.category = Settings.RegisterCanvasLayoutCategory(p, p.name)
  Settings.RegisterAddOnCategory(V.category)
  V.RefreshSettings()
end
local function build()
  local db = type(ForeverVanguardDB) == "table" and ForeverVanguardDB or {}
  ForeverVanguardDB = db
  if type(db.enabled) ~= "boolean" then db.enabled = true end
  if db.key ~= false and not validKey(db.key) then db.key = "BUTTON4" end
  local order, seen = {}, {}
  if type(db.order) == "table" then
    for _, icon in ipairs(db.order) do
      if type(icon) == "number" and names[icon] and not seen[icon] then order[#order + 1] = icon; seen[icon] = true end
    end
  end
  for _, icon in ipairs(defaults) do if not seen[icon] then order[#order + 1] = icon end end
  db.order = order
  local disabled = {}
  if type(db.disabled) == "table" then for icon = 1, 8 do if db.disabled[icon] == true then disabled[icon] = true end end end
  db.disabled = disabled
  ForeverVanguardCycleDB = type(ForeverVanguardCycleDB) == "table" and ForeverVanguardCycleDB or {}
  local reserved = {}
  if type(ForeverVanguardCycleDB.reserved) == "table" then
    for icon = 1, 8 do if ForeverVanguardCycleDB.reserved[icon] == true then reserved[icon] = true end end
  end
  ForeverVanguardCycleDB.reserved = reserved
  ForeverVanguardCycleDB.log = type(ForeverVanguardCycleDB.log) == "table" and ForeverVanguardCycleDB.log or {}
  local b = CreateFrame("Button", "ForeverVanguardCycle", UIParent, "SecureActionButtonTemplate")
  b:SetSize(1, 1); b:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10000, 10000)
  b:SetAlpha(0); b:EnableMouse(false); b:RegisterForClicks("AnyUp")
  b:SetAttribute("useOnKeyDown", false)
  b:SetAttribute("action", "set-unmarked")
  b:SetAttribute("unit", "mouseover")
  b:SetScript("PreClick", V.PreClick)
  b:SetScript("PostClick", V.PostClick)
  -- Also guard the secure handler itself: combat can start after preparation.
  -- No combat click may execute a stale marker prepared outside combat.
  SecureHandlerWrapScript(b, "OnClick", b, [[
    if SecureCmdOptionParse("[combat] stop; go") == "stop" then return false end
  ]])
  V.button = b
  local _, clientBuild = GetBuildInfo()
  V.Log("SESSION 0.2.6 build=" .. clientBuild .. " route=hardware-click")
  settings(); V.ApplyBinding()
end
local version, _, _, interface = GetBuildInfo()
V.supported = version == "1.60.1" and interface == 16001
if not V.supported then return end
SLASH_FOREVERVANGUARD1 = "/fv"
SLASH_FOREVERVANGUARD2 = "/vanguard"
SlashCmdList.FOREVERVANGUARD = function(commandText)
  if commandText == "off" then
    if ForeverVanguardDB then ForeverVanguardDB.enabled = false; V.RefreshSettings() end
    return
  elseif commandText == "report" and ForeverVanguardCycleDB then
    local f = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(650, 450); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG")
    f.TitleText:SetText("Forever Vanguard — diagnostic report")
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 15, -35); scroll:SetPoint("BOTTOMRIGHT", -35, 15)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true); edit:SetFontObject(ChatFontNormal); edit:SetWidth(590)
    edit:SetAutoFocus(false); edit:SetText(table.concat(ForeverVanguardCycleDB.log, "\n"))
    scroll:SetScrollChild(edit); edit:SetFocus(); edit:HighlightText()
    edit:SetScript("OnEscapePressed", function() f:Hide() end)
    return
  end
  if V.category then Settings.OpenToCategory(V.category:GetID()) end
end
local events = CreateFrame("Frame")
for _, event in ipairs({"ADDON_LOADED", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "UPDATE_BINDINGS", "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent", function(_, event, name, action)
  if event == "ADDON_LOADED" then
    if name ~= addonName or V.button then return end
    if locked() then V.waiting = true else build() end
  elseif event == "PLAYER_REGEN_ENABLED" then
    if V.waiting then V.waiting = nil; build()
    elseif V.button then V.button:SetAttribute("type", nil); V.ApplyBinding() end
  elseif event == "PLAYER_REGEN_DISABLED" then
    V.StopCapture(); V.RefreshSettings()
  elseif event == "UPDATE_BINDINGS" then
    V.ApplyBinding()
  elseif V.button and (name == addonName or V.attempting) then
    local detail = (issecretvalue and issecretvalue(action)) and "hidden action" or tostring(action)
    V.StopBlocked(event .. " " .. detail)
  end
end)

local elapsed = 0
events:SetScript("OnUpdate", function(_, dt)
  elapsed = elapsed + dt
  if elapsed >= 0.1 then
    elapsed = 0
    if V.pending and GetTime() - V.pending.at >= 0.2 then completeAttempt() end
  end
end)
