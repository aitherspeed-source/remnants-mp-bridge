# Current Status

Last updated: 2026-07-10.

## Current milestone

Phase 1A: Shared inert replica lifecycle. The project is still a transport and
lifecycle spike; it is not yet a gameplay bridge.

## Completed with evidence

- Isolated Build 42 mod layout and Project Remnants dependency.
- Protocol/bridge/game/Project Remnants/replica API handshake fields.
- Server validation, directed replies, rate limit, bounded client retry.
- Independent client companion agent with no bytecode transformers.
- Local inert replica create, direct position update, inspection, persistence
  detachment, and cleanup APIs.
- Solo Host/listen-server handshake accepted on Build 42.19.0 revision 964.
- Solo visible server-issued body and creation acknowledgment.
- Solo scripted transform delivery through multiple revisions/squares.
- Shared session-only ID, accepted-client broadcast, explicit destroy handling,
  handshake reconciliation, presence tracking, and Phase 1 diagnostics are
  implemented but have not been run in-game.
- Nineteen static tests pass as of this update.
- Version 0.1.1 adds the delayed guest cell-loading correction and a checksum-
  verified GitHub Release updater. Twenty static tests pass.
- Current Lua source is deployed to the local root and versioned Build 42 mod
  folders; SHA-256 comparisons match. The previous deployment is preserved as
  `RemnantsMPBridge.codex-backup-20260710-155453-989`.
- A private friend ZIP with automatic Steam-library detection, one-click
  install/uninstall, backups, verification, checksums, Lua runtime, and the
  bridge companion is built under `dist`. It excludes Project Remnants and game
  files. Runtime installation on the friend's machine is untested.
- The friend installer now automatically invokes Project Remnants' own supplied
  installer when its Java prerequisite is missing. This integration is
  statically verified but still needs the friend-machine retry.
- Baseline, compatibility, rollback, design, test, and continuity documents exist.

## Currently being worked on

The first guest attempt failed after a successful handshake because the guest
replica API could not create at an unloaded host-area square. Delayed bounded
retries are implemented. Public repository and release publication are in
progress; runtime verification of the correction remains next.

## Blocked

- Phase 1A cannot be accepted without a real Steam-invited guest test.
- Git branch/history inspection is unavailable because this workspace currently
  has no `.git` metadata.
- Project Remnants source and full transformer details are not in the repository.

## Next exact task

Install the rebuilt bridge on both machines, restart the Host session, invite
the guest, teleport the guest to the host promptly, and verify that a delayed
retry changes `api-returned-false` to `created=true`. Do not add further systems
before recording that result.

## Files expected to be involved

- `src/42/media/lua/shared/RemnantsMPBridge/Protocol.lua`
- `src/42/media/lua/server/RemnantsMPBridge/BridgeServer.lua`
- `src/42/media/lua/client/RemnantsMPBridge/BridgeClient.lua`
- `tests/test_remnants_mp_bridge_static.py`
- `TESTING.md`, `docs/test-results.md`, and this file

## Next multiplayer test

Run Foundation F1-F4 in `NPCMPTest`: host creation, Steam-invited guest joining,
same-ID comparison, and ten-minute shared transform observation. Retain host
client, guest client, and listen-server logs plus screenshots and before/after
save/player-database hashes.

## Do not start yet

Persistent saves, AI ownership, commands, combat, inventory, vehicles,
personality, memories, trust, jobs, schedules, and settlements.
