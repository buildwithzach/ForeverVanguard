# Forever Vanguard

Local development version 0.2.3 for WoW Forever 1.60.1. This is the actual `ForeverVanguard` addon, with its normal `/fv` settings. It has not been uploaded.

## Controls

Hold Mouse 4 and move across living hostile mobs. Release to stop. `/fv` opens Options > AddOns > Forever Vanguard. Configure Mouse 3/4/5 with optional Alt/Ctrl/Shift, change icon order, disable individual icons, or disable marking. Other game bindings are preserved; choose an unused button. Close settings before sweeping.

The addon preconfigures eight secure raid-target buttons outside combat. Mouseover changes while the chosen button is held request a synthetic click on the selected button. There are no direct SetRaidTarget calls, user macros, or click-per-mob fallback.

**The real client may reject synthetic secure-button clicks. Merely using a secure button does not grant hardware-input permission. This route has not been validated in Forever.** Version 0.2.1's direct route was forbidden on build 70862; that route is removed from this addon. Local tests are not evidence that the native client accepts the new route.

## Icon protection

Already-marked mobs are skipped. Each candidate icon must be reported free by the client, including icons on mobs outside your current mouseover. Attempts are reserved across reloads, and the cycle never wraps to a used icon. If marker information is secret or unavailable, marking pauses rather than guessing. Group members assigning icons concurrently remain a server-side race; use one marker during validation.

Start new batch releases reservations outside combat after releasing the button; it does not clear live marks. Any blocked action during the request disables marking. A readable failed confirmation also disables it, avoiding repeated blocked calls. Enable again in `/fv` only when ready to retry.

## Installation and validation

Replace the old `ForeverVanguard` folder with the folder from the local ZIP. Disable/remove the earlier separate `ForeverVanguardSweepTest` addon. Restart or reload after installation. Old normal settings are preserved; a previously disabled normal addon stays disabled.

`/fv report` opens a copyable diagnostic report. `/fv off` stops marking, including in combat. Reports record secure attempts and distinguish confirmed markers, rejected requests, and unreadable or changed mouseover results. They are saved per character after reload/logout.

Run `python build.py` using Python with `lupa` installed. The build tests source and extracted ZIP, and writes only to `dist/local-only`. The isolated historical probe cannot be packaged as the normal addon by its builder.
