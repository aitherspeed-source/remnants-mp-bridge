# Remnants MP Bridge — Design

## Status

Phase 1 persistent-identity spike in progress. The versioned handshake,
diagnostics, independently compiled Java companion extension, shared replica,
and schema-1 canonical identity save exist. Persistence is implemented but not
runtime-verified; canonical gameplay does not exist.

Target runtime: Project Zomboid unstable Build 42.19.0, revision 964, using the in-game **Host** flow (a listen server plus host client), with one invited friend.

## Goal

Provide a small party of friendly human NPC companions that the host and one invited player can see, fight beside, command, and persist safely in the same private multiplayer world.

The initial release is successful when both players observe the same NPC identity, position, health, death state, equipment, and current order after normal play, reconnects, and a host restart.

## Evidence from the installed mod

The inspected Workshop item is `3738362476`, mod ID `ProjectRemnants`, located outside this repository at:

`D:\Steam\steamapps\workshop\content\108600\3738362476\mods\ProjectRemnants`

Project Remnants is not a normal Lua-only mod:

- `NPCFW.jar` is a Java instrumentation agent. It patches core classes including `IsoPlayer`, player death/save paths, combat, rendering, and XP behavior.
- An NPC is an `IsoNPC` subclass of `IsoPlayer`, created directly in the local `IsoWorld` cell.
- The Java framework contains no references to `GameClient`, `GameServer`, `UdpConnection`, `ServerMap`, `ServerPlayerDB`, or an equivalent replication layer.
- NPC AI runs locally in `IsoNPC.tickAI()` and NPC state is saved locally to `NPCFW_Data.bin`.
- Runtime NPCs are deliberately removed from `IsoPlayer.players`; non-possessed NPCs report that they are not local players.
- The installer patches only `ProjectZomboid64.json`. It does not install an agent into the separate server JVM started by the game's Host flow.
- The Lua entry point calls initialize, load, tick, and save directly without separating client, host, and server authority.

These facts explain why enabling the existing mod in a multiplayer host does not provide synchronized NPCs. At best, an NPC exists only inside the client process that created it. At worst, save/player-slot patches conflict with multiplayer player persistence.

## Decision

Do not edit the subscribed Workshop folder and do not try to make every client run an independent copy of the same NPC AI.

The implementation is a separate mod named `RemnantsMPBridge`, with Project Remnants used as a client-side rendering/runtime dependency only. Because its source is unavailable, the bridge supplies an independent Java companion extension compiled against public APIs. The existing jar is not copied, modified, or redistributed as part of this repository.

If source access is unavailable, the fallback is a clean-room NPC framework that uses only local game APIs and behavior requirements learned from testing. Decompiled Project Remnants source must not be committed or copied into the implementation.

## Authority model

The Host flow still starts separate server and client processes. Therefore the server process, not the host player's client, owns canonical multiplayer state.

```text
Host client (AI worker) ---- intent/state proposal ----> Listen server
Guest client ---------------- commands ----------------> Listen server
                                                     validate + persist
Host client <--------------- canonical snapshots -------+
Guest client <-------------- canonical snapshots -------+
   |                                                     |
   +-- local visual/animation replica                    +-- health, inventory,
                                                           orders, ownership,
                                                           damage and death
```

For the first version, the host client may calculate navigation and behavior because Project Remnants already expects a rendered client world. The listen server validates its proposals and remains authoritative for position limits, orders, health, combat results, inventory changes, and persistence. If the host client's AI worker disappears, NPCs freeze safely rather than allowing a guest to invent state.

Every NPC has a stable UUID and monotonically increasing state revision. Commands include the player identity, NPC UUID, expected revision, and a request ID. The server rejects stale, duplicated, unauthorized, or physically impossible requests.

Both players share the party. A short server-issued control lease ensures only one player can issue direct orders to a given NPC at a time. The host's AI worker executes the accepted order.

## Runtime components

### Server Lua

- Canonical registry: identity, appearance seed, position, health, order, stance, inventory summary, owner/lease, and revision.
- Command validation and rate limiting.
- Interest filtering so snapshots are sent only to nearby players.
- Save/load under a bridge-specific versioned key or file; never overwrite `NPCFW_Data.bin`.
- Join snapshots, disconnect handling, and host-AI-worker election.
- Server-side combat and inventory transaction validation.

### Client Lua

- Party UI and commands routed through `sendClientCommand`.
- Snapshot interpolation and reconciliation.
- Join/leave creation and cleanup of visual replicas.
- No canonical save writes and no autonomous replica AI.
- Debug overlay for UUID, revision, authority, lag, and replica error.

### Java extension

The extension must expose narrowly scoped APIs rather than additional broad game patches:

- create/destroy a visual replica with a server-provided UUID and appearance;
- enable/disable autonomous AI;
- apply canonical transform, animation, equipment, health, and death state;
- capture an AI worker proposal without committing canonical combat or inventory results;
- guarantee replicas never enter `IsoPlayer.players`, player databases, or connection ownership tables;
- disable possession/control switching in multiplayer.

The companion uses public `NPCManager`, `NPCData`, and `IsoNPC` methods to spawn a body, disable its behavior tree and task queues, detach it from Project Remnants persistence, and map it to the server UUID. It installs no bytecode transformers. This path still requires runtime verification after every Project Remnants or Build 42 update because those public APIs are not a stable modding contract.

## MVP scope

Included:

- one to three friendly NPCs;
- stable identity and appearance;
- idle, follow, stay, guard, and simple melee combat;
- visible movement and animation on both clients;
- authoritative health/death;
- basic equipment display;
- save, host restart, guest reconnect, and late join;
- one-at-a-time command leases shared by host and friend.

Deferred until the MVP is stable:

- possessing or switching control to an NPC;
- NPC driving and vehicle-seat swapping;
- firearms, reloading, and detailed ballistics;
- full drag-and-drop party inventory;
- sleeping/time acceleration;
- hostile factions, roaming world populations, and off-screen simulation.

Those features touch connection ownership, vehicles, ballistics, or global time and are substantially riskier than synchronized companions.

## Safety and compatibility

- Develop under a new mod ID and a disposable server profile named `NPCMPTest`.
- Never edit the Workshop item in place; Steam can replace it without warning.
- Never use `servertest` or an existing multiplayer save for development.
- Back up launch JSON before installing any Java agent and retain an uninstall script/rollback note.
- Both players must use the exact same Build 42 revision, Workshop version, bridge version, and Java extension hash.
- The bridge refuses to start on an unknown game revision or mismatched protocol version.
- A server option disables NPC spawning while still allowing data recovery/export.
- Snapshot files use a magic value, schema version, checksum, and atomic temporary-file replacement.
- Build 42 unstable updates are treated as compatibility events requiring the smoke suite before play resumes.

## Go/no-go criteria

Continue with the bridge architecture only if the Phase 1 replica spike proves all of the following:

1. A non-player human replica can exist on both clients without occupying a player slot or requiring a network connection.
2. Repeated transform/animation reconciliation remains stable for ten minutes with no duplicate bodies or save corruption.
3. A server-validated melee hit can damage the same zombie exactly once for both players.
4. Removing the mod leaves the disposable world loadable and does not alter either player's database record.

If criteria 1 or 3 fail, stop adapting the `IsoPlayer` approach. The fallback becomes a clean-room server-native entity design, which is a larger project and should be planned separately.
