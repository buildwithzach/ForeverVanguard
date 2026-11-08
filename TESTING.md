# Local secure-route validation

This build is not published. Actual Forever authorization and UI rendering remain unverified.

1. Install the actual ForeverVanguard folder; disable the separate old sweep probe.
2. Open `/fv`. Confirm the normal key and icon-order controls appear. Choose an unused Mouse 4 and enable marking if previously disabled. Close settings.
3. Out of combat, hold Mouse 4 before moving over two hostile mobs. Keep holding as you move, then release. Confirm whether two distinct icons actually appear and further mouseover no longer marks.
4. Revisit a marked mob and check that it keeps its icon. Check that another mob does not take an occupied icon. Only one player should mark during this check.
5. Release, use Start new batch outside combat, then close settings and enter combat. Repeat the held-button sweep. The addon will skip unreadable marker information; a skip is not a successful or forbidden action.
6. If blocked, stop: the addon disables itself. Copy `/fv report`. Do not re-enable repeatedly. Report the actual visible icons as well as the log.

No icon should be cleared by reset. No ability or macro should be created or replaced. Existing normal key conflicts should be reported and left intact.

Automated tests exercise the actual addon and pinned Blizzard Lua dispatcher against mocked native APIs. Permissive dispatch tests are deliberately hypothetical. Rejection tests verify that denial is reported and further attempts stop. These tests cannot certify native combat permissions or synthetic-click trust.
