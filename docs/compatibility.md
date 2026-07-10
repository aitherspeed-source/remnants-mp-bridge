# Compatibility Strategy

Universal compatibility cannot be guaranteed, but the bridge is designed to coexist with broad content mod lists and to fail closed when a critical runtime mismatch is detected.

## Expected low-risk categories

- maps and map additions;
- recipes and crafting content;
- ordinary items, food, and literature;
- clothing and appearance packs that use vanilla body locations;
- UI additions that do not replace party or player inventory classes;
- vehicles before NPC vehicle support is enabled.

## Audit-required categories

- mods with Java agents or custom jars;
- mods that patch `IsoPlayer`, player save/load, death, XP, or animation;
- combat, ballistics, firearm, damage, or zombie-targeting overhauls;
- inventory replacements and anti-duplication systems;
- vehicle physics or seat-management overhauls;
- anti-cheat, networking, packet, or server-authority changes;
- mods that replace the same Lua event handlers instead of adding handlers.

## Compatibility rules

1. The bridge never replaces vanilla Lua files.
2. All globals, command modules, save keys, and log prefixes use `RemnantsMPBridge`.
3. The server owns canonical NPC state and rejects unknown commands.
4. Both players must have matching game, bridge protocol, bridge version, and Java replica API versions.
5. Optional NPC features are gated separately so combat, inventory, firearms, or vehicles can be disabled when another mod conflicts.
6. Compatibility shims live in their own files and activate only when the target mod is detected.
7. The actual private mod collection is tested incrementally and recorded below.

## Private collection test matrix

Populate this table from the final `Mods=` and `WorkshopItems=` lists before Phase 3.

| Mod ID | Workshop ID | Version/hash | Category | Result | Disabled bridge feature | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| ProjectRemnants | 3738362476 | pending | Java/NPC framework | required | none | Exact jar hash must match both clients. |
| RemnantsMPBridge | public release | 0.1.2 | networking bridge | baseline | none | Protocol 1. |

Test the base pair first, then add the normal collection in small groups. If a group fails, bisect that group until the conflicting mod is identified. Never diagnose a compatibility failure in the real save.
