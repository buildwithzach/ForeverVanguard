# Upstream dispatcher fixture

BlizzardSecureTemplates.lua is an unmodified copy of Blizzard UI source mirrored at:
https://github.com/Ketho/wow-ui-source-forever/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua

Retrieved 2026-11-07. SHA256 b6e91f1d54f269a8bd66312b368e6fd7706028d366eee0167161ace9004cae23.
Copyright remains with the upstream author. Test-only; not included in addon ZIP.

native_dispatch.lua executes the original functions; native GetAttribute resolution, C marking APIs, input events and secure trust are modeled. This increases coverage over handmade action simulation but does not certify a live client or secret-value behavior.

Before changing type1 to *type1, three existing tests fail with this dispatcher: Shift overwrite, Quick Mark modifiers, and Shift marking a new mouseover. All passed under the old handmade simulation. Real keydown/keyup dispatch is also covered.

BlizzardTargetMarker.lua is the unmodified TARGET_MARKER registration excerpt from the same Forever source tree, Blizzard_ChatFrameBase/Shared/SlashCommands.lua, retrieved 2026-11-07. The native handler is executed in combined-action tests; macro conditional parsing and spell outcomes are modeled.
