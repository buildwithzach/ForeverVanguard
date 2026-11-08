## Forever Vanguard — Alpha testing release

Mark with an existing tank attack in **WoW Forever 1.60.1**. In version **0.1.0-alpha.4**, open `/fv` and click **Attach** beside an eligible offensive spell already on your action bar. Vanguard creates the combined mark-and-cast macro internally and puts it in the same slot, retaining that slot's usual key. **Restore** returns the saved original spell.

**Alpha status:** actual PC-client gameplay, appearance and class-specific compatibility remain unverified. 46 code tests pass using Blizzard Lua dispatch code with modeled native APIs. This is a testing release, not a stable or fully automatic marking addon.

### Get started

1. Install version 0.1.0-alpha.4 and reload the game.
2. Out of combat, with an empty cursor, type `/fv`.
3. Choose a normal targeted enemy attack and click **Attach**.
4. Use that ability's normal button/key. The action requests Skull and casts on your selected living hostile target.

Attachment is explicit and uses a character macro slot. No actions change merely by opening the window. Discovery is class-independent; multiple eligible attacks can be attached separately. Existing macros, helpful/passive spells and items are skipped. Ground-targeted attacks, forms, toggles and custom action bars are not certified. Restore refuses to overwrite newer manual edits to a slot or generated macro.

### Marking behavior

Existing marks on the chosen enemy are preserved. A Skull assignment may move Skull from another mob. Marking happens before casting, so a mark does not prove that the spell succeeded. Normal group marking permissions apply.

Attached attacks use your selected target. Optional separate marking keys use living hostile mouseover only. Passive hover-only marking and automatic first-hit detection are not implemented.

### Optional tools

- `/fv bar`: compact WoW-styled marker toolbar, hidden on fresh installs, with an X close button.
- `/fv bind F6`: opt into an available marker shortcut; existing bindings are preserved. Shift selects X, Ctrl Moon, Alt Square. `/fv bind off` disables addon shortcut overrides.
- `/fv pull [ability]`: optional manual macro builder using mouseover first, then target fallback.
- `/fv report`: copyable client and blocked-action diagnostics.

### Install and feedback

Forever 1.60.1 / Interface 16001 only; no addon dependencies. Extract the ZIP so the manifest is at `Interface/AddOns/ForeverVanguard/ForeverVanguard.toc`.

Report issues in project comments with addon/client versions, steps and Lua errors. The ZIP includes an in-game acceptance checklist. Alpha files may require direct website download rather than appearing in normal CurseForge client listings.
