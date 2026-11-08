Forever Vanguard 0.2.2

Fixes the missing /fv command. Opens a settings window with marking enable/disable, Mouse 4 or Mouse 5 selection, icon order, icon reservation reset, and diagnostic report. /forevervanguard and /fvtest remain available.

Hold-and-sweep starts disabled because a Blizzard-only action block was reported in live testing. A blocked attempt automatically stops further marking attempts; disabled state persists across reloads. This update fixes settings access, not Blizzard's action restriction. Hold-and-sweep remains unresolved.

Eight local control-flow tests pass against source and the extracted package, including opening /fv and stopping after a blocked action. Actual in-game UI rendering still needs confirmation.
