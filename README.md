# Forever Vanguard

Alpha build **0.1.0-alpha.4** for **WoW Forever 1.60.1 / Interface 16001**.

## Attach to your existing attack

1. Install the `ForeverVanguard` folder under `Interface/AddOns`, then restart/reload WoW.
2. Out of combat, type **/fv**. Vanguard lists eligible offensive spells already on your action bars.
3. Click **Attach** beside the targeted attack you want to mark with.
4. Use that ability's existing button or key. It requests Skull on your selected living enemy and casts that attack on the same target.

Discovery is class-independent: it reads the offensive spells actually present on this character’s bars, without a fixed class or opener list. Multiple eligible attacks can be attached independently. This does not certify every class-specific spell in-game.

You do not type a spell name, write a macro, drag a replacement button, or configure a new key. Vanguard creates a character macro internally and puts it in the same action slot, preserving the slot's bindings. It preserves the spell name and available rank text. **This changes that selected slot to a macro**; nothing changes until you click Attach.

Choose a normal, targeted enemy attack. Ground-targeted attacks, toggles, forms, helpful spells and existing custom macros are not supported by this conversion. The scan filters helpful/passive spells, macros and items; the player must choose an appropriate targeted attack from remaining offensive spells. Explicit target routing means this attached action uses your selected enemy, not native mouseover-casting preferences.

**Restore** puts the saved original spell back into that slot. If you edited the slot or generated macro since attachment, Vanguard refuses to overwrite your newer changes. Recovery records are character-specific. Generated macros are retained rather than deleted during restoration. Action slots managed outside WoW's standard slot APIs are not covered.

Attachment/restoration require being out of combat with an empty cursor; creating an action needs a free character macro slot. Existing destination marks are preserved. Marking happens before casting, so a mark can appear even if the spell fails, is out of range, or is on cooldown. A Skull assignment can move Skull from another mob. Normal group marking permissions still apply.

## Optional manual macro builder

`/fv pull [ability]` still provides a manual macro builder for users who want it. Those macros use living hostile mouseover first, then target fallback. The automatic **Attach** workflow above uses only the selected target to match the chosen targeted attack.

## Optional marking controls

The small WoW-styled toolbar is hidden on fresh installs; `/fv bar` toggles it. X closes it, including through a secure hardware click during combat. `/fv bar` visibility changes requested during combat are deferred. Drag its title out of combat to move it.

Separate marking keys are optional and are not assigned on fresh installs. `/fv bind F6` opts into a temporary shortcut and its Shift/Ctrl/Alt combinations when all are available. Existing bindings are preserved; conflicts are reported. `/fv bind off` removes these temporary shortcuts. These do not modify your saved WoW binding profile.

The optional shortcut marks only living hostile mouseover units, with no target fallback:

- Key alone: Skull.
- Shift + key: X.
- Ctrl + key: Moon.
- Alt + key: Square.

Quick Mark preserves an existing mark, including when modifiers are held. Individual icon bindings can be configured in WoW's Key Bindings; Shift with those individual actions explicitly replaces a mark. Moving the cursor onto the toolbar removes mouseover from the enemy, so use keys while hovering the enemy.

## Commands

- `/fv pull [ability]`: configure the combined mark-and-cast action.
- `/fv` or `/fv attach` or `/fv setup`: attach/restore marking on existing action slots.
- `/fv bar`: show/hide the optional toolbar.
- `/fv bind F6`: enable an optional marking shortcut (F1–F12).
- `/fv bind off`: disable addon shortcut overrides.
- `/fv reset`: show and recenter the toolbar.
- `/fv status`: version and marking shortcut on demand.
- `/fv report`: copyable client/input/blocked-action report.

## Validation

46 code tests cover routing, macro creation/reuse and failures, modifier dispatch, binding conflicts, close behavior, both click phases and existing-mark preservation. Tests execute pinned Blizzard Forever Lua action-dispatch and target-marker handlers. Native C APIs, secure trust, hardware input, spell casting and rendering remain modeled.

**Actual PC-client marking, casting, appearance and combat closing remain unverified. This Alpha is for testing and must pass TESTING.md before promotion to stable.** Event counts in `/fv report` do not prove a particular mob was marked.

## Development

Python 3 with `lupa`: `python tests/test_vanguard.py`, then `python build.py`. The builder tests source and extracted ZIP, validates one root addon folder and generates a deterministic archive. Upstream test fixtures are not shipped.

Source evidence:
- Blizzard Forever UI mirror: https://github.com/Ketho/wow-ui-source-forever/tree/forever
- Tanksign secure marking reference: https://github.com/TankerALane/tanksign
- AutoMarkAssist Forever behavior: https://www.curseforge.com/wow/addons/automarkassist/files/9045743/additional-files

Project: https://www.curseforge.com/wow/addons/forever-vanguard
