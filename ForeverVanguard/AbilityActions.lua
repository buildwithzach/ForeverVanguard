-- Recovery only for attack slots attached by older Vanguard builds.
local V = ForeverVanguard
if not V or not V.supported then return end
local A = {}
V.actions = A
local function saved()
  return type(ForeverVanguardActionsDB) == "table" and ForeverVanguardActionsDB or {}
end
local function available() return not InCombatLockdown() and not GetCursorInfo() end
local function matching(slot, record)
  if type(record) ~= "table" or type(record.spellID) ~= "number" or type(record.name) ~= "string" or type(record.body) ~= "string" then return false end
  local kind, id = GetActionInfo(slot)
  return kind == "macro" and id == GetMacroIndexByName(record.name) and GetMacroBody(id) == record.body
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

function V.RestoreLegacy()
  if not available() then return false, "Leave combat and empty your cursor first." end
  local slots = {}
  for slot in pairs(saved()) do slots[#slots + 1] = slot end
  local restored, kept = 0, 0
  for _, slot in ipairs(slots) do
    if type(slot) == "number" and slot >= 1 and slot <= (MAX_ACTION_BUTTONS or 180) and slot % 1 == 0 and A.Restore(slot) then
      restored = restored + 1
    else kept = kept + 1 end
  end
  if V.recoveryButton then V.recoveryButton:SetShown(next(saved()) ~= nil) end
  return kept == 0, restored .. " original attack buttons restored; " .. kept .. " changed/invalid slots left untouched. Existing macros kept."
end
