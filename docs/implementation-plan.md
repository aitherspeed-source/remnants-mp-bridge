# Remnants MP Bridge — Implementation Plan

This plan deliberately front-loads destructive-risk and networking experiments. Each phase ends at a checkpoint; later work does not begin until the checkpoint passes.

## Progress — 2026-07-10

- Completed the isolated Build 42 mod layout and dependency metadata.
- Completed protocol, bridge, game-version, Project Remnants agent, and future replica-API handshake fields.
- Completed server-side validation, directed replies, rate limiting, bounded client retries, and diagnostic state.
- Added rollback, disposable handshake testing, compatibility categorization, and static safety tests.
- Completed an independent companion agent that exposes replica API version 1 without transforming or bundling Project Remnants/game classes.
- Implemented local inert replica create, position update, destroy, cleanup, and Project Remnants persistence detachment.
- Not started: server-issued NPC creation, snapshot movement, AI, combat, inventory, or persistence.
- Current expected runtime result before agent installation: handshake is safely blocked. After both agents are installed, the handshake should pass but no NPC is spawned yet.
- First solo Host run confirmed Project Remnants independently spawned a local companion. It also revealed that Build 42's listen-server loader requires a versioned `42` local deployment; the deploy tool now installs both root and versioned layouts.
- Second solo Host run loaded the bridge on both processes and reached the server handshake. The client version included Build 42 metadata after `42.19.0`; protocol validation now normalizes only the leading three-part version while retaining the raw value in logs.
- Third solo Host run passed: client `handshake accepted`; listen server `accepted=true reason=ready`; raw Build 42 strings matched. The next checkpoint is one server-issued inert replica.
- First inert-replica run passed transport and lifecycle acknowledgments, but the fixed two-tile offset placed the body outside the player's obvious view. Placement now chooses a free reachable adjacent square and the companion forces alpha/outline/halo visibility plus emits a world-membership description.
- Visibility rerun passed: the server-issued body was visible on an adjacent square, `inWorld=true`, with alpha and target alpha at 1.0, and the server received `created=true`. Movement, cleanup/rejoin, and guest visibility remain before the Phase 1 checkpoint is complete.
- Transform transport rerun passed revisions 2–5 and client diagnostics confirmed four distinct world squares, but the six-second sequence completed before it was easy to observe after loading. The visual test now waits 10 seconds, then sends six updates at three-second intervals.
- Replaced the per-player test topology with one shared session-only ID,
  accepted-client broadcast, late-join current snapshot, explicit destroy,
  handshake reconciliation, presence tracking, and gated diagnostics. Static
  tests pass; no runtime claim is made until solo and guest checks are run.
- Version 0.1.5 replaces the hardcoded test ID with a server-generated UUID and
  a bridge-owned GlobalModData schema containing primary/backup checked records.
  Static verification passes; five hosted-world restart restores are next.

## Phase 0 — Permission, baseline, and rollback

1. Ask Pat for permission and, ideally, source access for a private multiplayer compatibility effort. Ask whether multiplayer work already exists and whether a separate dependency mod is acceptable.
2. Record hashes of `NPCFW.jar`, Build 42 revision, and relevant launch files.
3. Create the isolated `NPCMPTest` Host profile and a fresh disposable world with no unrelated gameplay mods.
4. Make a reversible local copy of the mod under a new mod ID. Do not copy it into this repository or distribute it until permission is clear.
5. Write install/uninstall scripts that back up and restore launch configuration. Do not patch the live install manually.
6. Run single-player baseline tests and collect `console.txt`, agent startup, patch, and error logs.
7. Run the unmodified mod in the disposable Host world with a guest and document exactly what each process sees. Do not spawn NPCs in an existing save.

Checkpoint: reproducible baseline, verified rollback, and a clear permission/source route. If the game or server fails to start cleanly after uninstall, stop.

## Phase 1 — One inert replicated human

1. Scaffold `RemnantsMPBridge` with `shared`, `client`, and `server` Lua directories and protocol constants.
2. Add handshake messages carrying protocol version, game revision, bridge version, and Java-extension hash.
3. Add a server registry for a single NPC with UUID, revision, appearance seed, transform, and lifecycle state.
4. Add the minimum Java replica API: create, update, and destroy; no AI, combat, inventory, possession, or persistence.
5. Spawn an inert replica on host and guest from the same canonical snapshot.
6. Interpolate movement snapshots and reconcile large errors by a visible debug snap.
7. Test guest join, leave, reconnect, cell unload/reload, host quit, and mod removal.

Checkpoint: both clients see one stable replica for ten minutes; no player slots, player database rows, duplicate bodies, or disconnect errors are created.

## Phase 2 — Commands and host AI worker

1. Implement server-issued AI-worker election restricted to the host client.
2. Add heartbeat and safe freeze on worker loss.
3. Add follow, stay, guard, and move proposals from the worker.
4. Validate maximum speed, teleport distance, Z-level transitions, timestamp/revision, and order ownership on the server.
5. Add shared-party command leases with timeout and explicit release.
6. Broadcast accepted state at a conservative rate, starting at 5–10 Hz, with client interpolation.
7. Add latency, packet-loss, stale-command, and malicious-command tests.

Checkpoint: host and guest can alternate commands without divergent NPC state; invalid movement and stale revisions are rejected.

## Phase 3 — Server-authoritative melee combat

1. Replicate target and attack-intent animations separately from damage.
2. On the server validate attacker state, target identity, distance, line of sight, weapon, cooldown, and current revision.
3. Apply damage exactly once on the server and broadcast the resulting health/death revision.
4. Define zombie targeting of NPCs and verify that target selection is consistent for both clients.
5. Test simultaneous player/NPC hits, zombie death, NPC death, corpse cleanup, disconnect during attack, and replayed request IDs.

Checkpoint: a 30-minute two-player combat session produces no duplicated damage, immortal/desynchronized zombies, or mismatched NPC death state.

## Phase 4 — Persistence and basic equipment

1. Persist canonical NPC records on the listen server with magic, schema version, checksum, and backup generation.
2. Save identity, appearance, transform, health, death state, accepted order, and a minimal equipment record.
3. Add transactional equip/unequip requests validated against canonical ownership.
4. Restore after host restart and reconcile after guest late join.
5. Add migration tests for at least one older schema and recovery behavior for a corrupt primary file.

Checkpoint: five save/restart cycles and five guest reconnects restore the same NPC UUIDs and equipment without item duplication or loss.

## Phase 5 — MVP hardening

1. Add server options for enable, maximum NPC count, snapshot rate, command permissions, and recovery-only mode.
2. Add structured logs and an in-game diagnostics panel.
3. Run compatibility tests with no other mods, then with the private group's normal mod list one mod at a time.
4. Run soak tests: idle, travel, combat, cell boundaries, player death/respawn, host shutdown, and forced disconnect.
5. Freeze a tested matrix of game revision, mod hash, protocol version, and known limitations.
6. Package only if explicitly requested and legally permitted.

Checkpoint: two players complete a two-hour disposable-world session and a restart/reconnect cycle with no state divergence or save damage.

## Later feature gates

Treat each as a separate opt-in phase with its own disposable save:

- ranged combat and reloads;
- full inventory transfer UI;
- vehicle passenger behavior, then driving;
- party sleep/time handling;
- possession/control switching.

Possession is last because an `IsoPlayer` body is coupled to a real multiplayer connection, player database identity, camera, input, and anti-cheat validation.

## Test evidence to retain

For every checkpoint retain:

- client logs from both players and the listen-server log;
- exact game revision and all enabled mod IDs/hashes;
- test steps and observed result;
- before/after player database and bridge-save hashes;
- screenshots or short video showing both client views when visual synchronization matters;
- rollback result after disabling the bridge.

## Immediate next action

Install Project Remnants and the independent companion agent on both clients, then install the Lua bridge into a disposable `NPCMPTest` profile and run the handshake checklist. Do not implement combat or persistence first; after the handshake passes, the first gameplay milestone remains one inert replicated human.
