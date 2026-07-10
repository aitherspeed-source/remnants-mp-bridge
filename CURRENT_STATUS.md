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
- Version 0.1.1's delayed cell-loading correction succeeded: the invited guest
  now sees the same shared test replica as the host.
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

Version 0.1.3 packaging correction is published. Each newly confirmed client gets
one bounded server-driven movement sequence so host and guest can observe the
same revisions together.

## Blocked

- Phase 1A cannot be accepted without a real Steam-invited guest test.
- Project Remnants source and full transformer details are not in the repository.

## Repository and releases

- Public repository: `https://github.com/aitherspeed-source/remnants-mp-bridge`
- Default branch: `main`
- Latest release: `v0.1.3`
- Git history is now available and must be inspected at session start.
- The release publishes a versioned ZIP and `latest.json`; the
  permanent updater verifies the manifest SHA-256 before installation.
- A local end-to-end updater run from installed 0.1.0 to public 0.1.1 passed.
- Twenty-two static tests pass for 0.1.3; two-player movement replay is the next
  runtime checkpoint.

## Next exact task

Publish/install 0.1.3, restart both clients, join and teleport together, then
confirm that guest creation schedules six shared transform revisions after a
three-second delay. Compare both views and logs. Do not add follow AI yet.

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
