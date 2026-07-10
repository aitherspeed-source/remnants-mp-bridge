# Project Vision

## Purpose

Build a stable private hosted-multiplayer compatibility layer for Pat's NPC:
Project Remnants, then use that foundation to develop persistent survivors with
personalities, memories, player-specific trust, routines, jobs, communities,
and eventually broader world simulation.

The immediate product is not a large simulation. It is a small party of NPCs
whose identity and important state remain consistent for a host and one
Steam-invited friend across play, late join, reconnect, and hosted-world reload.

## Principles

- Server-authoritative permanent state; one valid executor for NPC actions.
- Project Remnants supplies local NPC/runtime capabilities, not multiplayer
  authority or canonical persistence.
- Network handlers transport validated requests and state; personality,
  memories, jobs, and behavior belong in separate modules.
- Compatibility and rollback safety take priority over clever architecture.
- Every feature is gated by a repeatable disposable-world test checkpoint.
- Living-world systems begin only after identity, duplicate prevention,
  ownership, late join, reconnect, and persistence are stable.

## Initial success condition

The host and invited player observe the same NPC identity, transform, animation,
health, death state, equipment, and accepted order through normal play,
reconnects, and a host restart, with no duplicate bodies, player slots, player
database corruption, or item duplication.

## Explicitly deferred

Possession, driving, ranged combat, full inventory UI, distant settlements, and
off-screen world simulation are not foundation work. Each requires a separate
decision, feature gate, and multiplayer checkpoint.
