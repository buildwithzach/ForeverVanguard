FOREVER VANGUARD — HOLD SWEEP TEST 1 (Forever 1.60.1)
Experimental diagnostic build. Not uploaded to CurseForge.

INSTALL
Extract ForeverVanguardSweepTest into your Forever client's Interface/AddOns.
Disable the normal Forever Vanguard addon while testing. Enable Hold Sweep TEST.
Temporarily clear any existing Mouse Button 4 game binding, so it does not also
cast/use something. This probe polls the physical button; no binding or macro
setup is needed. No permanent binding changes are made by this addon.

TEST
1. Start out of combat, solo or with raid-marker permission in your group.
2. Hold Mouse 4 BEFORE moving onto a mob. Keep it held and sweep across several
   different hostile mobs. Release. Look for icons and chat diagnostics.
3. Repeat during combat (use /fvtest reset outside combat first if needed).
4. Compare /fvtest click with the default /fvtest direct, repeating both tests.
   Release Mouse 4 before switching routes. These are experimental pathways,
   not claims that Forever authorizes hover-triggered actions.
5. /fvtest report opens a selectable log. Ctrl+A / Ctrl+C and send the text back,
   along with whether you actually SAW icons over the mobs, in/out of combat.
   Include which route you tested. Escape closes the report.

COMMANDS
/fvtest direct  Direct SetRaidTarget from held-button mouseover (default).
/fvtest click   Synthetic click on a preconfigured secure raidtarget button.
/fvtest reset   Reset reserved attempts outside combat, with Mouse 4 released.
/fvtest off     Stop testing immediately.
/fvtest on      Resume testing.
/fvtest report  Copy diagnostics.

RESULTS
HOLD start/end proves the probe observed Mouse 4, not that marking worked.
ATTEMPT identifies the route, icon and combat state.
CALL returned does NOT mean success; protected APIs can silently refuse.
CONFIRMED means a readable marker matched on the same hovered GUID afterwards.
NOT APPLIED means the same hovered mob still did not have the expected icon.
UNVERIFIED means you moved away or marker information became unreadable; check
visually. Pausing briefly over each mob helps confirmation but is not required
for the attempt. BLOCKED/FORBIDDEN events may also come from other addons;
the report records their reported addon and function for correlation.

Preserves readable existing marks and asks the client whether each icon is free.
If either check is secret/unavailable, it SKIPS instead of guessing. This can
prevent a combat attempt; the log distinguishes that from a blocked marker call.
Each attempted icon is reserved, including failures. After eight attempts the
probe stops rather than wrapping and stealing earlier icons. Reset between
runs as needed. Reservations survive reloads. Reset does not remove raid marks.
A group member assigning the same icon concurrently is outside this probe's
control; test with one marker at a time.

Logs (last 400 lines) persist after /reload or clean logout in your character's
WTF/Account/.../<realm>/<character>/SavedVariables/ForeverVanguardSweepTest.lua.
Mouse4 detection, native authorization, and real combat behavior need your live
Forever test. Six local mocked tests cover code flow, not the game's engine.
Disable/remove this separate addon to return to the released version.
