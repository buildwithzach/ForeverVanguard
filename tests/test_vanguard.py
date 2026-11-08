"""Real addon + pinned Blizzard Lua dispatcher. Native permissions are mocked.
Permissive cases test flow only; the rejection case models the likely restriction.
"""
import unittest
from pathlib import Path
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]
class VanguardTests(unittest.TestCase):
 def client(self, allow=True, setup=''):
  l=LuaRuntime(unpack_returned_tuples=True)
  for f in ['tests/mock.lua','tests/native_dispatch.lua','tests/fixtures/BlizzardSecureTemplates.lua']:
   l.execute((ROOT/f).read_text())
  l.execute('''
M.secret={}; M.time=0; M.clicks=0
function UnitGUID(u) return M.units[u] and M.units[u].guid end
function IsMouseButtonDown(b) return M.down==b end
local methods=getmetatable(UIParent).__index
function methods:SetScrollChild(child) self.child=child end
function methods:Click(button,down)
 M.clicks=M.clicks+1
 if not M.allowHover then M.emit('ADDON_ACTION_FORBIDDEN','ForeverVanguard','Button:Click()'); return end
 -- Hypothetical permission only; never evidence that Forever permits this.
 M.secure=true;M.hardware=true
 SecureActionButton_OnClick(self,button,down)
 M.secure=false;M.hardware=false
end
function step(guid,button)
 M.units.mouseover=guid and {guid=guid,hostile=true,dead=false} or nil
 M.down=button;M.time=M.time+0.3
 for _,f in ipairs(M.frames) do if f.scripts.OnUpdate then f.scripts.OnUpdate(f,0.3) end end
end
''')
  l.execute(setup);g=l.globals();g.M.allowHover=allow
  for f in ['ForeverVanguard/ForeverVanguard.lua','ForeverVanguard/AbilityActions.lua']:
   l.execute((ROOT/f).read_text(),'ForeverVanguard')
  g.M.emit('ADDON_LOADED','ForeverVanguard')
  self.l,self.lua,self.g=l,l,g
  return g
 def test_fv_and_report(self):
  g=self.client();self.assertEqual(g.SLASH_FOREVERVANGUARD1,'/fv')
  g.SlashCmdList.FOREVERVANGUARD('');self.assertEqual(g.M.openCategory,123)
  g.SlashCmdList.FOREVERVANGUARD('report')
 def test_hold_sweep_release_and_no_single_press_dependency(self):
  g=self.client();g.step('A',None);self.assertEqual(g.M.clicks,0)
  g.step('A','Button4');g.step('A','Button4');g.step('B','Button4');g.step('C',None)
  self.assertEqual(g.M.assignments.A,8);self.assertEqual(g.M.assignments.B,7)
  self.assertIsNone(g.M.assignments.C);self.assertEqual(g.M.clicks,2)
 def test_combat_has_no_attribute_changes(self):
  g=self.client();g.M.combat=True;g.step('A','Button4');g.step('B','Button4')
  self.assertEqual(g.M.clicks,2);self.assertEqual(g.M.assignments.B,7)
 def test_existing_marks_and_unseen_owners_preserved(self):
  g=self.client();g.M.assignments.unseen=8;g.M.assignments.A=5
  g.step('A','Button4');g.step('B','Button4')
  self.assertEqual(g.M.assignments.A,5);self.assertEqual(g.M.assignments.unseen,8)
  self.assertEqual(g.M.assignments.B,7)
 def test_eight_marks_no_wrap(self):
  g=self.client()
  for n in range(10):g.step(str(n),'Button4')
  self.assertEqual(g.M.clicks,8)
 def test_secret_queries_skip_even_in_combat(self):
  for key in ['secretMarker','secretAvailability']:
   g=self.client();g.M[key]=True;g.M.combat=True;g.step('A','Button4')
   self.assertEqual(g.M.clicks,0)
 def test_native_rejection_stops_and_is_not_success(self):
  g=self.client(False);g.step('A','Button4');g.step('A','Button4');g.step('B','Button4')
  self.assertEqual(g.M.clicks,1);self.assertFalse(g.ForeverVanguardDB.enabled)
  logs='\n'.join(g.ForeverVanguardCycleDB.log.values())
  self.assertIn('BLOCKED',logs);self.assertNotIn('CONFIRMED',logs)
 def test_silent_failure_stops(self):
  g=self.client();g.M.rejectMark=True;g.step('A','Button4');g.step('A','Button4');g.step('B','Button4')
  self.assertEqual(g.M.clicks,1);self.assertFalse(g.ForeverVanguardDB.enabled)
 def test_new_batch_preserves_actual_marks(self):
  g=self.client();g.step('A','Button4');self.assertFalse(g.ForeverVanguard.NewBatch())
  g.step('A',None);self.assertTrue(g.ForeverVanguard.NewBatch());g.step('B','Button4')
  self.assertEqual(g.M.assignments.A,8);self.assertEqual(g.M.assignments.B,7)
 def test_mouse5_and_modifiers(self):
  g=self.client();self.assertTrue(g.ForeverVanguard.SetKey('SHIFT-BUTTON5'))
  g.step('A','Button5');self.assertEqual(g.M.clicks,0)
  g.M.modifier='shift';g.step('A','Button5');self.assertEqual(g.M.clicks,1)
 def test_icon_settings(self):
  g=self.client();g.ForeverVanguard.SetIconEnabled(8,False)
  g.ForeverVanguard.MoveIcon(3,-1);g.step('A','Button4')
  self.assertEqual(g.M.assignments.A,6)
 def test_settings_capture_does_not_mark(self):
  g=self.client();g.ForeverVanguard.capturing=True;g.step('A','Button4')
  self.assertEqual(g.M.clicks,0)
  g.ForeverVanguard.capturing=False;g.ForeverVanguard.panel.Show(g.ForeverVanguard.panel)
  g.step('A','Button4');self.assertEqual(g.M.clicks,0)
 def test_off_command_stops(self):
  g=self.client();g.SlashCmdList.FOREVERVANGUARD('off');g.step('A','Button4')
  self.assertEqual(g.M.clicks,0)
 def test_saved_reservations_and_disabled_state(self):
  g=self.client(setup='ForeverVanguardDB={enabled=false};ForeverVanguardCycleDB={reserved={[8]=true}}')
  g.step('A','Button4');self.assertEqual(g.M.clicks,0)
  g.ForeverVanguardDB.enabled=True;g.step('A','Button4');self.assertEqual(g.M.assignments.A,7)
 def test_no_direct_marking_macros_or_override_bindings(self):
  g=self.client();g.step('A','Button4')
  source=(ROOT/'ForeverVanguard/ForeverVanguard.lua').read_text()
  self.assertNotIn('pcall(SetRaidTarget',source);self.assertNotIn('SetRaidTarget(',source)
  self.assertEqual(len(list(g.M.overrides.items())),0);self.assertEqual(len(list(g.M.macros.items())),0)
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
