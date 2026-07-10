# Architectural Decisions

Reconsider an accepted decision only when new runtime, API, compatibility, or
performance evidence is recorded.

## D-001: Separate compatibility mod

- **Decision:** Implement as `RemnantsMPBridge`; do not edit the Workshop mod.
- **Reason:** Steam can replace subscribed files and rollback must be safe.
- **Alternatives:** Patch the subscribed directory; fork/copy the original mod.
- **Consequences:** Project Remnants remains a dependency; both clients install
  the bridge separately; original payload is not redistributed.

## D-002: Listen server owns canonical state

- **Decision:** Permanent NPC state and validation belong to the Host flow's
  separate listen-server process, not the host player's client.
- **Reason:** Clients cannot safely be trusted to independently commit NPC state.
- **Alternatives:** Host-client authority; peer-to-peer replicas.
- **Consequences:** Clients submit requests/proposals and render corrections;
  persistence must be available to server Lua.

## D-003: One executor per NPC

- **Decision:** Never run independent canonical NPC AI on multiple machines.
- **Reason:** Project Remnants AI is local and would diverge or duplicate actions.
- **Alternatives:** Every client runs AI; last-writer-wins state.
- **Consequences:** Planned host-worker election requires heartbeat and safe freeze.

## D-004: Client-only inert Project Remnants replicas for Phase 1

- **Decision:** Use `NPCManager.spawn()` for a local body, disable behavior/tasks,
  make it non-damaging/invulnerable, and detach it from Remnants persistence.
- **Reason:** This tests whether the existing runtime can render a safe replica
  without first building gameplay systems.
- **Alternatives:** Server-native entity; immediately synchronize full Remnants AI.
- **Consequences:** API is unstable and must be reverified after updates; Phase 1
  go/no-go decides whether to retain this approach.

## D-005: Independent narrow Java companion

- **Decision:** Expose narrowly scoped replica functions without bytecode
  transformers or bundled game/Remnants classes.
- **Reason:** Reduce patch conflicts and redistribution risk.
- **Alternatives:** Transform core classes; modify `NPCFW.jar`.
- **Consequences:** Both clients require matching agents; separate server JVM is
  not patched; lifecycle depends on public Remnants APIs.

## D-006: Separate bridge persistence

- **Decision:** Future canonical saves must use a bridge-owned, versioned format,
  never `NPCFW_Data.bin`.
- **Reason:** Remnants persistence is local and showed unsafe hosted-MP behavior.
- **Alternatives:** Share or overwrite the Remnants save.
- **Consequences:** Identity migration and recovery must be designed explicitly.

## D-007: Feature-gated phased delivery

- **Decision:** Identity/lifecycle precede AI, which precedes combat/inventory;
  vehicles and living-world systems remain later opt-in phases.
- **Reason:** Each layer depends on authority and duplicate prevention below it.
- **Alternatives:** Implement the full survivor system vertically at once.
- **Consequences:** Early releases are intentionally narrow and test-heavy.

## D-008: Public GitHub release update channel

- **Decision:** Publish bridge source and checksum-verified install bundles at
  `aitherspeed-source/remnants-mp-bridge`; friends keep one updater BAT.
- **Reason:** Avoid manually transferring every test build while retaining
  reproducible releases and integrity verification.
- **Alternatives:** Discord ZIP transfers; private authenticated repository;
  Steam Workshop distribution.
- **Consequences:** Bridge source is public. Project Remnants/game binaries remain
  excluded. Tag releases publish a ZIP and `latest.json`; the updater refuses a
  checksum mismatch and preserves the installed copy on download failure.
