# Repository Audit

Audit date: 2026-07-10. Scope: `remnants-mp-bridge`. Evidence sources are the
Lua/Java implementation, static tests, and recorded disposable-world results.

## Architecture found

- `Protocol.lua`: protocol 1, bridge 0.1.2, game 42.19.0 and replica API 1
  handshake; replica snapshot validation.
- `BridgeServer.lua`: listen-server handshake registry and session-only test
  replica records; directed create/update delivery and a bounded movement demo.
- `BridgeClient.lua`: bounded handshake retries, snapshot application, stale
  revision rejection, acknowledgements, diagnostics, and pre-map-load cleanup.
- `ReplicaAgent.java`: client Java agent exposing eight `npcfwReplica*` Lua
  functions. It uses public Project Remnants `NPCManager`, `NPCData`, and
  `IsoNPC` APIs and installs no bytecode transformer.
- The bridge does not contain or modify Project Remnants or vanilla classes.

## Current packet flow

1. Client sends `RemnantsMPBridge/hello` from `OnCreatePlayer` and retries every
   three seconds, at most six times.
2. Server validates versions/readiness and replies with `helloResult`.
3. On the first acceptance, the server creates the shared session-only ID
   `bridge-test-shared-001`. Every accepted joining player receives its current
   `replicaCreate` snapshot.
4. Client calls `npcfwReplicaCreate` and replies with `replicaResult`.
5. The server schedules six test moves after ten seconds, increments revisions,
   and broadcasts `replicaUpdate` every three seconds to all accepted online
   players.
6. Client calls `npcfwReplicaSetPosition`, rejects stale applied revisions, and
   acknowledges each result.

There is an explicit `replicaDestroy` path and current-state delivery on hello.
There is no periodic full-state request, command, ownership lease, combat
transaction, inventory transaction, or save packet. Shared delivery and destroy
are implemented but not runtime-verified.

## Ownership and persistence found

- The listen server chooses test IDs and scripted positions.
- All accepted players receive the same session-only test ID and should render a
  separate local body corresponding to that canonical record.
- Bridge replica AI is disabled (`setBehaviorTree(null)`, cleared tasks,
  stopped movement); therefore no bridge AI owner currently exists.
- Replicas are made invulnerable and detached from Project Remnants persistence.
- `Server.clients`, `Server.replicas`, and client revision maps exist only in RAM.
- No `ModData`, bridge save file, schema, checksum, migration, or load path exists.
- Unmodified Project Remnants AI runs locally in `IsoNPC.tickAI()` and its local
  save is `NPCFW_Data.bin`, according to the recorded installed-mod inspection.

## System classification

| System | Classification | Evidence |
| --- | --- | --- |
| Static layout/safety suite | Confirmed Working | 14 tests pass; this is static evidence only. |
| Host/listen-server handshake | Confirmed Working | Recorded solo Host acceptance on Build 42.19.0. |
| Host inert replica creation | Confirmed Working | Recorded visible body, `inWorld=true`, creation acknowledgment. |
| Host transform transport | Confirmed Working | Recorded revisions 2-5 at four world squares. |
| Guest handshake/API readiness | Working but Untested | Same code path exists; no guest evidence. |
| Java create/update/destroy API | Working but Untested | Create/update have runtime evidence; destroy only static coverage. |
| Cleanup on map change | Working but Untested | `OnPreMapLoad` calls clear-all; lifecycle ordering unverified. |
| Shared NPC creation | Confirmed Working | Host and Steam-invited guest saw the same shared test replica after delayed retry. |
| Persistent identity | Missing | No UUID or saved identity record. |
| Duplicate prevention | Partial | Java map prevents repeated live IDs; no orphan/reload/reconcile protection. |
| Position synchronization | Partial | Broadcast exists but lacks guest evidence, interpolation, and gap recovery. |
| Animation and direction | Missing | No fields or Java setters. |
| AI ownership | Missing | Replica AI disabled; planned host-worker election absent. |
| Target selection | Missing | No implementation. |
| Commands/follow/orders | Missing | No request or lease protocol. |
| Recruitment/groups | Missing | No implementation. |
| Health/wounds/death | Missing | Replica is locally invulnerable. |
| Combat | Missing | No attack intent or damage transaction. |
| Inventory/equipment authority | Missing | Only an outfit string is sent on creation. |
| Vehicle state | Missing | No implementation. |
| Bridge persistence/reload | Missing | All canonical tables are session-only. |
| Late join/reconnect | Partial | Delayed retry produced a visible guest body; disconnect/reconnect remains untested. |
| Disconnect handling | Partial | Tick reconciliation marks accepted clients offline; runtime record remains. |
| Diagnostics | Partial | Debug-gated logs and packet/presence/revision/lookup counters exist; no UI. |
| Personality/memory/trust | Missing | Future living-NPC systems. |
| Jobs/schedules/settlements | Missing | Future community/world systems. |
| Project Remnants save safety in MP | Broken | Recorded `NPCFW_Data.bin` shrink and lost companion after player-death failover. |
| Player-slot/database isolation | Unknown | Designed for it, but sustained two-client evidence is absent. |

## Highest risks and technical debt

1. The new shared topology has no real guest runtime evidence yet.
2. Clearing Java references on Lua environment change may orphan a body if
   `OnPreMapLoad` cleanup did not run first.
3. `NPCManager.spawn()` may have unmeasured local side effects before detachment.
4. There is no explicit destroy/reconcile lifecycle or disconnect cleanup.
5. Revision handling rejects stale packets but does not detect gaps or request a
   complete correction.
6. Direct position changes provide no interpolation, facing, animation, or
   streamed-cell recovery.
7. Current debug logging is unconditional.
8. No Git metadata is available, so historical change attribution is unknown.

The first guest test subsequently confirmed handshake and shared snapshot
delivery but not body creation: `NPCManager.spawn()` returned failure until the
remote square could be loaded. Delayed retries are implemented but unverified.

## Important unknowns

- Whether the same shared ID can remain stable on host and guest for ten minutes.
- Whether client replica cleanup is safe across cell/map reload and reconnect.
- Hidden registries or inventory side effects of Project Remnants `spawn()`.
- Exact Project Remnants bytecode patches beyond the prior recorded inspection.
- Compatibility with the final private mod collection.
