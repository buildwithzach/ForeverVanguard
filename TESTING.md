# Local hardware-click validation

Version 0.2.6 is local only. Native Forever behavior remains unverified.

1. Install the ForeverVanguard folder, disable the old sweep probe, and reload.
2. Open `/fv`, enable if previously disabled, choose unused Mouse 4 and review icon order. Close settings. Test again after reopening and closing settings.
3. Outside combat, hover mob A and click Mouse 4 once. Verify its real raid icon appears on release. Hover mob B without clicking: no mark should appear. Click once: it should receive the next unused icon.
4. Hold Mouse 4 and sweep over several mobs. No repeated marks should appear. Releasing may mark only the enemy currently under the cursor.
5. Reclick a marked mob: its icon stays. Place a mark through Blizzard's UI on another mob, move away from it, then mark a new mob with Vanguard: the externally occupied icon must be skipped. Use one designated marker; concurrent assignments cannot be made atomic by this addon.
6. Exhaust all eight icons: extra clicks do nothing. Start new batch must not clear any existing mark; live occupied icons remain unavailable.
7. Enter combat and click: no marks should be placed or stolen. Settings must explain that safe cycling is unavailable in combat. Leave combat: click marking should resume if enabled.
8. Check a modifier binding and a conflicting existing binding. Confirm existing game bindings are preserved, unbinding stops marking, and `/fv off` stops marking.
9. If the client rejects a marking request, stop. The addon should disable itself. `/fv report` distinguishes attempts, confirmations, failures and unreadable results. Do not treat an attempt log as a visible mark.

The automated tests execute the actual addon and a pinned Blizzard Lua dispatcher. The harness injects hardware/secure permission only for simulated physical binding events; synthetic Click calls raise errors. Tests cover occupied icons, exhaustion, hidden data, disabled/capture/settings states, conflicts, modifiers, combat rejection, and combat beginning between preparation and dispatch. Native C restrictions and in-game UI rendering are not reproduced.
