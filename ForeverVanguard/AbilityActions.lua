-- Explicit, reversible conversion of an existing spell slot. Never hooks a cast event.
local V = ForeverVanguard
if not V or not V.supported then return end
local A = {}
V.actions = A
local function saved()
  if type(ForeverVanguardActionsDB) ~= "table" then ForeverVanguardActionsDB = {} end
  return ForeverVanguardActionsDB
end
local function available()
  return not InCombatLockdown() and not GetCursorInfo()
end
local function spellBody(id)
  if not C_Spell.IsSpellHarmful(id) or C_Spell.IsSpellHelpful(id) or C_Spell.IsSpellPassive(id) then return end
  local name, rank = C_Spell.GetSpellName(id), C_Spell.GetSpellSubtext(id)
  if type(name) ~= "string" or name == "" or name:find("[%c%[%];|/\\]") then return end
  if type(rank) == "string" and rank ~= "" then name = name .. "(" .. rank .. ")" end
  if name:find("[%c%[%];|/\\]") then return end
  local body = "#showtooltip " .. name .. "\n/targetmarker [@target,harm,nodead] ~8\n/cast [@target,harm,nodead] " .. name
  if #body > 255 then return end
  return body, name
end
local function matching(slot, record)
  if type(record) ~= "table" or type(record.spellID) ~= "number" or type(record.name) ~= "string" or type(record.body) ~= "string" then return false end
  local kind, id = GetActionInfo(slot)
  return kind == "macro" and id == GetMacroIndexByName(record.name) and GetMacroBody(id) == record.body
end
function A.Scan()
  local rows = {}
  if InCombatLockdown() then return rows end
  for slot = 1, (MAX_ACTION_BUTTONS or 180) do
    local kind, id = GetActionInfo(slot)
    local record = saved()[slot]
    if record then
      rows[#rows + 1] = {slot=slot, name=type(record) == "table" and type(record.spellID) == "number" and C_Spell.GetSpellName(record.spellID) or "Saved ability", attached=matching(slot, record), tracked=true}
    elseif kind == "spell" then
      local body, name = spellBody(id)
      if body then rows[#rows + 1] = {slot=slot, spellID=id, name=name} end
    end
  end
  return rows
end
function A.Attach(slot, expectedSpellID)
  if not available() then return false, "Leave combat and empty your cursor first." end
  if type(slot) ~= "number" or slot < 1 or slot > (MAX_ACTION_BUTTONS or 180) or slot % 1 ~= 0 then return false, "Invalid action slot." end
  if saved()[slot] then return false, "This slot already has a restore record." end
  local kind, id = GetActionInfo(slot)
  if kind ~= "spell" or id ~= expectedSpellID then return false, "That slot changed. Refresh the list." end
  local body = spellBody(id)
  if not body then return false, "This spell cannot be converted safely." end
  local macroID, macroName
  for n = 1, 30 do
    local name = "VG Ability" .. n
    local index = GetMacroIndexByName(name)
    if index == 0 then
      local ok, created = pcall(CreateMacro, name, "INV_MISC_QUESTIONMARK", body, true)
      if not ok or not created or created == 0 then return false, "No free character macro slot. Nothing on your bars changed." end
      macroID, macroName = created, name; break
    elseif GetMacroBody(index) == body then macroID, macroName = index, name; break end
  end
  if not macroID then return false, "No free Vanguard macro name. Nothing changed." end
  -- Persist recovery information before any action-slot mutation.
  local record = {spellID=id, name=macroName, body=body}
  saved()[slot] = record
  local ok = pcall(function()
    PickupMacro(macroID)
    local cursor, cursorID = GetCursorInfo()
    if cursor ~= "macro" or cursorID ~= macroID then error("macro pickup failed") end
    -- Recheck immediately before replacing; do not overwrite a newly changed slot.
    local currentKind, currentID = GetActionInfo(slot)
    if currentKind ~= "spell" or currentID ~= id then error("slot changed") end
    PlaceAction(slot)
  end)
  if ok and matching(slot, record) then ClearCursor(); return true, "Attached. Use this ability's usual button/key. Restore is available here." end
  local currentKind, currentID = GetActionInfo(slot)
  if currentKind == "spell" and currentID == id then saved()[slot] = nil end
  return false, "Placement was not verified. Your restore record is kept if the slot changed; inspect your cursor and action bar."
end
function A.Restore(slot)
  if not available() then return false, "Leave combat and empty your cursor first." end
  local record = saved()[slot]
  if not matching(slot, record) then return false, "Slot or macro changed since attachment. Kept your current action untouched." end
  local ok = pcall(function()
    C_Spell.PickupSpell(record.spellID)
    local cursor = GetCursorInfo()
    if cursor ~= "spell" then error("spell pickup failed") end
    PlaceAction(slot)
  end)
  local kind, id = GetActionInfo(slot)
  if ok and kind == "spell" and id == record.spellID then
    ClearCursor(); saved()[slot] = nil
    return true, "Original ability restored in the same slot."
  end
  return false, "Restore was not verified. Recovery information is retained."
end
function V.ShowActions()
  if InCombatLockdown() then print("Vanguard: Open ability attachment after combat."); return end
  if not A.frame then
    local f = CreateFrame("Frame", "ForeverVanguardAbilities", UIParent, "BasicFrameTemplateWithInset")
    A.frame = f; f:SetSize(520, 390); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG"); f:SetClampedToScreen(true)
    f.TitleText:SetText("Vanguard • Attach to an existing ability")
    local function text(message, x, y, width)
      local label = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      label:SetPoint("TOPLEFT",x,y);label:SetWidth(width);label:SetJustifyH("LEFT");label:SetText(message);return label
    end
    text("Choose a targeted enemy attack already on your bar. Attach adds Skull to its selected enemy and casts the spell in the SAME slot, using its usual key. Vanguard creates the macro for you. Avoid ground-targeted attacks or toggles.",18,-38,480)
    A.rows = {}
    for i=1,6 do
      local row = {label=text("",18,-105-(i-1)*34,350)}
      row.button = CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
      row.button:SetSize(108,24);row.button:SetPoint("TOPLEFT",388,-100-(i-1)*34)
      row.button:SetScript("OnClick",function()
        local entry=row.entry;if not entry then return end
        local _,message
        if entry.tracked then _,message=A.Restore(entry.slot) else _,message=A.Attach(entry.slot,entry.spellID) end
        A.message:SetText(message);A.Refresh()
      end)
      A.rows[i]=row
    end
    A.message=text("No actions change until you click Attach. Your existing macros and other slots are preserved.",18,-340,480)
    local nextPage=CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
    nextPage:SetSize(130,24);nextPage:SetPoint("TOPLEFT",366,-307);nextPage:SetText("Next / refresh")
    nextPage:SetScript("OnClick",function() A.page=(A.page or 0)+1;A.Refresh() end)
    if UISpecialFrames then table.insert(UISpecialFrames,"ForeverVanguardAbilities") end
  end
  A.page=0;A.Refresh();A.frame:Show()
end
function A.Refresh()
  if not A.frame then return end
  local entries=A.Scan();local pages=math.max(1,math.ceil(#entries/6));A.page=(A.page or 0)%pages
  for i,row in ipairs(A.rows) do
    local entry=entries[A.page*6+i];row.entry=entry
    row.label:SetText(entry and ("Slot "..entry.slot.." • "..entry.name..(entry.tracked and not entry.attached and " (changed)" or "")) or "")
    row.button:SetShown(entry~=nil);row.button:SetEnabled(not InCombatLockdown())
    row.button:SetText(entry and entry.tracked and "Restore" or "Attach")
  end
  if #entries==0 then A.message:SetText("No eligible spell slots found. Existing macros, items and helpful/passive spells are skipped.") end
end
