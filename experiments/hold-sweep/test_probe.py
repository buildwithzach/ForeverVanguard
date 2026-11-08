"""Control-flow tests only: no claim about Forever's native security engine."""
from pathlib import Path
from lupa.lua51 import LuaRuntime
import unittest, os
ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path(os.environ.get('FV_SWEEP_SOURCE', str(Path(__file__).parent/'ForeverVanguardSweepTest/SweepTest.lua')))
class Probe(unittest.TestCase):
 def client(self, blocked=False):
  l=LuaRuntime(unpack_returned_tuples=True)
  l.execute((ROOT/'tests/mock.lua').read_text())
  l.execute((ROOT/'tests/native_dispatch.lua').read_text())
  l.execute('''
M.secret={}; M.time=0; M.calls=0
function GetTime() return M.time end
function IsMouseButtonDown(button) return M.down end
function UnitGUID(u) return M.units[u] and M.units[u].guid end
function UnitIsDeadOrGhost(u) return M.units[u] and M.units[u].dead end
function SetRaidTarget(u,n)
 M.calls=M.calls+1
 if M.block then M.emit('ADDON_ACTION_FORBIDDEN','SweepTest','SetRaidTarget'); return end
 M.assignments[UnitGUID(u)]=n
end
function GetFrameMetatable() return getmetatable(UIParent) end
getmetatable(UIParent).__index.Click=function(self) SetRaidTarget('mouseover',self:GetAttribute('marker')) end
function step(guid, down)
 M.units.mouseover=guid and {guid=guid, hostile=true, dead=false} or nil
 M.down=down; M.time=M.time+0.3
 for _,f in ipairs(M.frames) do if f.scripts.OnUpdate then f.scripts.OnUpdate(f,0.3) end end
end
''')
  l.execute(SOURCE.read_text(),'ForeverVanguardSweepTest')
  g=l.globals();g.M.block=blocked;g.M.emit('ADDON_LOADED','ForeverVanguardSweepTest');g.SlashCmdList.FVSWEEPTEST('on')
  return l,g
 def test_fv_opens_settings_and_disable_button_works(self):
  l,g=self.client();self.assertEqual(g.SLASH_FVSWEEPTEST2,'/fv')
  g.SlashCmdList.FVSWEEPTEST('');panel=g.ForeverVanguardSettings
  self.assertTrue(panel.shown)
  for f in g.M.frames.values():
   if f.text=='Disable marking':f.scripts.OnClick()
  self.assertFalse(g.ForeverVanguardSweepTestDB.enabled)
  panel.Hide(panel);g.SlashCmdList.FVSWEEPTEST('options');self.assertTrue(panel.shown)
 def test_block_stops_further_attempts(self):
  l,g=self.client(True);g.step('A',True);g.step('B',True)
  self.assertEqual(g.M.calls,1);self.assertFalse(g.ForeverVanguardSweepTestDB.enabled)
 def test_sustained_sweep_combat_and_release(self):
  l,g=self.client();g.step('A',False);self.assertEqual(g.M.calls,0)
  g.step('A',True);g.step('A',True);g.M.combat=True;g.step('B',True)
  g.step('C',False);self.assertEqual(g.M.calls,2)
  self.assertEqual(g.M.assignments.A,8);self.assertEqual(g.M.assignments.B,7)
 def test_existing_and_exhaustion(self):
  l,g=self.client();g.M.assignments.unseen=8;g.M.assignments.A=5
  g.step('A',True);g.step('B',True);self.assertEqual(g.M.assignments.B,7)
  for n in range(12):g.step(str(n),True)
  self.assertEqual(g.M.calls,6);self.assertEqual(g.M.assignments.unseen,8);self.assertEqual(g.M.assignments.A,5)
 def test_block_is_not_success(self):
  l,g=self.client(True);g.step('A',True);g.step('A',True)
  logs='\n'.join(g.ForeverVanguardSweepTestDB.log.values())
  self.assertIn('ADDON_ACTION_FORBIDDEN',logs);self.assertIn('NOT APPLIED',logs)
  self.assertNotIn('CONFIRMED',logs);self.assertEqual(g.M.calls,1)
 def test_secret_skips(self):
  l,g=self.client();g.M.secretAvailability=True;g.step('A',True)
  self.assertEqual(g.M.calls,0)
 def test_click_route_does_not_mutate_protected_attributes_in_combat(self):
  l,g=self.client();g.SlashCmdList.FVSWEEPTEST('click');g.M.combat=True
  g.step('A',True);g.step('B',True);self.assertEqual(g.M.calls,2)
 def test_off_and_reset_guard(self):
  l,g=self.client();g.step('A',True);g.SlashCmdList.FVSWEEPTEST('reset')
  self.assertTrue(g.ForeverVanguardSweepTestDB.reserved[8]);g.SlashCmdList.FVSWEEPTEST('off')
  g.step('B',True);self.assertEqual(g.M.calls,1)
if __name__=='__main__':unittest.main()
