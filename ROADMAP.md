# Roadmap

Status labels must be based on acceptance evidence, not code presence.

## Phase 1: Multiplayer foundation — active

### 1A. Shared inert replica lifecycle — substantially passed; reconnect deferred

- **Purpose:** Prove one server record can produce exactly one corresponding
  inert body on each of two clients.
- **Dependencies:** Existing handshake and replica Java API.
- **Acceptance:** Same ID/revision on host and guest for ten minutes; late join,
  disconnect/reconnect, cell reload, explicit destroy, and mod removal create no
  duplicates, player slots, database rows, or save changes.
- **Testing:** `TESTING.md` Foundation F1-F8 with all three logs and save hashes.
- **Difficulty:** High, because `IsoNPC` is an `IsoPlayer`-derived local entity.

### 1B. Persistent identity and duplicate prevention — current milestone

- **Purpose:** Preserve a canonical NPC across hosted-world reloads.
- **Dependencies:** 1A passed; stable replica cleanup/reconciliation.
- **Acceptance:** Stable server-issued ID through five reloads and reconnects;
  one body per client; versioned save with checksum, backup, migration test.
- **Testing:** Persistence P1-P5 and corrupted-primary recovery.
- **Difficulty:** High.

### 1C. Simulation ownership, movement, and commands

- **Purpose:** Elect one host-client AI worker while the server validates state.
- **Dependencies:** 1B; canonical revisions and presence tracking.
- **Acceptance:** Worker heartbeat/freeze, movement validation, corrections,
  facing/animation, request deduplication, and deterministic command leases.
- **Testing:** Ownership O1-O5, packet loss, stale requests, simultaneous orders.
- **Difficulty:** Very high.

### 1D. Combat, death, inventory, and equipment

- **Purpose:** Add authoritative gameplay transactions after ownership is safe.
- **Dependencies:** 1C.
- **Acceptance:** Damage applied once; matching health/death/corpse; transactional
  equip/transfer without loss or duplication over restart/reconnect.
- **Testing:** Combat C1-C6 and inventory I1-I5.
- **Difficulty:** Very high.

### 1E. Recruitment, groups, permissions, and vehicles

- **Purpose:** Complete shared companion interactions and gated vehicle support.
- **Dependencies:** 1D; persistent membership and inventory authority.
- **Acceptance:** Deterministic recruitment/dismissal/permissions; vehicle seats
  have one server owner and no ghost occupancy. Driving remains separately gated.
- **Testing:** Group G1-G4 and vehicle V1-V5.
- **Difficulty:** Very high.

## Phase 2: Living NPCs

- **Purpose:** Add persistent personality, high-value memories, per-player trust,
  contextual dialogue, and camp idle behavior in separate modules.
- **Dependencies:** Phase 1 persistence, identity, authority, permissions.
- **Acceptance:** Values generated once and saved; authoritative trust/memory
  changes; behavior demonstrably uses them; clients receive consistent views;
  feature gates disable each module without disabling the bridge.
- **Testing:** Restart/reconnect, conflicting-player interactions, event dedupe,
  decay/cooldown, and module-disable tests.
- **Difficulty:** High.

## Phase 3: Community simulation

- **Purpose:** Add shared community priorities, guard/patrol/farmer/cook/doctor/
  hauler/cleaner/mechanic/scavenger jobs, routines, and settlement membership.
- **Dependencies:** Phase 2; stable schedules and resource authority.
- **Acceptance:** Jobs benefit shared state, avoid simultaneous activity herding,
  recover after interruptions, persist, and do not duplicate resources.
- **Testing:** Multi-NPC soak tests, resource accounting, player separation,
  restart/reconnect, and disabled-module recovery.
- **Difficulty:** Very high.

## Phase 4: World simulation

- **Purpose:** Add bounded off-screen communities and broader survivor activity.
- **Dependencies:** Phase 3 performance and persistence proven at scale.
- **Acceptance:** Deterministic transitions between abstract and active NPCs,
  bounded CPU/network/save growth, migration and recovery, no duplicate materialization.
- **Testing:** Long-duration soak, save-size/performance budgets, cell transitions,
  population reconciliation, and repeated upgrade/rollback cycles.
- **Difficulty:** Extreme.
