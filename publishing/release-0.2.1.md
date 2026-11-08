Forever Vanguard 0.2.1

Experimental hold-and-sweep Alpha for WoW Forever 1.60.1.

Hold Mouse 4 continuously while moving over hostile mobs to test sequential raid marking, in and out of combat. No macro setup. Clear any existing Mouse 4 game binding before testing.

This is an instrumented test build: actual marking and combat compatibility remain unverified. It skips unreadable marker information and does not recycle attempted icons. The older settings screen and click-per-mob mode are not included in this Alpha.

Use /fvtest report to copy diagnostic results; /fvtest click tests the alternate secure-button route; /fvtest direct restores the default route. Use /fvtest reset outside combat between runs and /fvtest off to stop.

Installs as the normal ForeverVanguard addon. Disable/remove the separate ForeverVanguardSweepTest addon if you installed the earlier local test ZIP.

Validation: six mocked control-flow tests passed against both source and the extracted release ZIP. Live Forever validation is still required.
