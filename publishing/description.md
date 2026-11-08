## Mark the pull. Lead the pack.

**Forever Vanguard** gives tanks a compact target and mouseover marking bar, configurable keybinds, and a mark-and-pull macro builder for **WoW Forever 1.60.1**.

**Initial alpha:** live-client combat behavior and appearance still need validation. This build is for testing and feedback, not a stable release. It uses player-triggered clicks, keybinds, and macros; it does not automatically detect hits or mark enemies on its own.

### Fast marking, fewer keys

- **Quick Mark:** Skull normally, X with Shift, Moon with Ctrl, and Square with Alt.
- **Individual icons:** all eight raid target icons plus Clear, with assignable keybinds.
- **Mouseover first:** mark a living enemy under your cursor, falling back to your current hostile target. Target-only and mouseover-only modes are also available.
- **Keep existing marks:** normal marking preserves a mark already on that mob. Shift with an individual icon replaces it; Quick Mark preserves it with every modifier.
- **Readable controls:** keybind labels, a target/mouseover preview when readable, and a movable bar with saved settings.
- **Quiet by default:** no automatic party announcements or chat spam.

### Mark and use your opener on one press

Type **/fv pull** followed by your opening ability's exact name. Vanguard generates a macro you can copy into WoW's macro window. The macro requests Skull and casts your chosen ability with the same target/mouseover conditions.

Existing marks on that mob are preserved. Marking is attempted before casting, so a mark does not mean the ability landed. The addon does not choose an ability, change your action bars, or execute the macro automatically. Regenerate the macro if you change targeting modes.

### Get started

1. Install the latest Forever Vanguard alpha and restart the client.
2. Type **/fv setup** for the in-game guide.
3. Open **Options > Key Bindings > Forever Vanguard** and assign Quick Mark or individual icons.
4. Hover a living enemy's model or nameplate and press the key. With no valid mouseover, the default mode uses your target.

**Use keybinds for mouseover marking.** Clicking the bar moves the cursor away from the enemy and normally marks your target. Modifier combinations must invoke Quick Mark rather than another game binding; Vanguard never overwrites your keybindings.

### Commands

- **/fv** — show or hide the bar outside combat.
- **/fv auto** — mouseover first, target fallback.
- **/fv target** — target only.
- **/fv mouseover** — mouseover only, no fallback.
- **/fv pull <ability>** — preview a mark-and-cast macro.
- **/fv setup** — open the setup guide.
- **/fv reset** — restore bar position and show it.
- **/fv status** — show addon version and targeting mode.

### Compatibility and installation

**WoW Forever 1.60.1 / Interface 16001 only.** Retail and Classic are not supported. This addon is independent of RP Journal and has no required addon dependencies.

For manual installation, extract the ZIP so the final path is **Interface/AddOns/ForeverVanguard/ForeverVanguard.toc**. Enable **Forever Vanguard** in your AddOns list.

The game's normal marking permissions apply. Each icon can belong to only one unit; assigning an icon may move it off another mob. Bar configuration and movement are restricted to out of combat. Marking uses Blizzard's secure player-input actions.

### Help improve the alpha

Report issues in this project's comments. Include your addon version, client build, targeting mode, steps to reproduce, and any Lua error. Particularly useful reports cover in-combat keybinds, modifier conflicts, raid permissions, and UI scaling. The package includes a testing checklist.
