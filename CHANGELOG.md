## 0.2.2

- Restore /fv settings access with mouse-button and icon-order controls.
- Start experimental marking disabled and stop after a blocked action.
- Preserve disabled state across reloads. Blizzard-only action restriction remains unresolved.

## 0.2.1

- Package the experimental hold-Mouse-4 sweep probe under the normal Forever Vanguard name.
- Add direct-call and synthetic secure-click routes, blocked-action diagnostics, and copyable reports.
- Preserve readable existing marks, reserve attempted icons, and skip secret/unavailable allocation data.
- Six mocked tests pass against source and extracted package; live Forever behavior remains unverified.

# 0.2.0-alpha.1

- Replace attack attachment, macro setup, modifier shortcuts and toolbar with one Mouse 4 mouseover action.
- Add a native settings category for hotkey capture, icon order, enabled icons and new batches.
- Preserve existing marks, skip globally occupied icons, reserve attempted icons per character and stop at exhaustion.
- Fail closed in combat and when Forever hides marker availability. Combat cycling is not implemented.
- Keep recovery-only support for old attached attack slots; never overwrite newer slot/macro edits.
- Actual PC-client behavior remains unverified; see TESTING.md. No publishing performed.

## 0.1.0-alpha.4 — 2026-11-08

- `/fv` lists existing offensive spell slots with explicit Attach/Restore controls.
- Create the combined target-mark-and-cast macro internally and place it in the same slot; no manual macro authoring, dragging or new keybind required.
- Save character-specific original spell IDs before replacing a slot. Refuse restoration over newer user edits.
- Preserve rank text, reuse matching generated macros, and guard combat, occupied cursor, stale slot selection and storage/placement failure.
- Alpha testing release: code-only validation; actual PC client and custom-bar compatibility remain unverified.

## 0.1.0-alpha.3-dev — Unreleased

- Make the opening-ability macro the primary workflow: mouseover first, then living hostile main target; marking and casting share the exact same conditionals.
- Add an ability field and Create & pick up action button; safely create/reuse a character macro for a one-time action-bar placement.
- Fresh installs hide the optional toolbar and assign no separate marker keys.
- Add native target-marker-handler tests and macro creation/reuse/failure checks. Gameplay still unverified; no publication.

## 0.1.0-alpha.2-dev — Unreleased

- Replace the large panel with a 380 × 144 WoW-textured toolbar; icon guidance lives in tooltips.
- Add a secure close button, persistent hidden state, and deferred slash-command toggling during combat.
- Mouseover-only routing, including migration from older saved target modes.
- Ready-to-use conflict-free F6–F9 shortcut; Shift X, Ctrl Moon, Alt Square. Session overrides leave persistent bindings untouched.
- Fix modifier action lookup with `*type1`; upstream dispatcher regression tests replace handmade marking simulation.
- Use `/targetmarker` in generated macros to avoid `/tm` addon alias collisions.
- Add `/fv report` for input, marker-event and blocked-action evidence.
- Retain optional individual-icon bindings and setup controls. Live rendering and combat close need in-game acceptance.

# Changelog

## 0.1.0-alpha.1 — 2026-11-07

Initial CurseForge alpha submission. In-game validation remains pending.

### Local improvements, 2026-11-07

- Quick Mark: Skull, Shift-X, Ctrl-Moon, Alt-Square through one secure control.
- Live binding badges and safe destination preview; no polling or chat spam.
- In-game setup guide and `/fv pull <ability>` copyable macro builder.
- Pull macros use native `~8` preservation and identical mark/cast unit conditions.
- Block command injection and overlength macros; do not edit action bars or bindings.
- Package as an alpha for testing; do not claim live-client validation.

### Initial local build

- Separate WoW Forever target/mouseover marking bar and nine assignable keybinds.
- Mouseover-first, target-only, and mouseover-only modes.
- Preserve the selected unit's existing mark; Shift to replace; explicit Clear.
- Secure hardware-click routing, out-of-combat configuration, saved position, quiet defaults.
- No automatic combat-log or first-hit marking.
