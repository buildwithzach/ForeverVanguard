local name = ...
local frame = CreateFrame("Frame")
local buttons, seen = {}, {}
local held, elapsed, pending = false, 0, nil
local db
local function say(s) print("|cffffcc00FV Sweep Test:|r " .. s) end
local function public(fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, value = pcall(fn, ...)
    if not ok or (issecretvalue and issecretvalue(value)) then return false end
    return true, value
end
local function log(s)
    if not db then return end
    local line = string.format("%.2f combat=%s %s", GetTime(), tostring(InCombatLockdown()), s)
    db.log[#db.log + 1] = line
    if #db.log > 400 then table.remove(db.log, 1) end
end
local function finish()
    if not pending then return end
    local p = pending
    pending = nil
    local known, guid = public(UnitGUID, "mouseover")
    local result = "UNVERIFIED: mob no longer under cursor"
    if known and guid == p.guid then
        local readable, mark = public(GetRaidTargetIndex, "mouseover")
        if readable then
            result = mark == p.icon and "CONFIRMED" or "NOT APPLIED"
        else result = "UNVERIFIED: marker unreadable" end
    end
    log(result .. " icon=" .. p.icon)
    say(result .. " (icon " .. p.icon .. ")")
end
local function attempt()
    if not db or not db.enabled or not held then return end
    local ok, guid = public(UnitGUID, "mouseover")
    if not ok or not guid then return end
    if seen[guid] then return end
    seen[guid] = true
    local attackOK, attack = public(UnitCanAttack, "player", "mouseover")
    local deadOK, dead = public(UnitIsDeadOrGhost, "mouseover")
    if not attackOK or not deadOK or not attack or dead then
        log("SKIP: invalid/unreadable hostile unit") return
    end
    local readable, mark = public(GetRaidTargetIndex, "mouseover")
    if not readable then log("SKIP: current mark secret/unreadable"); say("Skipped: current mark unreadable."); return end
    if mark then log("SKIP: already marked"); return end
    local icon
    for n = 8, 1, -1 do
        if not db.reserved[n] then
            local known, available = public(GetNextAvailableRaidTargetMarkerIndex, n, false, false, false)
            if not known then log("SKIP: free-icon query secret/unavailable"); say("Skipped: free icons unreadable."); return end
            if available == n then icon = n; break end
        end
    end
    if not icon then log("SKIP: no unused icons"); say("No unused icons; stopping."); return end
    -- Reserve even failed attempts. Never wrap or recycle icons during a test.
    db.reserved[icon] = true
    finish()
    pending = { guid = guid, icon = icon, at = GetTime() }
    log("ATTEMPT route=" .. db.route .. " icon=" .. icon .. " guid=" .. guid)
    local success
    if db.route == "click" then
        -- Deliberately test whether a hover-driven synthetic click is accepted.
        -- Attributes were configured before combat; this is NOT a hardware click.
        success = pcall(buttons[icon].Click, buttons[icon], "LeftButton", false)
    else
        success = pcall(SetRaidTarget, "mouseover", icon)
    end
    log(success and "CALL returned (not proof of marking)" or "CALL raised an error")
end
local function poll()
    if not db then return end
    local known, down = public(IsMouseButtonDown, "Button4")
    down = known and down and db.enabled or false
    if down ~= held then
        held = down
        if held then seen = {}; log("HOLD start"); say("Mouse 4 held: " .. db.route)
        else log("HOLD end"); say("Mouse 4 released.") end
    end
    if pending and GetTime() - pending.at >= 0.2 then finish() end
    if held then attempt() end
end
frame:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed >= 0.03 then elapsed = 0; poll() end
end)
frame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == name then
        ForeverVanguardSweepTestDB = ForeverVanguardSweepTestDB or {}
        db = ForeverVanguardSweepTestDB
        db.log, db.reserved = db.log or {}, db.reserved or {}
        db.route, db.enabled = "direct", true
        local version, build = GetBuildInfo()
        log("SESSION version=" .. version .. " build=" .. build .. " test=0.2.0-sweep-test.1")
        say("Ready. Hold Mouse 4 and sweep. /fvtest for help. Disable normal Forever Vanguard.")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then poll()
    elseif event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
        local a = (issecretvalue and issecretvalue(arg1)) and "secret" or tostring(arg1)
        local b = (issecretvalue and issecretvalue(arg2)) and "secret" or tostring(arg2)
        log(event .. " addon=" .. a .. " function=" .. b)
        say(event .. " (recorded)")
    else log(event) end
end)
for _, event in ipairs({"ADDON_LOADED", "UPDATE_MOUSEOVER_UNIT", "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "RAID_TARGET_UPDATE"}) do
    frame:RegisterEvent(event)
end
for n = 1, 8 do
    local b = CreateFrame("Button", "ForeverVanguardSweepProbe" .. n, UIParent, "SecureActionButtonTemplate")
    b:RegisterForClicks("AnyUp")
    b:SetAttribute("useOnKeyDown", false)
    b:SetAttribute("type", "raidtarget")
    b:SetAttribute("unit", "mouseover")
    b:SetAttribute("action", "set-unmarked")
    b:SetAttribute("marker", n)
    b:EnableMouse(false)
    buttons[n] = b
end
SLASH_FVSWEEPTEST1 = "/fvtest"
SlashCmdList.FVSWEEPTEST = function(command)
    if not db then return end
    command = command:lower():match("^%s*(.-)%s*$")
    if command == "direct" or command == "click" then
        db.route = command; seen = {}; log("ROUTE " .. command); say("Route: " .. command)
    elseif command == "off" then db.enabled = false; poll(); say("Disabled.")
    elseif command == "on" then db.enabled = true; say("Enabled.")
    elseif command == "reset" then
        if InCombatLockdown() or held then say("Release Mouse 4 and leave combat before reset."); return end
        finish(); db.reserved = {}; seen = {}; log("RESET reservations"); say("Reservations reset; existing marks still checked.")
    elseif command == "report" then
        local f = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
        f:SetSize(650, 450); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG")
        local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 15, -35); scroll:SetPoint("BOTTOMRIGHT", -35, 15)
        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true); edit:SetFontObject(ChatFontNormal); edit:SetWidth(590)
        edit:SetAutoFocus(false); edit:SetText(table.concat(db.log, "\n"))
        scroll:SetScrollChild(edit); edit:SetFocus(); edit:HighlightText()
        edit:SetScript("OnEscapePressed", function() f:Hide() end)
    else say("Hold Mouse 4 to sweep. /fvtest direct | click | reset | report | off | on") end
end
