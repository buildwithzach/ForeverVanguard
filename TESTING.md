# 0.2.0-alpha.1 — real Forever acceptance (not yet performed)

Record GetBuildInfo(), input device, group permission and whether the area hides markers.
Use only this addon first, then repeat with the player's normal nameplate/unit-frame addons.
Do not claim in-game success from the offline mocked tests.

1. Install on Forever 1.60.1 / 16001. No toolbar or popup should appear. `/fv` opens the
   native Options → AddOns → Forever Vanguard page. No macros or action slots change.
2. With Mouse 4 unbound, hover a living hostile mob and press/release it. Observe a real
   Skull above that mob without changing your target. Hover alone must do nothing.
3. Repeat on eight different mobs. Observe Skull, Cross, Square, Moon, Triangle, Diamond,
   Circle, Star. The ninth mob receives nothing; the first eight keep their marks.
4. Repeat on the same marked mob. It must keep its mark without consuming another icon.
   Repeat on friendly/dead/missing mouseover; your selected target must stay unchanged.
5. Have another player place Skull on a mob outside your visible nameplates, then start
   a new batch. The next new mob must receive Cross. No existing mark should move.
6. Test every enabled icon already in use, and multiple rapid presses. If marks move or
   duplicate presses consume icons unexpectedly, record the sequence and stop acceptance.
7. Enter combat, including while holding Mouse 4 before releasing it. The request must
   remain inert with no protected-action errors. Out of combat, a new press may work.
8. Test an instance with hidden marker/availability values. It must pause with an accurate
   message rather than guessing or moving a mark. This build does not promise marking
   in restricted instances, even before a pull.
9. Toggle icons off, move Moon to first, and test the new order. Disable all icons and
   confirm no request. Settings controls must lock in combat and become usable afterward.
10. Change Mouse 4 to Mouse 5 and then a keyboard key using the picker. Escape cancels.
    A conflicting key must be refused without replacing it. Unbind removes only Vanguard's
    override. Repeat after reload and with native action-on-keydown both on and off.
11. Test Mouse 4 over a world model, default nameplate, and any custom nameplate/unit frame.
    Record input interception separately from marking rejection. Test actual modifiers
    if choosing a modified key; no modifier should select a different icon.
12. Clear a mark externally. Its reserved icon stays reserved until Start new batch.
    New batch must not clear or move marks that remain in use. Reservations survive reload.
13. With a saved 0.1.x attack attachment, Restore old attack buttons restores the exact
    saved spell ID/rank in that slot. Edited slots/macros remain unchanged. Existing macros
    are retained. Test a failed restore and confirm the recovery record remains.
14. Inspect settings at the player's UI scale and screen size; every control must be visible,
    hotkey capture must end on Escape/page close/combat, and there must be no Lua errors.

No shared atomic reservation exists against simultaneous marks from other players.
Server rejection can reserve an icon without placing it: verify actual visible markers,
not the word “requested” or a RAID_TARGET_UPDATE event count.
