M = {frames={}, combat=false, units={}, assignments={}, prints={}, secure=false}
SlashCmdList={}
function print(s) table.insert(M.prints,s) end
function GetBuildInfo() return M.version or '1.60.1','70500','date',M.interface or 16001 end
function InCombatLockdown() return M.combat end
function IsInRaid() return M.raid end
function UnitIsGroupLeader() return M.leader end
function UnitIsGroupAssistant() return M.assistant end
local methods={}
function methods:SetAttribute(k,v)
  assert(not (self.secure and M.combat and not M.secure), 'insecure protected attribute write')
  self.attributes[k]=v
end
function methods:GetAttribute(k) return self.attributes[k] end
function methods:WrapScript(frame,event,body) self.wrapper=assert(loadstring(body)) end
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:RegisterEvent(e) self.events[e]=true end
function methods:SetPoint(...) self.point={...} end
function methods:ClearAllPoints() self.point=nil end
function methods:SetSize(w,h) self.width,self.height=w,h end
function methods:EnableMouse(v) self.mouseEnabled=v end
function methods:SetAlpha(a) self.alpha=a end
function methods:EnableKeyboard(v) self.keyboard=v end
function methods:SetPropagateKeyboardInput(v) self.propagate=v end
function methods:SetWidth(w) self.width=w end
function methods:SetHeight(h) self.height=h end
function methods:GetCenter() return 500,400 end
function methods:SetText(t) self.text=t end
function methods:GetText() return self.text end
function methods:SetShown(v)
 assert(not (self.secure and M.combat and not M.secure), 'insecure protected visibility write')
 local changed=self.shown~=v;self.shown=v
 local handler=self.scripts[v and 'OnShow' or 'OnHide']
 if changed and handler then handler(self) end
end
function methods:Show() self:SetShown(true) end
function methods:Hide() self:SetShown(false) end
function methods:GetParent() return self.parent end
function methods:IsShown() return self.shown end
function methods:SetEnabled(v) self.enabled=v end
function methods:LockHighlight() self.highlight=true end
function methods:UnlockHighlight() self.highlight=false end
function methods:RegisterForClicks(...) self.clicks={...} end
function methods:CreateTexture() return CreateFrame('Texture',nil,self) end
function methods:CreateFontString() return CreateFrame('FontString',nil,self) end
for _,k in ipairs({'SetNormalTexture','SetPushedTexture','SetMaxLines','SetFontObject','SetMultiLine','SetAutoFocus','SetMaxLetters','ClearFocus','SetFocus','HighlightText','SetJustifyH','SetFrameStrata','SetClampedToScreen','SetMovable','SetBackdrop','SetBackdropColor','SetBackdropBorderColor','SetColorTexture','SetTextColor','RegisterForDrag','StartMoving','StopMovingOrSizing','SetAllPoints','SetTexture','SetHighlightTexture','SetOwner','AddLine'}) do methods[k]=function() end end
function CreateFrame(kind,name,parent,template)
 local f=setmetatable({name=name,parent=parent,template=template,shown=true,attributes={},scripts={},events={},secure=template and template:find('Secure')}, {__index=methods})
 if f.secure then local p=parent;while p do p.secure=true;p=p.parent end end
 table.insert(M.frames,f);if name then _G[name]=f end
 if template and template:find('BasicFrameTemplate') then f.TitleText=CreateFrame('FontString',nil,f) end
 return f
end
UIParent=CreateFrame('Frame','UIParent');GameTooltip=CreateFrame('Frame')
function M.emit(event,...)
 for _,f in ipairs(M.frames) do if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f,event,...) end end
end
-- Small macro-condition model, not an implementation of Blizzard's secure engine.
function SecureCmdOptionParse(route)
 for clause in route:gmatch('[^;]+') do
  local unit=clause:match('%[@(%w+),harm,nodead%]')
  if unit then
   local value=M.units[unit]
   if value and value.hostile and not value.dead then return unit end
  elseif clause:match('none') then return 'none' end
 end
end
M.bindings={}
function GetBindingKey(command) return M.bindings[command] end
function GetBindingText(key) return key end
function UnitName(unit) return M.units[unit] and (M.units[unit].name or M.units[unit].guid) end
function issecretvalue(value) return value == M.secret and M.secret ~= nil end
function M.close()
 local b=ForeverVanguardClose
 M.secure=true
 local handler=assert(loadstring(b:GetAttribute('_onclick')))
 setfenv(handler,setmetatable({self=b},{__index=_G}));handler()
 M.secure=false
end

M.overrides={}
function GetBindingAction(key,includeOverrides)
 if includeOverrides and M.overrides[key] then return M.overrides[key].command end
 for command,k in pairs(M.bindings) do if k==key then return command end end
 return ''
end
function ClearOverrideBindings(owner)
 assert(not M.combat, 'binding change in combat')
 for key,value in pairs(M.overrides) do if value.owner==owner then M.overrides[key]=nil end end
end
function SetOverrideBindingClick(owner,priority,key,name,button)
 assert(not M.combat, 'binding change in combat')
 M.overrides[key]={owner=owner,command='CLICK '..name..':'..button}
end

function GetCursorInfo() return M.cursor end
M.macros={}
function GetMacroIndexByName(name) for id,m in pairs(M.macros) do if m.name==name then return id end end;return 0 end
function GetMacroBody(index) return M.macros[index] and M.macros[index].body end
function CreateMacro(name,icon,body,perCharacter)
 assert(not M.combat);if M.macroFull then error('full') end
 local id=121+#M.macros;while M.macros[id] do id=id+1 end
 M.macros[id]={name=name,body=body};return id
end
function PickupMacro(id) assert(not M.combat);M.cursor='macro';M.pickedMacro=id end
M.actionSlots={};M.spells={}
function GetActionInfo(slot)
 local a=M.actionSlots[slot];if a then return a.kind,a.id end
end
C_Spell={
 GetSpellName=function(id) return M.spells[id] and M.spells[id].name end,
 GetSpellSubtext=function(id) return M.spells[id] and M.spells[id].rank end,
 IsSpellHarmful=function(id) return M.spells[id] and M.spells[id].harmful end,
 IsSpellHelpful=function(id) return M.spells[id] and M.spells[id].helpful end,
 IsSpellPassive=function(id) return M.spells[id] and M.spells[id].passive end,
 PickupSpell=function(id) assert(not M.combat);M.cursor='spell';M.cursorID=id end,
}
function GetCursorInfo() return M.cursor,M.cursorID end
function PickupMacro(id) assert(not M.combat);M.cursor='macro';M.cursorID=id;M.pickedMacro=id end
function ClearCursor() M.cursor=nil;M.cursorID=nil end
function PlaceAction(slot)
 assert(not M.combat)
 if M.placeError then error('placement denied') end
 if M.placeNoop then return end
 local previous=M.actionSlots[slot]
 M.actionSlots[slot]={kind=M.cursor,id=M.cursorID}
 M.cursor=previous and previous.kind;M.cursorID=previous and previous.id
end

function GetTime() return M.time or 0 end
UIErrorsFrame={AddMessage=function(_, text) M.errorMessage=text end}
Settings={
 RegisterCanvasLayoutCategory=function(panel,name) M.settingsPanel=panel;return {GetID=function() return 123 end} end,
 RegisterAddOnCategory=function(category) M.category=category end,
 OpenToCategory=function(id) M.openCategory=id;M.settingsPanel:Show() end,
}
