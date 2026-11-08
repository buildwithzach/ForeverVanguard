> **0.2.2:** `/fv` opens settings again. Hold-and-sweep starts disabled following a live Blizzard-only action block; that restriction is unresolved. See [release notes](publishing/release-0.2.2.md).

> **0.2.1 Alpha:** The current experimental hold-Mouse-4 sweep package is built with `experiments/hold-sweep/build.py` and installs as `ForeverVanguard`. See [release notes](publishing/release-0.2.1.md). Live Forever marking remains unverified. The main addon directory below retains the previous click-per-mob implementation while the experiment is evaluated.

# Forever Vanguard

**0.2.0-alpha.1 — WoW Forever 1.60.1 / Interface 16001**

Hover an enemy and press **Mouse 4**. Move to another enemy and press it again.
Vanguard requests the next unused raid icon without changing your target or creating macros.

**Out of combat only.** Cycling pauses in areas where Forever hides available icons.
This is an installable test build: actual Forever input, secure execution and appearance
are not yet verified. Offline tests cannot establish in-game compatibility.

## Setup

1. Extract the ZIP into your Forever client's `Interface/AddOns` folder. The manifest
   should be `Interface/AddOns/ForeverVanguard/ForeverVanguard.toc`.
2. Restart/reload WoW. **Mouse 4** is selected automatically if it is unbound. Existing
   bindings are never replaced. If it is occupied, choose another key in settings.
3. Open **Options → AddOns → Forever Vanguard**, or type **/fv**.

There is no toolbar, floating panel, attack attachment, macro setup or modifier-specific
icon mapping. `/fv` opens the native settings category.

## Marking

The default order is **Skull → Cross → Square → Moon → Triangle → Diamond → Circle → Star**.
Each press/release handles the living hostile mob under your cursor, with no target fallback.
The button acts on release, so keep your mouse on the mob until you release it.

- Already-marked mobs are left unchanged. Repeated presses on a marked mob do not advance.
- Icons reported in use anywhere are skipped, including other players' marks.
- After every enabled icon has been used or reserved, marking stops. It never wraps and
  deliberately moves a previous icon to another mob.
- Your settings page lets you change the hotkey, reorder the icons and turn individual
  icons on/off. Changes are available out of combat.
- **Start new batch** releases the addon's reservations. It does not clear real marks;
  icons the client still reports in use remain unavailable. No automatic combat/zone reset.
- A request reserves its icon even if the server rejects it. This conservative behavior
  avoids reusing it while a previous request is pending. Start a new batch to retry after
  checking your marks and permissions. “Requested” does not mean success was confirmed.

Marking requires the normal group permissions; raid leaders and assistants can mark.
A custom unit-frame addon may consume Mouse 4 before a global binding receives it. Test
world models and enemy nameplates on the actual client; changing to a keyboard key can
help diagnose input interception.

## Forever limits

The marker itself is placed by Blizzard's secure `raidtarget` action with `set-unmarked`.
Vanguard never calls `SetRaidTarget` directly. Before arming it, the addon checks
`GetRaidTargetIndex` and `GetNextAvailableRaidTargetMarkerIndex` for public results.
If these values are secret, unavailable or invalid, the action stays inert.

Selecting the next unused icon cannot be done with the verified restricted snippet API
in combat, so this build does not offer combat cycling. It never falls back to a blind
counter or substitutes a fixed icon. A secure combat guard also prevents an already
prepared request from firing after combat begins.

The availability check and server assignment are separate operations. Another player's
simultaneous marking can race that check; this build cannot provide an atomic server-side
reservation across players. The persisted per-character reservation list prevents reuse
of this addon's own attempted icons across reloads.

## Upgrading from 0.1.x

Old macro creation and attack attachment have been removed. Existing macros and attack
slots are not automatically modified. If an older build attached marking to an attack,
settings shows **Restore old attack buttons**. It restores saved spell IDs/ranks only
where the original generated macro and slot still match; newer edits are preserved.
Generated macros are retained, but no longer created or used by the new marking flow.

The old toolbar and modifier bindings are retired. The new default is Mouse 4, not the
old optional F-key shortcut. Your unrelated WoW binding profile is unchanged.

## Validation

Run `python tests/test_vanguard.py` with Python 3 and `lupa`, then `python build.py`.
The builder checks the source and the extracted ZIP and writes a SHA-256 sidecar.
Tests run the actual pinned Blizzard Lua dispatcher with modeled native APIs. They cover
allocation, exhaustion, repeated mobs, occupied icons, secrets, combat guards, key conflicts,
settings, persisted reservations and recovery of older attack slots.

See **TESTING.md** for required real-client acceptance. Remains Alpha until it passes.

Source evidence:
- Forever secure dispatcher: https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua
- Forever restricted API: https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/RestrictedEnvironment.lua
- Forever marker API: https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/RaidMarkersDocumentation.lua
