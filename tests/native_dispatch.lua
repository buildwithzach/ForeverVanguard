-- Runs the real Blizzard Lua dispatcher. C APIs and hardware trust remain modeled.
function CopyTable(t) local r={};for k,v in pairs(t) do r[k]=v end;return r end
function GetFrameMetatable() return getmetatable(UIParent) end
local methods=getmetatable(UIParent).__index
function methods:GetAttribute(prefix,name,suffix)
 if not name then return self.attributes[prefix] end
 local a=self.attributes
 -- Native modified-attribute fallback: explicit prefix, wildcard prefix; bare name fallback.
 local candidates={prefix..name..suffix,'*'..name..suffix,prefix..name..'*','*'..name..'*',name}
 for _,key in ipairs(candidates) do if a[key]~=nil then return a[key] end end
end
function methods:WrapScript(frame,event,body)
 local wrapper=assert(loadstring(body));local original=frame.scripts[event]
 assert(original,'No inherited action handler to wrap')
 frame.wrapper=wrapper
 frame.scripts[event]=function(self,button,down)
  setfenv(wrapper,setmetatable({self=self,button=button,down=down},{__index=_G}))
  local result=wrapper();if result==false then return end
  return original(self,result or button,down)
 end
end
local create=CreateFrame
function CreateFrame(kind,name,parent,template)
 local f=create(kind,name,parent,template)
 if template and template:find('SecureActionButtonTemplate') then
  f.scripts.OnClick=function(...) return SecureActionButton_OnClick(...) end
 end
 return f
end
function IsShiftKeyDown() return M.modifier and M.modifier:find('shift')~=nil end
function IsControlKeyDown() return M.modifier and M.modifier:find('ctrl')~=nil end
function IsAltKeyDown() return M.modifier and M.modifier:find('alt')~=nil end
function UnitHasVehicleUI() return false end
function UnitExists(u) return M.units[u]~=nil end
function UnitCanAttack(_,u) return M.units[u] and M.units[u].hostile end
function UnitCanAssist(_,u) return M.units[u] and not M.units[u].hostile end
function SpellCanTargetItem() return false end
function SpellCanTargetItemID() return false end
function GetCVarBool(name) return name=='ActionButtonUseKeyDown' and M.useKeyDown or false end
function GetRaidTargetIndex(unit) local u=M.units[unit];return u and M.assignments[u.guid] end
function SetRaidTarget(unit,index)
 assert(M.secure and M.hardware, 'marker requires simulated secure hardware dispatch')
 local u=M.units[unit];if not u then return end
 M.markerCalls=(M.markerCalls or 0)+1
 if index==0 then M.assignments[u.guid]=nil;return end
 for guid,mark in pairs(M.assignments) do if mark==index then M.assignments[guid]=nil end end
 M.assignments[u.guid]=index
end
gsub=string.gsub
function M.dispatch(button,modifier)
 M.secure=true;M.hardware=true;M.modifier=modifier
 button.scripts.OnClick(button,'LeftButton',true)
 button.scripts.OnClick(button,'LeftButton',false)
 if button.scripts.PostClick then button.scripts.PostClick(button,'LeftButton',false) end
 M.secure=false;M.hardware=false;M.modifier=nil
end
function M.click(index,shift) M.dispatch(_G['ForeverVanguardMark'..index],shift and 'shift' or nil) end
function M.quick(modifier) M.dispatch(ForeverVanguardQuick,modifier) end
function M.key(key)
 local command=GetBindingAction(key,true)
 local name=command:match('^CLICK ([^:]+):LeftButton$')
 if not name then return end
 local modifier=key:match('^(.*)%-[^%-]+$')
 M.dispatch(_G[name],modifier and modifier:lower() or nil)
end
SLASH_COMMAND={TARGET_MARKER=1};SLASH_COMMAND_CATEGORY={TARGET_MARKER=1}
SlashCommandUtil={CheckAddSlashCommand=function(_,_,handler) M.nativeMarker=handler end}
local routeParser=SecureCmdOptionParse
function SecureCmdOptionParse(options)
 if options:find(';',1,true) then return routeParser(options) end
 local rest=options;local selected
 while rest:sub(1,1)=='[' do
  local clause=rest:match('^%b[]');local unit=clause:match('@(%w+)')
  local u=M.units[unit]
  if not selected and u and u.hostile and not u.dead then selected=unit end
  rest=rest:sub(#clause+1)
 end
 if selected then return rest:match('^%s*(.-)%s*$'),selected end
end
function M.executePull(body)
 M.secure=true;M.hardware=true;M.lastCast=nil
 for line in body:gmatch('[^\n]+') do
  if line:sub(1,14)=='/targetmarker ' then M.nativeMarker(line:sub(15)) end
  if line:sub(1,6)=='/cast ' then
   local spell,unit=SecureCmdOptionParse(line:sub(7))
   if spell and unit then M.lastCast={spell=spell,guid=M.units[unit].guid,succeeded=not M.castFails} end
  end
 end
 M.secure=false;M.hardware=false
end
