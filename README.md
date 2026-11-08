# Forever Vanguard

Local development version 0.2.6 for WoW Forever 1.60.1. Not uploaded or verified in the live client.

## Controls

Hover a living hostile mob and click Mouse 4 once. The mark is requested on button release. Move to the next mob and click again. Holding the button and sweeping does nothing automatically.

`/fv` opens the normal addon settings: enabled state, Mouse 3/4/5 with optional Alt/Ctrl/Shift, icon order, disabled icons, and Start new batch. Close settings before marking. Existing key conflicts are preserved. No macros or action-bar changes are needed.

The hotkey is bound to one secure raid-target button. Outside combat, PreClick checks the current mouseover and available icons, prepares the chosen marker, and lets Blizzard's inherited handler perform the actual hardware click. PostClick disarms it. There are no synthetic clicks, mouse-button polling, or mouseover-triggered marking.

## Combat limitation

**Safe automatic icon selection is out of combat only.** Combat clicks deliberately do nothing. A secure combat guard also prevents execution if combat begins after the marker was prepared. This build does not promise combat cycling or substitute a fixed icon that could steal another mob's mark.

## Icon protection

Already-marked mobs are skipped. The selected icon must be reported free by the client, including icons on unseen mobs. Attempts are reserved across reloads; the order never wraps to a reserved icon. Hidden or unavailable information stops selection. Start new batch releases reservations outside combat; it never clears live marks and selection still checks occupancy.

There is no atomic claim-unused-icon API in this route. Another player assigning the same icon between the check and the action remains a race; use one designated marker. A blocked request or readable failed confirmation disables marking rather than repeatedly trying.

## Installation and validation

Replace the existing ForeverVanguard folder with the one in the local archive. Disable the historical ForeverVanguardSweepTest addon. Reload after installation. Existing settings, including a previously disabled state, are retained.

`/fv report` displays diagnostic results. `/fv off` disables marking. Native permission, rendered settings and actual visible marks still require live Forever validation; passing mocked tests does not establish these outcomes. See TESTING.md.

Run `python build.py` with lupa installed to test source and extracted archive. Packages are written only to dist/local-only. Do not publish before the requested behavior is validated.
