-- Forever Vanguard: explicit secure marking, never combat-log automation.
local addonName = ...
local V = { buttons = {}, modes = {}, bindings = {}, diagnostics = { inputs = 0, markerUpdates = 0 } }
ForeverVanguard = V
local routes = {
  mouseover = "[@mouseover,harm,nodead] mouseover; none",
}
local labels = { mouseover = "Mouseover only" }
local marks = {
  {8, "Skull", "First kill"}, {7, "Cross", "Second kill"},
  {6, "Square", "Add / trap"}, {4, "Triangle", "Add"},
  {3, "Diamond", "Add"}, {2, "Circle", "Add"},
  {1, "Star", "Add"}, {5, "Moon", "Crowd control"}, {0, "Clear", "Remove mark"},
}
-- Resolved on the hardware click, not on a timer or an insecure PreClick hook.
local routeClick = [[
  local unit = SecureCmdOptionParse(self:GetAttribute("route"))
  self:SetAttribute("unit", unit or "none")
]]
local function say(text) print("|cffd7b678Vanguard:|r " .. text) end
local function locked() return InCombatLockdown() end
local function label(parent, text, x, y, width, font)
  local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
  fs:SetPoint("TOPLEFT", x, y); fs:SetWidth(width); fs:SetJustifyH("LEFT"); fs:SetText(text)
  return fs
end
local function tooltip(self, title, detail)
  GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(title)
  GameTooltip:AddLine(detail, 0.85, 0.87, 0.90, true); GameTooltip:Show()
end
-- UI feedback may inspect public values only; secret combat data never drives actions.
local function read(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, value = pcall(fn, ...)
  if not ok or (issecretvalue and issecretvalue(value)) then return nil end
  return value
end
function V.RefreshBindings()
  for _, entry in ipairs(V.bindings) do
    local key = read(GetBindingKey, "CLICK " .. entry.name .. ":LeftButton")
    if not key and entry.name == "ForeverVanguardQuick" then key = V.shortcut end
    local badges = {ForeverVanguardMark8="", ForeverVanguardMark7="S-", ForeverVanguardMark5="C-", ForeverVanguardMark6="A-"}
    local text = key and (read(GetBindingText, key, "KEY_", 1) or key) or ""
    if not key and V.shortcut and badges[entry.name] then text = badges[entry.name] .. V.shortcut end
    entry.label:SetText(text)
  end
end
-- Session-only shortcuts: never overwrite or persist changes to the player's bindings.
local quickCommand = "CLICK ForeverVanguardQuick:LeftButton"
local keyPrefixes = {"", "SHIFT-", "CTRL-", "ALT-"}
function V.ConfigureKeys()
  if not V.frame or V.configuringKeys then return end
  if locked() then V.pendingKeys = true; return end
  V.pendingKeys = nil; V.configuringKeys = true
  if not V.bindingOwner then V.bindingOwner = CreateFrame("Frame") end
  ClearOverrideBindings(V.bindingOwner)
  V.shortcut = nil
  local assigned = GetBindingKey(quickCommand)
  if not assigned and ForeverVanguardDB.shortcut ~= false then
    local candidates = ForeverVanguardDB.shortcut and {ForeverVanguardDB.shortcut} or {"F6", "F7", "F8", "F9"}
    for _, key in ipairs(candidates) do
      local free = true
      for _, prefix in ipairs(keyPrefixes) do
        local action = GetBindingAction(prefix .. key, true)
        if action and action ~= "" then free = false; break end
      end
      if free then
        for _, prefix in ipairs(keyPrefixes) do SetOverrideBindingClick(V.bindingOwner, false, prefix .. key, "ForeverVanguardQuick", "LeftButton") end
        V.shortcut = key; break
      end
    end
  end
  V.configuringKeys = nil
  V.RefreshBindings()
  V.Refresh()
end
function V.Bind(key)
  if locked() then say("Change the shortcut after combat."); return false end
  key = (key or ""):upper()
  if key == "OFF" then ForeverVanguardDB.shortcut = false; V.ConfigureKeys(); return true end
  if not key:match("^F%d%d?$") or tonumber(key:sub(2)) < 1 or tonumber(key:sub(2)) > 12 then
    say("Use /fv bind F6 (F1–F12), or /fv bind off."); return false
  end
  for _, prefix in ipairs(keyPrefixes) do
    local action = GetBindingAction(prefix .. key, true)
    if action and action ~= "" and action ~= quickCommand then say(prefix .. key .. " is already bound; nothing changed."); return false end
  end
  ForeverVanguardDB.shortcut = key; V.ConfigureKeys(); return true
end
function V.RefreshTarget()
  if not V.destination then return end
  local unit = read(SecureCmdOptionParse, routes[ForeverVanguardDB.mode])
  if not unit then V.destination:SetText("Destination checked on keypress"); return end
  if unit == "none" then V.destination:SetText("Hover an enemy; press its marking key"); return end
  local name = read(UnitName, unit)
  if type(name) ~= "string" then name = "Enemy" else name = name:gsub("|", "||") end
  V.destination:SetText("Mouseover: " .. name)
end
function V.PullMacro(spell)
  -- Spell names are text, never executable slash commands or extra conditionals.
  if type(spell) ~= "string" then return nil end
  spell = spell:match("^%s*(.-)%s*$")
  if spell == "" or #spell > 80 or spell:find("[%c%[%];|/\\]") then return nil end
  local condition = "[@mouseover,harm,nodead][@target,harm,nodead]"
  -- ~8 is Blizzard's preserve-existing-mark form, not an insecure /run action.
  local macro = "#showtooltip " .. spell .. "\n/targetmarker " .. condition .. " ~8\n/cast " .. condition .. " " .. spell
  if #macro > 255 then return nil end
  return macro
end
-- Prepare the native mark-and-cast macro; never execute it from addon code.
function V.CreatePullAction(spell)
  if locked() then return nil, "Create the action after combat." end
  local body = V.PullMacro(spell)
  if not body then return nil, "Enter an ability name that fits the macro limit." end
  if GetCursorInfo() then return nil, "Put down the item on your cursor first." end
  for n = 1, 30 do
    local name = "Vanguard Pull" .. n
    local index = GetMacroIndexByName(name)
    if index == 0 or GetMacroBody(index) == body then
      if index == 0 then
        local ok, created = pcall(CreateMacro, name, "INV_MISC_QUESTIONMARK", body, true)
        if not ok or not created or created == 0 then return nil, "Could not create a character macro. Check free macro slots." end
        index = created
      end
      PickupMacro(index)
      return index, "Place this macro on your opener's action-bar slot."
    end
  end
  return nil, "No unused Vanguard macro name; existing macros were preserved."
end
function V.ShowSetup(macro, spell)
  if locked() then say("Open setup after combat."); return end
  if not V.setup then
    local f = CreateFrame("Frame", "ForeverVanguardSetup", UIParent, "BasicFrameTemplateWithInset")
    V.setup = f
    f:SetSize(470, 340); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG"); f:SetClampedToScreen(true)
    f.TitleText:SetText("Vanguard • Mark with your opening ability")
    label(f, "Enter your opening ability's exact name. This action marks Skull and casts on mouseover, or your main target if no valid mouseover exists.", 18, -40, 428)
    f.spell = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    f.spell:SetPoint("TOPLEFT", 24, -86); f.spell:SetSize(310, 24); f.spell:SetAutoFocus(false); f.spell:SetMaxLetters(80)
    f.spell:SetText("")
    local preview = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    preview:SetSize(100,24); preview:SetPoint("TOPLEFT", 346, -86); preview:SetText("Preview")
    f.copy = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    f.copy:SetPoint("TOPLEFT", 24, -128); f.copy:SetSize(420, 94)
    f.copy:SetMultiLine(true); f.copy:SetAutoFocus(false); f.copy:SetFontObject(GameFontHighlightSmall)
    f.copy:SetMaxLetters(255); f.copy:SetScript("OnEscapePressed", function(self) self:ClearFocus(); f:Hide() end)
    f.copy:SetText("")
    f.message = label(f, "One-time setup: replace your opener's button with this macro. Then use your normal ability key.", 18, -264, 428)
    local function updatePreview()
      local body = V.PullMacro(f.spell:GetText())
      f.copy:SetText(body or "Ability name missing or macro too long.")
    end
    preview:SetScript("OnClick", updatePreview); f.spell:SetScript("OnEnterPressed", updatePreview)
    f.spell:SetScript("OnEscapePressed", function(self) self:ClearFocus(); f:Hide() end)
    f.create = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.create:SetSize(240,26); f.create:SetPoint("TOPLEFT", 18, -230); f.create:SetText("Create & pick up action")
    f.create:SetScript("OnClick", function()
      updatePreview()
      local _, message = V.CreatePullAction(f.spell:GetText()); f.message:SetText(message)
    end)
    label(f, "Keeps existing marks. Marking can happen even if the cast fails.", 18, -310, 428)
    if UISpecialFrames then table.insert(UISpecialFrames, "ForeverVanguardSetup") end
  end
  V.setup:Show()
  if spell then V.setup.spell:SetText(spell) end
  if macro then V.setup.copy:SetText(macro) end
end
function V.Report()
  local version, build, _, interface = GetBuildInfo()
  local key = read(GetBindingKey, quickCommand) or V.shortcut or "none"
  return "Forever Vanguard 0.1.0-alpha.4\nClient: " .. tostring(version) .. " / build " .. tostring(build) .. " / interface " .. tostring(interface)
    .. "\nRoute: living hostile mouseover only\nShortcut: " .. key
    .. "\nInput releases seen: " .. V.diagnostics.inputs
    .. "\nRaid marker update events: " .. V.diagnostics.markerUpdates
    .. "\nLast blocked action: " .. (V.diagnostics.blocked or "none observed")
    .. "\nEvents confirm input/update activity, not that a particular mob was marked."
end
function V.ShowReport()
  if locked() then say("Open the report after combat."); return end
  if not V.reportFrame then
    local f = CreateFrame("Frame", "ForeverVanguardReport", UIParent, "BasicFrameTemplateWithInset")
    V.reportFrame = f; f:SetSize(500, 300); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG"); f:SetClampedToScreen(true)
    f.TitleText:SetText("Vanguard • Test report")
    label(f, "Hover an enemy and use the displayed key, then reopen this report. Copy the text below if marking fails.", 18, -38, 460)
    f.copy = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    f.copy:SetPoint("TOPLEFT", 24, -90); f.copy:SetSize(450, 180)
    f.copy:SetMultiLine(true); f.copy:SetAutoFocus(false); f.copy:SetFontObject(GameFontHighlightSmall); f.copy:SetMaxLetters(4096)
    f.copy:SetScript("OnEscapePressed", function(self) self:ClearFocus(); f:Hide() end)
    if UISpecialFrames then table.insert(UISpecialFrames, "ForeverVanguardReport") end
  end
  V.reportFrame.copy:SetText(V.Report()); V.reportFrame:Show(); V.reportFrame.copy:SetFocus(); V.reportFrame.copy:HighlightText()
end
local function recordInput(_, _, down)
  if not down then V.diagnostics.inputs = V.diagnostics.inputs + 1 end
end
function V.Refresh()
  if not V.frame then return end
  local combat = locked()
  V.state:SetText(combat and "Combat" or "")
  V.state:SetTextColor(combat and 1 or 0.45, combat and 0.63 or 0.82, 0.50)
  for mode, button in pairs(V.modes) do
    button:SetEnabled(not combat)
    if ForeverVanguardDB.mode == mode then button:LockHighlight() else button:UnlockHighlight() end
  end
  if V.hint then
    local key = read(GetBindingKey, quickCommand) or V.shortcut
    V.hint:SetText(key and ("Hover + " .. key .. "  •  Shift: X  Ctrl: Moon  Alt: Square") or "Mark with your opener: /fv pull")
  end
  V.permission:SetText(IsInRaid() and not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player"))
    and "Raid marks require leader or assistant."
    or "Quick mark keeps marks. Shift + icon replaces.")
end
function V.SetMode(mode)
  if not routes[mode] then return false end
  if locked() then say("Change targeting mode after combat. Your mark keys still work."); return false end
  ForeverVanguardDB.mode = mode
  for _, button in ipairs(V.buttons) do button:SetAttribute("route", routes[mode]) end
  V.Refresh(); V.RefreshTarget()
  return true
end
function V.Toggle()
  if not V.frame then return end
  if locked() then V.pendingToggle = not V.pendingToggle; say("Bar toggle queued until combat ends; use the X to close now."); return end
  ForeverVanguardDB.visible = not V.frame:IsShown()
  V.frame:SetShown(ForeverVanguardDB.visible)
end
function V.Reset()
  if locked() then say("Reset the bar after combat."); return end
  ForeverVanguardDB.x, ForeverVanguardDB.y = 0, -170
  ForeverVanguardDB.visible = true
  V.frame:ClearAllPoints(); V.frame:SetPoint("CENTER", UIParent, "CENTER", 0, -170); V.frame:Show()
end
local function build()
  local db = type(ForeverVanguardDB) == "table" and ForeverVanguardDB or {}
  ForeverVanguardDB = db
  db.mode = "mouseover" -- Migrate older saved modes: target fallback is no longer supported.
  if db.shortcut ~= false and (type(db.shortcut) ~= "string" or not db.shortcut:match("^F%d%d?$") or tonumber(db.shortcut:sub(2)) < 1 or tonumber(db.shortcut:sub(2)) > 12) then db.shortcut = nil end
  if db.shortcut == nil then db.shortcut = false end
  if type(db.visible) ~= "boolean" then db.visible = false end
  local function coordinate(value)
    return type(value) == "number" and value == value and math.abs(value) < 5000 and value or 0
  end
  db.x, db.y = coordinate(db.x), db.y == nil and -170 or coordinate(db.y)
  local frame = CreateFrame("Frame", "ForeverVanguardBar", UIParent, "BackdropTemplate")
  V.frame = frame
  frame:SetSize(380, 144); frame:SetPoint("CENTER", UIParent, "CENTER", db.x, db.y)
  frame:SetFrameStrata("MEDIUM"); frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true)
  frame:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=16, insets={left=4,right=4,top=4,bottom=4}})
  frame:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
  frame:SetScript("OnHide", function() db.visible = false; V.pendingToggle = nil end)
  frame:SetScript("OnShow", function() db.visible = true end)
  -- Hardware-driven secure hide is allowed even when the bar has protected children.
  local close = CreateFrame("Button", "ForeverVanguardClose", frame, "SecureHandlerClickTemplate")
  V.close = close
  close:SetSize(24, 24); close:SetPoint("TOPRIGHT", -5, -5)
  close:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
  close:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
  close:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
  close:SetAttribute("_onclick", "self:GetParent():Hide()")
  close:SetScript("OnEnter", function(self) tooltip(self, "Close Vanguard", "Reopen with /fv after combat. Your marking keybinds remain assigned.") end)
  close:SetScript("OnLeave", function() GameTooltip:Hide() end)
  local drag = CreateFrame("Frame", nil, frame)
  drag:SetPoint("TOPLEFT", 8, -5); drag:SetSize(260, 24)
  drag:EnableMouse(true); drag:RegisterForDrag("LeftButton")
  drag:SetScript("OnDragStart", function() if not locked() then frame:StartMoving(); V.moving = true end end)
  drag:SetScript("OnDragStop", function()
    if V.moving then
      frame:StopMovingOrSizing(); V.moving = false
      local x, y = frame:GetCenter(); local ux, uy = UIParent:GetCenter()
      if x and ux then db.x, db.y = x - ux, y - uy end
    end
  end)
  label(drag, "Vanguard", 6, -6, 110, "GameFontNormal")
  V.state = label(drag, "", 114, -6, 100)
  local quick = CreateFrame("Button", "ForeverVanguardQuick", frame, "UIPanelButtonTemplate,SecureHandlerBaseTemplate,SecureActionButtonTemplate")
  V.quick = quick; V.buttons[#V.buttons + 1] = quick
  quick:SetSize(72, 26); quick:SetPoint("TOPLEFT", 12, -48); quick:SetText("Quick")
  quick:SetScript("OnEnter", function(self) tooltip(self, "Quick mark", "Skull • Shift: X • Ctrl: Moon • Alt: Square. Keeps existing marks. Bind this action to mark mouseover units.") end)
  quick:SetScript("OnLeave", function() GameTooltip:Hide() end)
  quick:RegisterForClicks("AnyDown", "AnyUp")
  quick:SetScript("PostClick", recordInput)
  quick:SetAttribute("*type1", "raidtarget"); quick:SetAttribute("unit", "none")
  quick:SetAttribute("marker", 8); quick:SetAttribute("action", "set-unmarked")
  quick:SetAttribute("shift-marker1", 7); quick:SetAttribute("ctrl-marker1", 5); quick:SetAttribute("alt-marker1", 6)
  -- Ambiguous modifier combinations do nothing; they must not silently mark Skull.
  for _, prefix in ipairs({"alt-ctrl-", "alt-shift-", "ctrl-shift-", "alt-ctrl-shift-"}) do quick:SetAttribute(prefix .. "type1", "") end
  quick:SetAttribute("route", routes[db.mode]); quick:WrapScript(quick, "OnClick", routeClick)
  local quickKey = label(frame, "", 12, -78, 72); quickKey:SetJustifyH("CENTER")
  V.bindings[#V.bindings + 1] = {name="ForeverVanguardQuick", label=quickKey}
  _G["BINDING_NAME_CLICK ForeverVanguardQuick:LeftButton"] = "Quick mark • Skull / Shift X / Ctrl Moon / Alt Square"
  V.destination = label(frame, "", 14, -30, 350)
  V.destination:SetHeight(14); V.destination:SetMaxLines(1)
  for i, mark in ipairs(marks) do
    local index, name, purpose = mark[1], mark[2], mark[3]
    local button = CreateFrame("Button", "ForeverVanguardMark" .. index, frame, "SecureActionButtonTemplate,SecureHandlerBaseTemplate")
    V.buttons[#V.buttons + 1] = button
    button:SetSize(28, 28); button:SetPoint("TOPLEFT", 90 + (i - 1) * 30, -48)
    button:RegisterForClicks("AnyDown", "AnyUp")
    button:SetScript("PostClick", recordInput)
    button:SetAttribute("*type1", "raidtarget")
    button:SetAttribute("unit", "none")
    button:SetAttribute("marker", index)
    button:SetAttribute("action", index == 0 and "clear" or "set-unmarked")
    button:SetAttribute("shift-action1", index == 0 and "clear" or "set")
    button:SetAttribute("route", routes[db.mode])
    button:WrapScript(button, "OnClick", routeClick)
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(); background:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    if index > 0 then
      local icon = button:CreateTexture(nil, "ARTWORK")
      icon:SetSize(22, 22); icon:SetPoint("CENTER")
      icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. index)
    else
      local glyph = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
      glyph:SetPoint("CENTER"); glyph:SetText("—")
    end
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    local key = label(frame, "", 89 + (i - 1) * 30, -78, 30)
    key:SetJustifyH("CENTER"); key:SetMaxLines(1)
    V.bindings[#V.bindings + 1] = {name="ForeverVanguardMark" .. index, label=key}
    button:SetScript("OnEnter", function(self)
      tooltip(self, name .. " • " .. purpose,
        labels[db.mode] .. ". Hostile, living units only.\n" ..
        (index == 0 and "Clears this unit's mark." or "Keeps this unit's existing mark. Shift replaces it. Assigning an icon can move it from another mob.") ..
        "\nFor mouseover marking, bind this action in Options > Key Bindings > Forever Vanguard.")
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    _G["BINDING_NAME_CLICK ForeverVanguardMark" .. index .. ":LeftButton"] = name .. (index == 0 and " mark" or " • " .. purpose)
  end
  V.hint = label(frame, "", 14, -99, 352)
  V.permission = label(frame, "", 14, -123, 352)
  local setup = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  setup:SetSize(54, 20); setup:SetPoint("TOPRIGHT", -32, -8); setup:SetText("Ability")
  setup:SetScript("OnClick", function() V.ShowActions() end)
  frame:SetShown(db.visible)
  V.ConfigureKeys(); V.Refresh(); V.RefreshBindings(); V.RefreshTarget()
end
BINDING_HEADER_FOREVERVANGUARD = "Forever Vanguard"
SLASH_FOREVERVANGUARD1 = "/fv"
SLASH_FOREVERVANGUARD2 = "/vanguard"
SlashCmdList.FOREVERVANGUARD = function(input)
  if not V.supported then say("Requires WoW Forever 1.60.1 (Interface 16001)."); return end
  if not V.frame then return end
  local command = (input or ""):lower():match("^%s*(%S*)")
  if command == "" or command == "attach" then V.ShowActions()
  elseif command == "bar" then V.Toggle()
  elseif routes[command] then V.SetMode(command)
  elseif command == "reset" then V.Reset()
  elseif command == "setup" then V.ShowActions()
  elseif command == "bind" then V.Bind((input or ""):match("^%s*%S+%s+(%S+)"))
  elseif command == "pull" then
    if not (input or ""):match("^%s*%S+%s+%S") then V.ShowSetup(); return end
    local spell = (input or ""):match("^%s*%S+%s+(.+)$")
    local macro = V.PullMacro(spell)
    if macro then V.ShowSetup(macro, spell) else say("Use /fv pull followed by the exact opening ability name. The generated macro must fit 255 bytes; commands and conditionals are not allowed in the name.") end
  elseif command == "report" then V.ShowReport()
  elseif command == "status" then say("0.1.0-alpha.4 | " .. labels[ForeverVanguardDB.mode] .. " | " .. (locked() and "in combat" or "ready") .. ". Mouseover shortcut: " .. (read(GetBindingKey, quickCommand) or V.shortcut or "none") .. ". /fv report for diagnostics.")
  else say("/fv setup for quick setup; /fv pull <ability> for a mark-and-cast macro. /fv toggles bar; /fv reset restores position. Bind marks in Options > Key Bindings > Forever Vanguard. Shift replaces an existing target mark. Settings change out of combat.") end
end
local version, _, _, interface = GetBuildInfo()
V.supported = version == "1.60.1" and interface == 16001
if not V.supported then return end
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:RegisterEvent("UPDATE_BINDINGS")
events:RegisterEvent("RAID_TARGET_UPDATE")
events:RegisterEvent("ADDON_ACTION_BLOCKED")
events:RegisterEvent("ADDON_ACTION_FORBIDDEN")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
events:SetScript("OnEvent", function(_, event, name, action)
  if event == "RAID_TARGET_UPDATE" then V.diagnostics.markerUpdates = V.diagnostics.markerUpdates + 1; return end
  if event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
    if name == addonName then V.diagnostics.blocked = event .. ": " .. tostring(action) end
    return
  end
  if event == "ADDON_LOADED" then
    if name ~= addonName or V.frame then return end
    if locked() then V.waiting = true; return end
    build()
  else
    if event == "PLAYER_REGEN_ENABLED" and V.waiting then V.waiting = nil; build() end
    if event == "PLAYER_REGEN_ENABLED" and V.pendingToggle then V.pendingToggle = nil; V.Toggle() end
    if event == "PLAYER_REGEN_DISABLED" and V.moving then V.frame:StopMovingOrSizing(); V.moving = false end
    if event == "PLAYER_REGEN_ENABLED" and V.pendingKeys then V.ConfigureKeys() end
    if event == "UPDATE_BINDINGS" then V.ConfigureKeys()
    elseif event == "PLAYER_TARGET_CHANGED" or event == "UPDATE_MOUSEOVER_UNIT" then V.RefreshTarget()
    else V.Refresh(); V.RefreshTarget() end
  end
end)
