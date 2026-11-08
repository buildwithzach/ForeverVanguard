"""Synthetic Lua 5.1 UI/routing tests; cannot prove live secure execution/permissions."""
import unittest
from pathlib import Path
import xml.etree.ElementTree as ET
from lupa.lua51 import LuaRuntime
ROOT = Path(__file__).resolve().parents[1]

class VanguardTests(unittest.TestCase):
    def client(self, setup=''):
        lua=LuaRuntime(unpack_returned_tuples=True)
        lua.execute((ROOT/'tests/mock.lua').read_text());lua.execute((ROOT/'tests/native_dispatch.lua').read_text())
        lua.execute((ROOT/'tests/fixtures/BlizzardSecureTemplates.lua').read_text());lua.execute((ROOT/'tests/fixtures/BlizzardTargetMarker.lua').read_text());lua.execute("ForeverVanguardDB={visible=true,shortcut='F6'}");lua.execute(setup)
        lua.execute((ROOT/'ForeverVanguard/ForeverVanguard.lua').read_text(),'ForeverVanguard')
        lua.execute((ROOT/'ForeverVanguard/AbilityActions.lua').read_text(),'ForeverVanguard')
        lua.globals().M.emit('ADDON_LOADED','ForeverVanguard')
        self.lua,self.g=lua,lua.globals()
        return self.g
    def unit(self, token, guid, hostile=True, dead=False):
        self.g.M.units[token]=self.lua.table_from(dict(guid=guid,hostile=hostile,dead=dead))
    def test_no_mark_until_click_and_default_mouseover_priority(self):
        g=self.client();self.unit('target','A');self.unit('mouseover','B')
        self.assertEqual(len(list(g.M.assignments.items())),0)
        g.M.click(8,False);self.assertEqual(g.M.assignments['B'],8);self.assertIsNone(g.M.assignments['A'])
    def test_friendly_dead_or_missing_mouseover_never_marks_target(self):
        for hostile,dead in [(False,False),(True,True)]:
            g=self.client();self.unit('target','A');self.unit('mouseover','B',hostile,dead)
            g.M.click(7,False);self.assertEqual(len(list(g.M.assignments.items())),0)
        g=self.client();self.unit('target','A');g.M.quick(None)
        self.assertEqual(len(list(g.M.assignments.items())),0)
    def test_no_valid_hostile_unit_does_nothing(self):
        g=self.client();self.unit('target','Friend',False)
        for i in [8,7,0]:g.M.click(i,False)
        self.assertEqual(len(list(g.M.assignments.items())),0)
    def test_target_modes_rejected_and_old_saved_mode_migrated(self):
        g=self.client("ForeverVanguardDB={mode='target'}")
        self.assertEqual(g.ForeverVanguardDB.mode,'mouseover')
        self.assertFalse(g.ForeverVanguard.SetMode('target'))
        self.assertFalse(g.ForeverVanguard.SetMode('auto'))
    def test_mark_is_preserved_unless_shift_and_clear_is_explicit(self):
        g=self.client();self.unit('mouseover','A');g.M.assignments['A']=5
        g.M.click(8,False);self.assertEqual(g.M.assignments['A'],5)
        g.M.click(8,True);self.assertEqual(g.M.assignments['A'],8)
        g.M.click(8,False);self.assertEqual(g.M.assignments['A'],8) # no toggle off
        g.M.click(0,False);self.assertIsNone(g.M.assignments['A'])
    def test_reassigning_icon_moves_it_as_documented(self):
        g=self.client();self.unit('mouseover','A');g.M.assignments['B']=8
        g.M.click(8,False);self.assertEqual(g.M.assignments['A'],8);self.assertIsNone(g.M.assignments['B'])
    def test_click_reads_current_unit_not_cached_mouseover(self):
        g=self.client();self.unit('target','A');self.unit('mouseover','B')
        self.unit('mouseover','C');g.M.click(8,False)
        self.assertEqual(g.M.assignments['C'],8);self.assertIsNone(g.M.assignments['B'])
    def test_configuration_locked_but_secure_mark_route_works_in_combat_model(self):
        g=self.client();self.unit('mouseover','A');g.M.combat=True
        g.M.emit('PLAYER_REGEN_DISABLED');self.assertFalse(g.ForeverVanguard.SetMode('target'))
        g.ForeverVanguard.Toggle();g.ForeverVanguard.Reset()
        self.assertEqual(g.ForeverVanguardDB.mode,'mouseover')
        g.M.click(8,False);self.assertEqual(g.M.assignments['A'],8)
        g.M.combat=False;g.M.emit('PLAYER_REGEN_ENABLED')
    def test_load_during_combat_defers_secure_creation(self):
        g=self.client('M.combat=true');self.assertIsNone(g.ForeverVanguard.frame)
        g.M.combat=False;g.M.emit('PLAYER_REGEN_ENABLED');self.assertIsNotNone(g.ForeverVanguard.frame)
    def test_unsupported_client_does_not_create_bar_or_touch_saved_data(self):
        g=self.client("M.version='12.0.0';M.interface=120000;ForeverVanguardDB={keep='yes'}")
        self.assertFalse(g.ForeverVanguard.supported);self.assertIsNone(g.ForeverVanguard.frame)
        self.assertEqual(g.ForeverVanguardDB.keep,'yes')
    def test_saved_mode_position_and_visibility_and_corrupt_defaults(self):
        g=self.client("ForeverVanguardDB={mode='mouseover',visible=false,x=40,y=50}")
        self.assertEqual(g.ForeverVanguardDB.mode,'mouseover');self.assertFalse(g.ForeverVanguard.frame.shown)
        g.ForeverVanguard.Reset();self.assertTrue(g.ForeverVanguard.frame.shown)
        g=self.client("ForeverVanguardDB={mode='invalid',visible='yes',x=0/0,y=math.huge}")
        self.assertEqual(g.ForeverVanguardDB.mode,'mouseover');self.assertEqual(g.ForeverVanguardDB.x,0)
        self.assertEqual(g.ForeverVanguardDB.y,0)
    def test_all_bindings_point_at_secure_buttons_and_no_keys_are_stolen(self):
        g=self.client();tree=ET.parse(ROOT/'ForeverVanguard/Bindings.xml')
        self.assertEqual(len(tree.getroot()),10)
        for binding in tree.getroot():
            name=binding.attrib['name'].split()[1].split(':')[0]
            button=g[name];self.assertIsNotNone(button)
            self.assertEqual(button.attributes['*type1'],'raidtarget')
            self.assertIsNotNone(g['BINDING_NAME_'+binding.attrib['name']])
        self.assertEqual(len(g.M.prints),0)
    def test_group_warning_and_no_chat_spam(self):
        g=self.client('M.raid=true');self.assertIn('leader',g.ForeverVanguard.permission.text)
        g.M.leader=True;g.M.emit('GROUP_ROSTER_UPDATE')
        self.assertIn('Quick mark keeps',g.ForeverVanguard.permission.text)
        self.assertEqual(len(g.M.prints),0)

    def test_close_in_combat_persists_and_reopens_without_losing_mark_actions(self):
        g=self.client();self.unit('mouseover','A');g.M.combat=True
        g.M.close();self.assertFalse(g.ForeverVanguard.frame.shown)
        self.assertFalse(g.ForeverVanguardDB.visible)
        g.M.quick(None);self.assertEqual(g.M.assignments['A'],8)
        g.M.combat=False;g.ForeverVanguard.Toggle()
        self.assertTrue(g.ForeverVanguard.frame.shown);self.assertTrue(g.ForeverVanguardDB.visible)
    def test_combat_toggle_is_deferred_and_close_cancels_pending_toggle(self):
        g=self.client();g.M.combat=True;g.ForeverVanguard.Toggle()
        self.assertTrue(g.ForeverVanguard.frame.shown)
        g.M.combat=False;g.M.emit('PLAYER_REGEN_ENABLED')
        self.assertFalse(g.ForeverVanguard.frame.shown)
        g.ForeverVanguard.Toggle();g.M.combat=True;g.ForeverVanguard.Toggle();g.M.close()
        g.M.combat=False;g.M.emit('PLAYER_REGEN_ENABLED')
        self.assertFalse(g.ForeverVanguard.frame.shown)

    def test_default_shortcut_is_ready_without_persistent_binding_changes(self):
        g=self.client();self.assertEqual(g.ForeverVanguard.shortcut,'F6')
        for key in ['F6','SHIFT-F6','CTRL-F6','ALT-F6']:
            self.assertEqual(g.M.overrides[key].command,'CLICK ForeverVanguardQuick:LeftButton')
        self.assertEqual(len(list(g.M.bindings.items())),0)
    def test_shortcut_preserves_conflicts_and_reports_no_available_key(self):
        g=self.client("M.bindings['existing']='SHIFT-F6'")
        self.assertIsNone(g.ForeverVanguard.shortcut);self.assertIsNone(g.M.overrides['SHIFT-F6'])
        self.assertFalse(g.ForeverVanguard.Bind('F6'));self.assertIsNone(g.ForeverVanguard.shortcut)
        g=self.client("M.bindings={one='F6',two='F7',three='F8',four='F9'}")
        self.assertIsNone(g.ForeverVanguard.shortcut);self.assertIn('/fv pull',g.ForeverVanguard.hint.text)
    def test_binding_changes_defer_in_combat_and_can_be_disabled(self):
        g=self.client();g.M.combat=True;g.M.bindings['new']='F6';g.M.emit('UPDATE_BINDINGS')
        self.assertTrue(g.ForeverVanguard.pendingKeys)
        g.M.combat=False;g.M.emit('PLAYER_REGEN_ENABLED');self.assertIsNone(g.ForeverVanguard.shortcut)
        g.ForeverVanguard.Bind('off');self.assertEqual(len(list(g.M.overrides.items())),0)
    def test_real_dispatch_handles_key_down_and_key_up_without_duplicate_marks(self):
        for use_down in [True,False]:
            g=self.client();self.unit('mouseover','A');g.M.useKeyDown=use_down
            g.M.quick(None);self.assertEqual(g.M.assignments['A'],8);self.assertEqual(g.M.markerCalls,1)
            g.M.quick('shift');self.assertEqual(g.M.assignments['A'],8);self.assertEqual(g.M.markerCalls,1)

    def test_diagnostics_record_events_without_claiming_confirmed_marks(self):
        g=self.client();self.unit('mouseover','A');g.M.quick(None)
        g.M.emit('RAID_TARGET_UPDATE')
        g.M.emit('ADDON_ACTION_FORBIDDEN','ForeverVanguard','SetRaidTarget()')
        report=g.ForeverVanguard.Report()
        self.assertIn('Input releases seen: 1',report);self.assertIn('marker update events: 1',report)
        self.assertIn('SetRaidTarget()',report);self.assertIn('not that a particular mob was marked',report)
        self.assertEqual(len(g.M.prints),0)
    def test_saved_shortcut_validation_and_explicit_binding_preservation(self):
        g=self.client("ForeverVanguardDB={shortcut={}}")
        self.assertIsNone(g.ForeverVanguard.shortcut)
        g=self.client("M.bindings['CLICK ForeverVanguardQuick:LeftButton']='G'")
        self.assertIsNone(g.ForeverVanguard.shortcut);self.assertEqual(len(list(g.M.overrides.items())),0)
        self.assertEqual(g.ForeverVanguard.bindings[1].label.text,'G')

    def test_default_keys_dispatch_to_current_mouseover_with_bar_closed_in_combat(self):
        g=self.client();self.unit('target','Never');g.M.combat=True;g.M.close()
        for key,mark in [('F6',8),('SHIFT-F6',7),('CTRL-F6',5),('ALT-F6',6)]:
            self.unit('mouseover',key);g.M.key(key);self.assertEqual(g.M.assignments[key],mark)
        self.assertIsNone(g.M.assignments['Never'])
        g.M.units.mouseover=None;g.M.key('F6');self.assertIsNone(g.M.assignments['Never'])

    def test_fresh_install_does_not_open_toolbar_or_assign_marker_shortcuts(self):
        g=self.client('ForeverVanguardDB=nil')
        self.assertFalse(g.ForeverVanguard.frame.shown)
        self.assertEqual(len(list(g.M.overrides.items())),0)
    def test_create_pull_action_is_explicit_and_preserves_existing_macros(self):
        g=self.client();g.M.macros[121]=self.lua.table_from(dict(name='Vanguard Pull1',body='/say Keep'))
        index,_=g.ForeverVanguard.CreatePullAction('Charge')
        self.assertEqual(g.M.macros[121].body,'/say Keep')
        self.assertEqual(g.M.pickedMacro,index)
        self.assertIn('/targetmarker ',g.M.macros[index].body)
        g.M.cursor=None;again,_=g.ForeverVanguard.CreatePullAction('Charge');self.assertEqual(index,again)
    def test_macro_creation_refuses_combat_full_slots_and_occupied_cursor(self):
        for setup in ['M.combat=true','M.macroFull=true',"M.cursor='item'"]:
            g=self.client();self.lua.execute(setup)
            result,_=g.ForeverVanguard.CreatePullAction('Charge');self.assertIsNone(result)
            self.assertEqual(len(list(g.M.macros.items())),0)

    def test_native_macro_marks_and_casts_same_mouseover_or_target(self):
        for hover in [True,False]:
            g=self.client();self.unit('target','T')
            if hover:self.unit('mouseover','M')
            g.M.executePull(g.ForeverVanguard.PullMacro('Charge'))
            expected='M' if hover else 'T'
            self.assertEqual(g.M.assignments[expected],8)
            self.assertEqual(g.M.lastCast.guid,expected)
            self.assertEqual(g.M.lastCast.spell,'Charge')
            if hover:self.assertIsNone(g.M.assignments['T'])
    def test_native_macro_no_valid_enemy_does_nothing_and_existing_marks_stay(self):
        g=self.client();self.unit('target','Friend',False);self.unit('mouseover','Dead',True,True)
        g.M.executePull(g.ForeverVanguard.PullMacro('Charge'))
        self.assertIsNone(g.M.lastCast);self.assertEqual(len(list(g.M.assignments.items())),0)
        self.unit('target','T');g.M.assignments['T']=5;g.M.executePull(g.ForeverVanguard.PullMacro('Charge'))
        self.assertEqual(g.M.assignments['T'],5);self.assertEqual(g.M.lastCast.guid,'T')
    def test_mark_before_cast_does_not_claim_successful_spell(self):
        g=self.client();self.unit('target','T');g.M.castFails=True
        g.M.executePull(g.ForeverVanguard.PullMacro('Charge'))
        self.assertEqual(g.M.assignments['T'],8);self.assertFalse(g.M.lastCast.succeeded)

    def existing_action(self):
        g=self.client()
        g.M.spells[100]=self.lua.table_from(dict(name='Charge',rank='Rank 1',harmful=True))
        g.M.actionSlots[5]=self.lua.table_from(dict(kind='spell',id=100))
        return g
    def test_attach_existing_spell_keeps_slot_and_binding_then_restores(self):
        g=self.existing_action();g.M.bindings['ACTIONBUTTON5']='5'
        ok,_=g.ForeverVanguard.actions.Attach(5,100);self.assertTrue(ok)
        action=g.M.actionSlots[5];self.assertEqual(action.kind,'macro')
        self.assertEqual(g.M.bindings['ACTIONBUTTON5'],'5')
        self.assertIn('Charge(Rank 1)',g.GetMacroBody(action.id))
        self.assertNotIn('@mouseover',g.GetMacroBody(action.id))
        self.assertIsNone(g.M.cursor)
        ok,_=g.ForeverVanguard.actions.Restore(5);self.assertTrue(ok)
        self.assertEqual(g.M.actionSlots[5].kind,'spell');self.assertEqual(g.M.actionSlots[5].id,100)
        self.assertIsNone(g.ForeverVanguardActionsDB[5])
    def test_attach_refuses_stale_selection_combat_cursor_and_full_macros(self):
        for condition in ["M.actionSlots[5].id=101",'M.combat=true',"M.cursor='item'",'M.macroFull=true']:
            g=self.existing_action();self.lua.execute(condition)
            ok,_=g.ForeverVanguard.actions.Attach(5,100);self.assertFalse(ok)
            self.assertEqual(g.M.actionSlots[5].kind,'spell')
            self.assertIsNone(g.ForeverVanguardActionsDB and g.ForeverVanguardActionsDB[5])
    def test_attach_scan_skips_helpful_passive_macro_and_item_actions(self):
        g=self.existing_action()
        g.M.spells[101]=self.lua.table_from(dict(name='Heal',harmful=False,helpful=True))
        g.M.spells[102]=self.lua.table_from(dict(name='Passive',harmful=True,passive=True))
        for slot,kind,id in [(6,'spell',101),(7,'spell',102),(8,'macro',1),(9,'item',2)]:
            g.M.actionSlots[slot]=self.lua.table_from(dict(kind=kind,id=id))
        entries=g.ForeverVanguard.actions.Scan();self.assertEqual(len(entries),1);self.assertEqual(entries[1].slot,5)
    def test_restore_does_not_overwrite_manual_bar_or_macro_edits(self):
        for edit in ['slot','body']:
            g=self.existing_action();g.ForeverVanguard.actions.Attach(5,100)
            if edit=='slot':g.M.actionSlots[5]=self.lua.table_from(dict(kind='item',id=99))
            else:g.M.macros[g.M.actionSlots[5].id].body='/say My edit'
            ok,_=g.ForeverVanguard.actions.Restore(5);self.assertFalse(ok)
            if edit=='slot':self.assertEqual(g.M.actionSlots[5].kind,'item')
            else:self.assertEqual(g.GetMacroBody(g.M.actionSlots[5].id),'/say My edit')
    def test_failed_placement_does_not_claim_attachment_or_change_original(self):
        for failure in ['placeError','placeNoop']:
            g=self.existing_action();g.M[failure]=True
            ok,_=g.ForeverVanguard.actions.Attach(5,100);self.assertFalse(ok)
            self.assertEqual(g.M.actionSlots[5].kind,'spell');self.assertEqual(g.M.actionSlots[5].id,100)
    def test_restore_uses_macro_name_after_macro_indices_change(self):
        g=self.existing_action();g.ForeverVanguard.actions.Attach(5,100)
        old=g.M.actionSlots[5].id;g.M.macros[160]=g.M.macros[old];g.M.macros[old]=None;g.M.actionSlots[5].id=160
        ok,_=g.ForeverVanguard.actions.Restore(5);self.assertTrue(ok)
    def test_attached_action_marks_selected_target_and_casts_original_rank(self):
        g=self.existing_action();g.ForeverVanguard.actions.Attach(5,100)
        self.unit('target','T');self.unit('mouseover','M')
        g.M.executePull(g.GetMacroBody(g.M.actionSlots[5].id))
        self.assertEqual(g.M.assignments['T'],8);self.assertIsNone(g.M.assignments['M'])
        self.assertEqual(g.M.lastCast.guid,'T');self.assertEqual(g.M.lastCast.spell,'Charge(Rank 1)')

    def test_attach_ui_wires_existing_slot_without_changes_on_open(self):
        g=self.existing_action();g.SlashCmdList.FOREVERVANGUARD('')
        self.assertEqual(g.M.actionSlots[5].kind,'spell');self.assertEqual(len(list(g.M.macros.items())),0)
        row=g.ForeverVanguard.actions.rows[1]
        self.assertEqual(row.entry.slot,5);row.button.scripts.OnClick()
        self.assertEqual(g.M.actionSlots[5].kind,'macro')
        self.assertEqual(row.button.text,'Restore');row.button.scripts.OnClick()
        self.assertEqual(g.M.actionSlots[5].kind,'spell')
    def test_corrupt_saved_restore_record_does_not_crash_or_overwrite(self):
        g=self.existing_action();g.ForeverVanguardActionsDB=self.lua.table_from({5:'bad'})
        self.assertEqual(len(g.ForeverVanguard.actions.Scan()),1)
        ok,_=g.ForeverVanguard.actions.Restore(5);self.assertFalse(ok)
        self.assertEqual(g.M.actionSlots[5].kind,'spell')

    def test_class_independent_discovery_and_multiple_ability_restoration(self):
        g=self.client()
        # Synthetic metadata: no class API, known opener list or fixed spell IDs.
        for i in range(1,9):
            g.M.spells[9000+i]=self.lua.table_from(dict(name='Attack '+str(i),rank='Rank 2',harmful=True))
            g.M.actionSlots[i]=self.lua.table_from(dict(kind='spell',id=9000+i))
        entries=g.ForeverVanguard.actions.Scan();self.assertEqual(len(entries),8)
        for i in range(1,9):
            ok,_=g.ForeverVanguard.actions.Attach(i,9000+i);self.assertTrue(ok)
            self.assertIn('Attack '+str(i)+'(Rank 2)',g.GetMacroBody(g.M.actionSlots[i].id))
        for i in range(1,9):
            ok,_=g.ForeverVanguard.actions.Restore(i);self.assertTrue(ok)
            self.assertEqual(g.M.actionSlots[i].id,9000+i)

    def test_quick_mark_modifier_choices_preserve_existing_marks(self):
        for modifier,index in [(None,8),('shift',7),('ctrl',5),('alt',6)]:
            g=self.client();self.unit('mouseover','A');g.M.combat=True;g.M.quick(modifier)
            self.assertEqual(g.M.assignments['A'],index)
            g.M.assignments['A']=3;g.M.quick(modifier);self.assertEqual(g.M.assignments['A'],3)
    def test_quick_mark_rejects_ambiguous_modifier_chords(self):
        g=self.client();self.unit('target','A')
        for combo in ['alt-ctrl','alt-shift','ctrl-shift','alt-ctrl-shift']:g.M.quick(combo)
        self.assertIsNone(g.M.assignments['A'])
    def test_quick_mark_tracks_current_mouseover_without_cache(self):
        g=self.client();self.unit('target','A');self.unit('mouseover','B')
        g.M.quick(None);self.assertEqual(g.M.assignments['B'],8)
        self.unit('mouseover','C');g.M.quick('shift');self.assertEqual(g.M.assignments['C'],7)
        self.assertIsNone(g.M.assignments['A'])
    def test_bind_labels_refresh_without_assigning_any_bindings(self):
        g=self.client();self.assertEqual(g.ForeverVanguard.bindings[1].label.text,'F6')
        g.M.bindings['CLICK ForeverVanguardQuick:LeftButton']='F6';g.M.emit('UPDATE_BINDINGS')
        self.assertEqual(g.ForeverVanguard.bindings[1].label.text,'F6')
        self.assertEqual(len(list(g.M.bindings.items())),1)
    def test_destination_preview_escapes_markup_and_hides_secret_names(self):
        g=self.client();self.unit('mouseover','A');g.M.units.mouseover.name='|cffff0000Fake'
        g.M.emit('PLAYER_TARGET_CHANGED');self.assertIn('||cffff0000Fake',g.ForeverVanguard.destination.text)
        g.M.secret='hidden';g.M.units.mouseover.name='hidden';g.ForeverVanguard.RefreshTarget()
        self.assertEqual(g.ForeverVanguard.destination.text,'Mouseover: Enemy')
        g.M.units.mouseover=None;g.ForeverVanguard.RefreshTarget();self.assertIn('Hover an enemy',g.ForeverVanguard.destination.text)
    def test_pull_macro_uses_same_route_and_preserves_marks(self):
        g=self.client()
        for mode in ['mouseover']:
            g.ForeverVanguard.SetMode(mode);macro=g.ForeverVanguard.PullMacro('Heroic Throw')
            lines=macro.splitlines();self.assertEqual(len(lines),3)
            self.assertEqual(lines[0],'#showtooltip Heroic Throw')
            self.assertTrue(lines[1].endswith(' ~8'))
            self.assertEqual(lines[1][14:-3],lines[2][6:-len(' Heroic Throw')])
            self.assertLessEqual(len(macro.encode()),255)
        self.assertIn('[@mouseover,harm,nodead][@target,harm,nodead]',g.ForeverVanguard.PullMacro('Charge'))
    def test_pull_macro_rejects_command_injection_and_oversized_names(self):
        g=self.client()
        for bad in ['',None,'Charge\n/run malicious()', '[help] Heal','Charge;Other','/cast Charge','Charge|test','x'*81]:
            self.assertIsNone(g.ForeverVanguard.PullMacro(bad),bad)
    def test_setup_macro_is_copyable_and_never_executes_or_edits_bindings(self):
        g=self.client();g.SlashCmdList.FOREVERVANGUARD('pull Charge')
        self.assertIn('/cast ',g.ForeverVanguard.setup.copy.text)
        self.assertTrue(g.ForeverVanguard.setup.shown)
        self.assertEqual(len(list(g.M.assignments.items())),0)
        self.assertEqual(len(list(g.M.bindings.items())),0)
        g.ForeverVanguard.setup.Hide(g.ForeverVanguard.setup);g.M.combat=True
        g.SlashCmdList.FOREVERVANGUARD('setup');self.assertFalse(g.ForeverVanguard.setup.shown)

if __name__=='__main__':unittest.main(verbosity=2)
