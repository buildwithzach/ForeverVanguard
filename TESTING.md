# Existing-slot attachment acceptance — not performed in the PC client

1. Out of combat and with an empty cursor, open `/fv`. Confirm your targeted tank attack appears in its correct slot. Opening must not change any action or macro.
2. Click Attach. Confirm the same slot and key now show the expected spell/rank and that other slots and existing macros are untouched.
3. Select a living enemy, keep mouseover on a different enemy, and use the original ability key. The selected target should get Skull and the selected attack; mouseover must not redirect this attached action.
4. Repeat in combat, on a mob with an existing mark, with no valid hostile target, and with an out-of-range or cooldown-blocked cast. No taint/errors; an attempted mark is not proof the cast succeeded.
5. Out of combat, click Restore. Verify the exact original spell ID/rank is back in the same slot and its binding is unchanged. Reload before restoring in a separate run to verify saved recovery data.
6. Test a manually edited slot and manually edited generated macro: Restore must preserve the newer edits and report refusal.
7. Test full macro storage, occupied cursor and combat attachment: original action must remain untouched.
8. Custom action-bar addons and ground-targeted/toggle/form abilities are not certified. Test only a normal targeted attack first. Existing custom macros and helpful/passive spells are excluded from attachment.

Code tests exercise simulated action-slot mutation/restoration and the original Blizzard Lua marker handler/dispatcher. They do not prove secure native execution, rendering or actual spell outcomes. User runs the game on another PC and requested code-only work here. **Promotion to a stable release remains blocked until in-game acceptance.**

`/fv report` provides addon marker input/blocked-action diagnostics, but executing an attached macro uses the normal action-bar path and does not increment Vanguard's separate marker-button input count. Observe actual mark/cast results; event counts are not proof.
