-- One hardware press, one living hostile mouseover, one unused raid icon.
local addonName = ...
local V = { status = "Hover an enemy and press Mouse 4.", controls = {} }
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
  return type(key) == "string" and #key <= 60 and key:match("^[A-Z0-9%-]+$")
    and key ~= "BUTTON1" and key ~= "BUTTON2" and key ~= "ESCAPE"
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
      SetOverrideBindingClick(V.button, false, key, "ForeverVanguardCycle", "LeftButton")
      V.activeKey = key
      message("Hover an enemy and press " .. keyLabel(key) .. ".")
    end
  else
    message("Choose a marking key.")
  end
  V.RefreshSettings()
end
function V.SetKey(key)
  if locked() then return false, "Change the key after combat." end
  if key ~= false and not validKey(key) then return false, "Use a keyboard key or mouse side button." end
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
  if locked() then return nil, "Cycling is available out of combat only." end
  if not ForeverVanguardDB.enabled then return nil, "Marking is disabled." end
  local ok, unit = public(SecureCmdOptionParse, "[@mouseover,harm,nodead] mouseover; none")
  if not ok or unit ~= "mouseover" then return nil, "Hover a living enemy first." end
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
local function prepare(self, _, down)
  if down then return end -- release only, independent of ActionButtonUseKeyDown
  if locked() then message("Cycling is available out of combat only.", true); return end
  self:SetAttribute("unit", "none")
  local icon, reason = V.Plan()
  if not icon then message(reason, true); return end
  -- Reserve attempts, not claimed successes. Stops latency/rejected requests from
  -- causing an icon to be reused. New batch releases reservations, never live marks.
  ForeverVanguardCycleDB.reserved[icon] = true
  self:SetAttribute("marker", icon)
  self:SetAttribute("unit", "mouseover")
  message(names[icon] .. " requested. Existing marks are preserved.")
  V.RefreshSettings()
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
  V.enabledButton:SetText(db.enabled and "Enabled" or "Disabled")
  V.keyButton:SetText(V.capturing and "Press a key / mouse button…" or keyLabel(db.key))
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
  text(p, "Hover an enemy. Press your marking button. Move to the next enemy.", 16, -48, 560)
  text(p, "Out of combat only. Pauses where Forever hides available icons.\nAlready-marked mobs are skipped. No macros, target changes or toolbar.", 16, -72, 570)
  V.enabledButton = control(p, "Enabled", 16, -116, 100, function()
    if locked() then return end
    ForeverVanguardDB.enabled = not ForeverVanguardDB.enabled; V.RefreshSettings()
  end)
  text(p, "Marking key", 16, -156, 100)
  V.keyButton = control(p, "", 130, -150, 250, function()
    if locked() then return end
    V.capturing = true; p:EnableKeyboard(true); p:SetPropagateKeyboardInput(false); p:EnableMouse(true)
    message("Press your preferred key or mouse side button. Escape cancels."); V.RefreshSettings()
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
  local b = CreateFrame("Button", "ForeverVanguardCycle", UIParent, "SecureActionButtonTemplate,SecureHandlerBaseTemplate")
  V.button = b
  b:SetSize(1, 1); b:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10000, 10000); b:SetAlpha(0); b:EnableMouse(false)
  b:RegisterForClicks("AnyUp"); b:SetAttribute("useOnKeyDown", false)
  b:SetAttribute("*type1", "raidtarget"); b:SetAttribute("action", "set-unmarked"); b:SetAttribute("unit", "none")
  b:SetScript("PreClick", prepare)
  -- Combat may start after arming: a secure guard always makes the click inert.
  b:WrapScript(b, "OnClick", [[
    if SecureCmdOptionParse("[combat] stop; go") == "stop" then
      self:SetAttribute("unit", "none")
    end
  ]])
  b:SetScript("PostClick", function(self)
    if not locked() then self:SetAttribute("unit", "none") end
  end)
  settings(); V.ApplyBinding()
end
local version, _, _, interface = GetBuildInfo()
V.supported = version == "1.60.1" and interface == 16001
if not V.supported then return end
SLASH_FOREVERVANGUARD1 = "/fv"
SLASH_FOREVERVANGUARD2 = "/vanguard"
SlashCmdList.FOREVERVANGUARD = function()
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
    elseif V.button then V.button:SetAttribute("unit", "none"); V.ApplyBinding() end
  elseif event == "PLAYER_REGEN_DISABLED" then
    V.StopCapture(); V.RefreshSettings()
  elseif event == "UPDATE_BINDINGS" then
    V.ApplyBinding()
  elseif name == addonName then
    message("Marking was blocked by the client: " .. tostring(action), true)
  end
end)
