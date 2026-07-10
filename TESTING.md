# Multiplayer Testing Manual

## Required environment and evidence

- Disposable Host profile and save named `NPCMPTest`; never `servertest` or a
  real multiplayer save.
- One host and one Steam-invited friend on matching Build, Workshop payload,
  bridge, protocol, and companion hashes.
- Retain host-client, guest-client, and listen-server logs, enabled mod lists,
  screenshots/video, exact hashes, test steps, and observed outcome.
- Record before/after player database, bridge save, and `NPCFW_Data.bin` hashes.
- A test passes only when both expected client results and server invariants hold.
- Append actual results to `docs/test-results.md`; do not overwrite failures.
- For a friend-bundle install, retain the installer output and verify it reports
  the detected game path, installed mod path, agent SHA-256, and launch backup.

## Foundation and hosted-world lifecycle

| ID | Test | Expected result / pass criterion |
| --- | --- | --- |
| F1 | Host enters fresh world | One canonical ID and one host body; no player row/save mutation. |
| F2 | Guest joins by Steam invite | Guest receives the same ID/revision; one body on each client. |
| F3 | Ten-minute movement | Same canonical positions/revisions; no duplicate or permanent disappearance. |
| F4 | Guest late joins after creation | Full current snapshot converges without respawning host body. |
| F5 | Guest disconnects/reconnects | Presence/lease clears; same NPC restored once on reconnect. |
| F6 | Move across streamed cells / players separate | Re-entry reconciles to one current body and revision. |
| F7 | Host exits and reloads | After persistence exists: same IDs/state, one body per client. |
| F8 | Disable/remove bridge | Disposable world loads; no new bridge logs or player DB changes. |

Inspect ID, local runtime description, owner, revision, spawn source, packet
counts, invalid lookups, duplicates, and authoritative corrections.

## Ownership and commands

| ID | Test | Expected result / pass criterion |
| --- | --- | --- |
| O1 | Worker election | Exactly one eligible executor; all peers report same owner. |
| O2 | Worker disconnect | NPC freezes safely; no guest invents state. |
| O3 | Control transfer | Old lease rejected; new lease accepted once. |
| O4 | Simultaneous conflicting orders | Deterministic winner; loser gets explicit rejection. |
| O5 | Replay/stale proposal | Duplicate request and stale revision change no state. |

## Persistence and duplicate prevention

| ID | Test | Expected result / pass criterion |
| --- | --- | --- |
| P1 | Five host save/reload cycles | Stable IDs and counts on every cycle. |
| P2 | Five guest reconnects | No duplicate bodies or reset revisions. |
| P3 | Late join with several NPCs | Each canonical NPC materializes exactly once. |
| P4 | Corrupt primary save | Backup/recovery behavior is explicit; no partial spawn. |
| P5 | Older schema fixture | Migration preserves identity and reports version change. |

## Combat

| ID | Test | Expected result / pass criterion |
| --- | --- | --- |
| C1 | NPC takes controlled damage | Server applies once; both clients match health/revision. |
| C2 | Simultaneous player/NPC hit | Target damage is not duplicated. |
| C3 | Replayed attack request | No additional damage. |
| C4 | NPC dies | One authoritative death and matching corpse state. |
| C5 | Disconnect during attack | Server resolves or rejects once; clients converge. |
| C6 | Thirty-minute combat soak | No immortal/desynced targets or mismatched deaths. |

## Inventory and equipment

| ID | Test | Expected result / pass criterion |
| --- | --- | --- |
| I1 | One player transfers one item | One transaction; total item count conserved. |
| I2 | Both players transfer same item | One succeeds; no loss/duplication. |
| I3 | Equip/unequip | Canonical equipment and visuals match both clients. |
| I4 | Reconnect | Inventory/equipment return unchanged. |
| I5 | Host reload | Exact contents and equipment persist. |

## Vehicles

| ID | Test | Expected result / pass criterion |
| --- | --- | --- |
| V1 | NPC enters/exits passenger seat | Same vehicle/seat state; no ghost occupant. |
| V2 | Two NPCs enter | Unique server-assigned seats. |
| V3 | Simultaneous seat requests | One deterministic assignment per seat. |
| V4 | Disconnect while seated | Occupancy remains canonical and recoverable. |
| V5 | Reload with vehicle state | Defined restoration/cleanup occurs without duplicates. |

## Failure symptoms to record

Duplicate portraits/bodies, differing IDs or revisions, rubber-banding without
correction, missing squares, stale bodies after map load, repeated damage,
inventory count changes, ghost seats, unexpected `NPCFW_Data.bin` changes,
player database rows, disconnect errors, Lua stack traces, and unbounded logs.
