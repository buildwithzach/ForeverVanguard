# Forever Vanguard 0.1.0-alpha.4

For WoW Forever 1.60.1 (Interface 16001) only.

- Open `/fv` to attach Skull marking to an existing targeted attack. Vanguard creates the macro internally and installs it in the same action slot, retaining its usual key.
- Restore puts the original spell back. Existing custom macros, newer user edits, and unrelated action slots are preserved.
- Class-independent discovery of offensive spell slots; targeted attacks only. Ground-targeted abilities, forms, toggles, and custom action-bar behavior are not certified.
- Smaller WoW-styled optional toolbar, secure close button, corrected modifier dispatch, and `/fv report` diagnostics.

This is an **Alpha for testing**, not fully automatic hover marking. Attach is a one-time explicit choice per ability. Existing destination marks are kept, and marking may occur even if a cast fails.

46 code tests pass on source and extracted ZIP, including Blizzard Lua action dispatch. Native APIs, trust boundaries, and casting are modeled. **Actual PC-client gameplay, rendering, and class-specific compatibility remain unverified.**

Install the `ForeverVanguard` folder from the attached ZIP into `Interface/AddOns`. Use the packaged addon ZIP, not GitHub's source-code archive. See TESTING.md for in-game acceptance steps.
