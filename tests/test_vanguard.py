"""Execute the shipped addon and Blizzard dispatcher; native APIs/security modeled."""
import unittest
from pathlib import Path
from lupa.lua51 import LuaRuntime
ROOT = Path(__file__).resolve().parents[1]

class VanguardTests(unittest.TestCase):
    def client(self, setup=''):
        lua=LuaRuntime(unpack_returned_tuples=True)
        for file in ['tests/mock.lua','tests/native_dispatch.lua','tests/fixtures/BlizzardSecureTemplates.lua']:
            lua.execute((ROOT/file).read_text())
        lua.execute('M.secret={}');lua.execute(setup)
        for file in ['ForeverVanguard/ForeverVanguard.lua','ForeverVanguard/AbilityActions.lua']:
            lua.execute((ROOT/file).read_text(),'ForeverVanguard')
        self.lua,self.g=lua,lua.globals()
        self.g.M.emit('ADDON_LOADED','ForeverVanguard')
        return self.g
    def unit(self, guid, hostile=True, dead=False, token='mouseover'):
        self.g.M.units[token]=self.lua.table_from(dict(guid=guid,hostile=hostile,dead=dead))
    def press(self):self.g.M.key('BUTTON4')
    def test_default_mouse4_no_toolbar_no_macros(self):
        g=self.client();self.assertEqual(g.ForeverVanguard.activeKey,'BUTTON4')
        self.assertIsNone(g.ForeverVanguardBar);self.assertFalse(g.ForeverVanguard.panel.shown)
        self.assertFalse(g.ForeverVanguard.button.mouseEnabled)
        self.assertEqual(len(list(g.M.macros.items())),0)
        g.SlashCmdList.FOREVERVANGUARD('');self.assertEqual(g.M.openCategory,123)
    def test_hover_alone_and_target_alone_do_not_mark(self):
        g=self.client();self.unit('T',token='target');self.press()
        self.unit('A');g.M.emit('UPDATE_MOUSEOVER_UNIT');self.assertEqual(len(list(g.M.assignments.items())),0)
        self.press();self.assertEqual(g.M.assignments['A'],8);self.assertIsNone(g.M.assignments['T'])
    def test_eight_distinct_icons_then_stop(self):
        g=self.client()
        for i,icon in enumerate([8,7,6,5,4,3,2,1]):
            self.unit(str(i));self.press();self.assertEqual(g.M.assignments[str(i)],icon)
        self.unit('ninth');self.press();self.assertIsNone(g.M.assignments['ninth'])
        self.assertEqual(len(list(g.M.assignments.items())),8);self.assertEqual(g.M.markerCalls,8)
    def test_repeat_same_mob_does_not_advance_or_replace(self):
        g=self.client();self.unit('A');self.press();self.press();self.press()
        self.unit('B');self.press()
        self.assertEqual(g.M.assignments['A'],8);self.assertEqual(g.M.assignments['B'],7)
        self.assertEqual(g.M.markerCalls,2)
    def test_skip_other_players_marks_and_used_icons_out_of_view(self):
        g=self.client();g.M.assignments['unseen']=8;g.M.assignments['A']=5
        self.unit('A');self.press();self.unit('B');self.press()
        self.assertEqual(g.M.assignments['unseen'],8);self.assertEqual(g.M.assignments['A'],5)
        self.assertEqual(g.M.assignments['B'],7)
    def test_invalid_hover_does_not_consume_icon(self):
        for hostile,dead in [(False,False),(True,True)]:
            g=self.client();self.unit('A',hostile,dead);self.press()
            self.unit('B');self.press();self.assertEqual(g.M.assignments['B'],8)
    def test_custom_order_disabled_icons_and_all_disabled(self):
        g=self.client();g.ForeverVanguard.MoveIcon(4,-1);g.ForeverVanguard.MoveIcon(3,-1);g.ForeverVanguard.MoveIcon(2,-1)
        g.ForeverVanguard.SetIconEnabled(8,False)
        self.unit('A');self.press();self.assertEqual(g.M.assignments['A'],5)
        self.unit('B');self.press();self.assertEqual(g.M.assignments['B'],7)
        for i in range(1,9):g.ForeverVanguard.SetIconEnabled(i,False)
        self.unit('C');self.press();self.assertIsNone(g.M.assignments['C'])
    def test_settings_rows_change_order_and_toggle(self):
        g=self.client();g.ForeverVanguard.rows[2].up.scripts.OnClick()
        self.assertEqual(g.ForeverVanguardDB.order[1],7)
        g.ForeverVanguard.rows[1].toggle.scripts.OnClick()
        self.assertTrue(g.ForeverVanguardDB.disabled[7])
        g.ForeverVanguard.rows[1].toggle.scripts.OnClick();self.assertIsNone(g.ForeverVanguardDB.disabled[7])
    def test_combat_has_no_mark_or_insecure_attribute_mutation(self):
        g=self.client();self.unit('A');g.M.combat=True;g.M.emit('PLAYER_REGEN_DISABLED');self.press()
        self.assertEqual(len(list(g.M.assignments.items())),0)
        self.assertEqual(len(list(g.ForeverVanguardCycleDB.reserved.items())),0)
        g.M.combat=False;g.M.emit('PLAYER_REGEN_ENABLED');self.press();self.assertEqual(g.M.assignments['A'],8)
    def test_secure_guard_if_combat_begins_after_preclick(self):
        g=self.client();self.unit('A');g.M.combatAfterPreClick=True;self.press()
        self.assertIsNone(g.M.assignments['A']);self.assertEqual(g.ForeverVanguard.button.attributes.unit,'none')
    def test_hidden_marker_or_availability_never_guessed(self):
        for condition in ['secretMarker','secretAvailability','availabilityError']:
            g=self.client();self.unit('A');g.M[condition]=True;self.press()
            self.assertIsNone(g.M.assignments['A']);self.assertEqual(len(list(g.ForeverVanguardCycleDB.reserved.items())),0)
    def test_missing_api_or_bad_return_stops(self):
        for setup in ['GetNextAvailableRaidTargetMarkerIndex=nil', 'M.badAvailability=99', "M.badAvailability='bad'"]:
            g=self.client(setup);self.unit('A');self.press();self.assertIsNone(g.M.assignments['A'])
    def test_rejected_attempt_reserved_without_false_success(self):
        g=self.client();self.unit('A');g.M.rejectMark=True;self.press()
        self.assertIsNone(g.M.assignments['A']);self.assertTrue(g.ForeverVanguardCycleDB.reserved[8])
        g.M.emit('RAID_TARGET_UPDATE');g.M.rejectMark=False;self.unit('B');self.press()
        self.assertEqual(g.M.assignments['B'],7);self.assertIn('requested',g.ForeverVanguard.status)
    def test_batch_reset_never_clears_or_steals_live_marks(self):
        g=self.client();self.unit('A');self.press();g.ForeverVanguard.NewBatch()
        self.unit('B');self.press();self.assertEqual(g.M.assignments['A'],8);self.assertEqual(g.M.assignments['B'],7)
        g.M.assignments['A']=None;g.ForeverVanguard.NewBatch();self.unit('C');self.press();self.assertEqual(g.M.assignments['C'],8)
    def test_saved_reservations_survive_reload_and_prevent_reuse(self):
        g=self.client('ForeverVanguardCycleDB={reserved={[8]=true,[7]=true}}')
        self.unit('A');self.press();self.assertEqual(g.M.assignments['A'],6)
    def test_press_once_for_either_game_keydown_setting(self):
        for keydown in [True,False]:
            g=self.client();g.M.useKeyDown=keydown;self.unit('A');self.press()
            self.assertEqual(g.M.markerCalls,1)
    def test_binding_conflicts_and_rebinding_preserve_player_bindings(self):
        g=self.client("M.bindings['OTHER']='BUTTON4'")
        self.assertIsNone(g.ForeverVanguard.activeKey);self.assertIsNone(g.M.overrides['BUTTON4'])
        ok,why=g.ForeverVanguard.SetKey('BUTTON4');self.assertFalse(ok);self.assertIn('already bound',why)
        self.assertTrue(g.ForeverVanguard.SetKey('BUTTON5'))
        self.unit('A');g.M.key('BUTTON5');self.assertEqual(g.M.assignments['A'],8)
        self.assertEqual(g.M.bindings['OTHER'],'BUTTON4')
        g.ForeverVanguard.SetKey(False);self.assertIsNone(g.M.overrides['BUTTON5'])
    def test_capture_mouse_button_keyboard_and_cancel(self):
        g=self.client();g.ForeverVanguard.keyButton.scripts.OnClick()
        g.ForeverVanguard.panel.scripts.OnMouseDown(None,'Button5')
        self.assertEqual(g.ForeverVanguardDB.key,'BUTTON5');self.assertFalse(g.ForeverVanguard.capturing)
        g.ForeverVanguard.keyButton.scripts.OnClick();g.ForeverVanguard.panel.scripts.OnKeyDown(None,'F6')
        self.assertEqual(g.ForeverVanguardDB.key,'F6')
        g.ForeverVanguard.keyButton.scripts.OnClick();g.ForeverVanguard.CaptureKey('ESCAPE')
        self.assertEqual(g.ForeverVanguardDB.key,'F6')
    def test_binding_change_deferred_in_combat_and_capture_cancelled(self):
        g=self.client();g.ForeverVanguard.keyButton.scripts.OnClick();g.M.combat=True;g.M.emit('PLAYER_REGEN_DISABLED')
        self.assertFalse(g.ForeverVanguard.capturing)
        g.M.emit('UPDATE_BINDINGS');self.assertTrue(g.ForeverVanguard.pendingBinding)
        self.assertFalse(g.ForeverVanguard.SetKey('F6')[0]);self.assertFalse(g.ForeverVanguard.NewBatch())
        g.M.combat=False;g.M.emit('PLAYER_REGEN_ENABLED');self.assertIsNone(g.ForeverVanguard.pendingBinding)
    def test_disabled_and_raid_permissions(self):
        for setup in ['ForeverVanguardDB={enabled=false}', 'M.raid=true']:
            g=self.client(setup);self.unit('A');self.press();self.assertIsNone(g.M.assignments['A'])
        g=self.client('M.raid=true;M.assistant=true');self.unit('A');self.press();self.assertEqual(g.M.assignments['A'],8)
    def test_load_in_combat_defers_build(self):
        g=self.client('M.combat=true');self.assertIsNone(g.ForeverVanguard.button)
        g.M.combat=False;g.M.emit('PLAYER_REGEN_ENABLED');self.assertIsNotNone(g.ForeverVanguard.button)
    def test_unsupported_client_does_not_mutate_data(self):
        g=self.client("M.version='12.1.5';ForeverVanguardDB={keep='yes'}")
        self.assertFalse(g.ForeverVanguard.supported);self.assertIsNone(g.ForeverVanguard.button)
        self.assertEqual(g.ForeverVanguardDB.keep,'yes')
    def test_corrupt_saved_settings_repaired_without_duplicate_icons(self):
        g=self.client('ForeverVanguardDB={key={},order={8,8,0,99,5},disabled="bad"};ForeverVanguardCycleDB={reserved="bad"}')
        order=list(g.ForeverVanguardDB.order.values());self.assertEqual(len(order),8);self.assertEqual(set(order),set(range(1,9)))
        self.assertEqual(g.ForeverVanguardDB.key,'BUTTON4')
    def legacy(self, extra=''):
        return self.client('''
M.macros[121]={name='VG Ability1',body='legacy body'}
M.spells[100]={name='Charge',rank='Rank 1',harmful=true}
M.actionSlots[5]={kind='macro',id=121}
ForeverVanguardActionsDB={[5]={spellID=100,name='VG Ability1',body='legacy body'}}
'''+extra)
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
    def test_no_macro_creation_or_old_action_workflows_in_shipped_code(self):
        for file in (ROOT/'ForeverVanguard').glob('*.lua'):
            source=file.read_text()
            for forbidden in ['CreateMacro(', 'PickupMacro(', 'macrotext', 'function A.Attach', 'V.ShowActions', 'V.ShowSetup']:
                self.assertNotIn(forbidden,source)

if __name__=='__main__':unittest.main(verbosity=2)
