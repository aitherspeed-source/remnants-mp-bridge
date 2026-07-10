# Remnants MP Bridge Operating Manual

These instructions apply to every file under this directory. The workspace-level
`AGENTS.md` also applies; where both are relevant, follow the more restrictive
instruction.

## Required session startup

Before proposing or changing implementation code, every Codex session must:

1. Read `CURRENT_STATUS.md` first.
2. Read `ROADMAP.md` and identify the active milestone and its acceptance gate.
3. Read `DECISIONS.md`; do not reopen accepted decisions without new evidence.
4. Read `docs/design.md`, then the relevant source, tests, and test evidence.
5. Inspect the current Git branch, working tree, and recent history. If `.git`
   is unavailable, record that limitation explicitly and do not invent history.
6. Preserve unrelated and user-authored changes. Keep work scoped to this mod.
7. Distinguish code presence, static verification, solo runtime evidence, and
   two-player multiplayer confirmation. Only the last may be called confirmed
   multiplayer behavior.

## Development rules

- Continue the current milestone; do not restart the bridge from scratch.
- Prefer small, reversible patches over broad rewrites.
- Preserve a working system unless evidence shows that it is unsafe,
  incompatible with persistence/late join, duplicating NPCs, permitting
  conflicting authority, or causing a measured performance problem.
- The listen server owns canonical multiplayer state. Client `IsoNPC` instances
  are visual/runtime replicas unless a later recorded decision changes this.
- Never allow more than one AI executor for a canonical NPC.
- Never treat Project Remnants' local `NPCFW_Data.bin` as the bridge's canonical
  multiplayer save.
- Never edit or redistribute the subscribed Project Remnants payload.
- Do not install, publish, package, or upload without explicit user direction.
- Use only the disposable `NPCMPTest` hosted-world profile for development.
- Revalidate against local game files after Build 42 or Project Remnants updates.

## Required completion work

Before ending any implementation or testing session:

1. Run verification proportional to the change.
2. Update `CURRENT_STATUS.md` with completed work, active work, blockers, exact
   next task, affected files, and the next multiplayer test.
3. Update `ROADMAP.md` when milestone scope or acceptance state changed.
4. Append material architectural choices to `DECISIONS.md`.
5. Append user-visible or architectural changes to `CHANGELOG.md`.
6. Update `TESTING.md` and `docs/test-results.md` with actual test evidence.
7. Keep `AUDIT.md` accurate when ownership, packets, persistence, or known risks
   change.

Documentation is part of the deliverable, not optional cleanup.
