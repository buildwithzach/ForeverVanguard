"""Hardware-click flow through pinned Blizzard Lua; native trust remains modeled."""
import unittest
from pathlib import Path
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]
class VanguardTests(unittest.TestCase):
 def client(self, setup=''):
  l=LuaRuntime(unpack_returned_tuples=True)
  for f in ['tests/mock.lua','tests/native_dispatch.lua','tests/fixtures/BlizzardSecureTemplates.lua']:
   l.execute((ROOT/f).read_text())
  l.execute('''
M.secret={}; M.time=0
function UnitGUID(u) return M.units[u] and M.units[u].guid end
function UnitIsDeadOrGhost(u) return M.units[u] and M.units[u].dead end
local methods=getmetatable(UIParent).__index
function methods:SetScrollChild(child) self.child=child end
function methods:Click() error('Synthetic clicks are forbidden') end
function SecureHandlerWrapScript(frame,event,owner,body)
 owner:WrapScript(frame,event,body)
end
function hover(guid)
 M.units.mouseover=guid and {guid=guid,hostile=true,dead=false} or nil
 M.time=M.time+0.3
 M.emit('UPDATE_MOUSEOVER_UNIT')
 for _,f in ipairs(M.frames) do if f.scripts.OnUpdate then f.scripts.OnUpdate(f,0.3) end end
end
function click(guid,key)
 hover(guid);M.key(key or 'BUTTON4')
end
''')
  l.execute(setup)
  for f in ['ForeverVanguard/ForeverVanguard.lua','ForeverVanguard/AbilityActions.lua']:
   l.execute((ROOT/f).read_text(),'ForeverVanguard')
  g=l.globals();g.M.emit('ADDON_LOADED','ForeverVanguard')
  self.l,self.lua,self.g=l,l,g
  return g
 def test_physical_binding_one_click_per_mob_no_sweep(self):
  g=self.client();g.hover('A');self.assertIsNone(g.M.assignments.A)
  g.click('A');g.hover('B');g.hover('C')
  self.assertEqual(g.M.assignments.A,8);self.assertIsNone(g.M.assignments.B)
  g.click('B');self.assertEqual(g.M.assignments.B,7)
  self.assertEqual(g.M.markerCalls,2)
  self.assertIsNone(g.ForeverVanguard.button.GetAttribute(g.ForeverVanguard.button,'type'))
 def test_combat_clicks_do_nothing_and_resume_after_combat(self):
  g=self.client();g.click('A');g.M.combat=True;g.M.emit('PLAYER_REGEN_DISABLED')
  g.click('B');g.click('C');self.assertEqual(g.M.markerCalls,1)
  g.M.combat=False;g.M.emit('PLAYER_REGEN_ENABLED');g.click('B')
  self.assertEqual(g.M.assignments.A,8);self.assertEqual(g.M.assignments.B,7)
 def test_combat_start_after_preparation_cannot_use_stale_marker(self):
  g=self.client();g.M.combatAfterPreClick=True;g.click('A')
  self.assertIsNone(g.M.assignments.A)
  g.click('B');self.assertIsNone(g.M.assignments.B)
 def test_existing_and_unseen_marks_preserved(self):
  g=self.client();g.M.assignments.unseen=8;g.M.assignments.A=5
  g.click('A');g.click('B')
  self.assertEqual(g.M.assignments.A,5);self.assertEqual(g.M.assignments.unseen,8)
  self.assertEqual(g.M.assignments.B,7)
 def test_eight_marks_no_wrap_or_replacement_on_repeat(self):
  g=self.client()
  for n in range(10):g.click(str(n))
  g.click('0');self.assertEqual(g.M.markerCalls,8)
  self.assertEqual(g.M.assignments['0'],8)
 def test_secret_or_failed_queries_skip(self):
  for key in ['secretMarker','secretAvailability','availabilityError']:
   g=self.client();g.M[key]=True;g.click('A');self.assertIsNone(g.M.markerCalls)
 def test_invalid_targets_skip(self):
  for override in ["function UnitIsDeadOrGhost() return true end",
                   "function UnitCanAttack() return false end",
                   "function UnitCanAttack() return M.secret end",
                   "function UnitGUID() return M.secret end"]:
   g=self.client(setup=override);g.click('A');self.assertIsNone(g.M.markerCalls)
  g=self.client();g.click(None);self.assertIsNone(g.M.markerCalls)
 def test_modifiers_and_rebinding(self):
  g=self.client();self.assertTrue(g.ForeverVanguard.SetKey('SHIFT-BUTTON5'))
  g.click('A');g.click('A','BUTTON5');self.assertIsNone(g.M.markerCalls)
  g.click('A','SHIFT-BUTTON5');self.assertEqual(g.M.assignments.A,8)
  self.assertIsNone(g.M.overrides['BUTTON4'])
  g.ForeverVanguard.SetKey(False);g.click('B','SHIFT-BUTTON5');self.assertIsNone(g.M.assignments.B)
 def test_binding_conflict_preserves_existing_binding(self):
  g=self.client(setup="M.bindings.JUMP='BUTTON4'")
  g.click('A');self.assertIsNone(g.M.markerCalls)
  self.assertEqual(g.GetBindingAction('BUTTON4',True),'JUMP')
 def test_settings_and_hidden_parent(self):
  g=self.client();g.SlashCmdList.FOREVERVANGUARD('');self.assertEqual(g.M.openCategory,123)
  g.click('A');self.assertIsNone(g.M.markerCalls)
  self.l.execute("M.window=CreateFrame('Frame',nil,UIParent); ForeverVanguard.panel.parent=M.window; M.window:Hide()")
  g.click('A');self.assertEqual(g.M.assignments.A,8)
  g.SlashCmdList.FOREVERVANGUARD('report')
 def test_capture_and_disabled_state(self):
  g=self.client();g.ForeverVanguard.capturing=True;g.click('A');self.assertIsNone(g.M.markerCalls)
  g.ForeverVanguard.capturing=False;g.SlashCmdList.FOREVERVANGUARD('off');g.click('A')
  self.assertIsNone(g.M.markerCalls)
 def test_icon_order_and_disable(self):
  g=self.client();g.ForeverVanguard.SetIconEnabled(8,False);g.ForeverVanguard.MoveIcon(3,-1)
  g.click('A');self.assertEqual(g.M.assignments.A,6)
 def test_new_batch_still_preserves_live_marks(self):
  g=self.client();g.click('A');self.assertTrue(g.ForeverVanguard.NewBatch())
  g.click('B');self.assertEqual(g.M.assignments.A,8);self.assertEqual(g.M.assignments.B,7)
 def test_saved_reservations_and_disabled_state(self):
  g=self.client(setup='ForeverVanguardDB={enabled=false};ForeverVanguardCycleDB={reserved={[8]=true}}')
  g.click('A');self.assertIsNone(g.M.markerCalls)
  g.ForeverVanguardDB.enabled=True;g.click('A');self.assertEqual(g.M.assignments.A,7)
 def test_native_rejection_disables(self):
  g=self.client(setup="function SetRaidTarget() M.emit('ADDON_ACTION_FORBIDDEN','ForeverVanguard','SetRaidTarget') end")
  g.click('A');self.assertFalse(g.ForeverVanguardDB.enabled)
  self.assertIsNone(g.M.assignments.A)
 def test_silent_failure_disables(self):
  g=self.client();g.M.rejectMark=True;g.click('A');g.hover('A')
  self.assertFalse(g.ForeverVanguardDB.enabled)
 def test_no_synthetic_clicks_direct_marks_or_macros(self):
  g=self.client();g.click('A')
  source=(ROOT/'ForeverVanguard/ForeverVanguard.lua').read_text()
  self.assertNotIn('SetRaidTarget(',source);self.assertNotIn('IsMouseButtonDown',source)
  self.assertNotIn('V.Poll',source);self.assertEqual(len(list(g.M.macros.items())),0)
 def legacy(self, extra=''):
  return self.client(setup="""
M.macros[121]={name='VG Ability1',body='legacy body'}
M.spells[100]={name='Charge',rank='Rank 1',harmful=true}
M.actionSlots[5]={kind='macro',id=121}
ForeverVanguardActionsDB={[5]={spellID=100,name='VG Ability1',body='legacy body'}}
"""+extra)
 def test_legacy_restore_preserves_original_spell_and_rank_id(self):
         g=self.legacy();self.assertTrue(g.ForeverVanguard.recoveryButton.shown)
         ok,result=g.ForeverVanguard.RestoreLegacy();self.assertTrue(ok)
         self.assertEqual(g.M.actionSlots[5].id,100);self.assertEqual(g.M.actionSlots[5].kind,'spell')
         self.assertEqual(g.M.macros[121].body,'legacy body');self.assertIsNone(g.ForeverVanguardActionsDB[5])
         self.assertFalse(g.ForeverVanguard.recoveryButton.shown)
 def test_legacy_restore_preserves_newer_edits_or_failed_placement(self):
         for edit in ["M.actionSlots[5]={kind='item',id=99}","M.macros[121].body='new'",'M.placeNoop=true','M.placeError=true',"M.cursor='item'",'ForeverVanguardActionsDB[5]="bad"']:
             g=self.legacy(edit);ok,_=g.ForeverVanguard.RestoreLegacy();self.assertFalse(ok)
             self.assertIsNotNone(g.ForeverVanguardActionsDB[5])
if __name__=='__main__':unittest.main(verbosity=2)
