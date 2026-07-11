# Changelog

This log records repository changes, not unverified runtime claims.

## 0.1.4 — Reconnect reconciliation checkpoint

- Detect a live-session reconnect after server presence marked a client offline.
- Re-send the existing canonical replica snapshot instead of creating a new
  server record.
- After the reconnecting client confirms its body, replay the bounded movement
  sequence for both players as a visible authoritative-correction test.
- Track reconnect count in server diagnostics.

## 0.1.3 — Deterministic multiplayer file packaging

- Fixed the client/server mismatch caused by GitHub's Windows runner converting
  release Lua files to CRLF while local server files used LF.
- Normalize packaged Lua and `mod.info` files to UTF-8 without BOM and LF.
- Added Git attributes and an exact-byte release regression test.
- Runtime checkpoint passed: host and guest observed the shared six-revision
  movement sequence, and the server received matching acknowledgements.

## 0.1.2 — Joined-client movement replay

- Recorded successful host/guest visibility of the shared replica.
- Schedule one six-update movement sequence for each newly confirmed client.
- Use the original ten-second delay for the host and a three-second delay after
  a late-joining guest successfully creates its body.
- Prevent acknowledgements from repeatedly restarting the test for one client.

## 0.1.1 — Public updater and guest retry correction

- Added the delayed bounded guest replica-create retry.
- Added a permanent checksum-verified GitHub Release updater.
- Added public repository README, release workflow, and repository hygiene.
- Made bundle names derive from `mod.info` version.
- Expanded the static suite to 20 passing tests.
- Published the public repository and GitHub Release `v0.1.1`.
- Verified the public `latest.json` endpoint and downloaded asset checksum.

## 2026-07-10 — Guest streamed-cell retry correction

- Recorded the first guest attempt: handshake and shared snapshot succeeded,
  but local creation failed because the host-area square was not loaded.
- Replaced three immediate retries with up to twenty deliveries spaced three
  seconds apart.
- Preserved the per-player delivery command so delayed retries use the correct
  create/update packet.
- Added a regression test for bounded delayed cell-loading retries.

## 2026-07-10 — Private friend installer bundle

- Added a double-click Windows installer and uninstaller.
- Added automatic Steam library and Project Zomboid discovery.
- Added checks for the Project Remnants Workshop payload and Java launch entries.
- When those Java entries are missing, the bundle now runs Project Remnants'
  own Workshop-supplied installer automatically, then verifies its result before
  installing the bridge.
- Added backups for the local mod and `ProjectZomboid64.json` plus install checks.
- Added a reproducible private ZIP packager and SHA-256 manifest.
- Verified the ZIP contains no `NPCFW.jar` or Project Zomboid jar.
- Expanded the static suite from 16 to 18 passing tests.

## 2026-07-10 — Shared inert replica topology

- Replaced username-derived test IDs with `bridge-test-shared-001`.
- Added broadcast updates to all accepted online clients and late-join delivery
  of the current canonical snapshot.
- Added explicit `replicaDestroy` client/server lifecycle handling.
- Added accepted-handshake cleanup/reconciliation and server presence tracking.
- Added debug-gated packet, duplicate, invalid-lookup, revision, and spawn-source
  diagnostics.
- Expanded the static suite from 14 to 16 passing tests.
- Deployed the verified Lua build locally with an automatic backup of the prior
  deployment; source/deployment hashes match.
- Runtime host and guest verification remains pending.

## 2026-07-10 — Project continuity baseline

- Added the long-term operating manual and continuity documents.
- Recorded the repository audit, actual packet/ownership model, system status,
  risks, accepted decisions, phased roadmap, and repeatable multiplayer tests.
- Established Phase 1A shared inert replica lifecycle as the active milestone.
- No gameplay, networking, Java, save, installation, or packaging code changed.

## Existing implementation summarized from repository evidence

- Added isolated `RemnantsMPBridge` Build 42 layout and dependency metadata.
- Added protocol 1 handshake and replica snapshot validation.
- Added server session registry, directed inert create/update test, rate limiting,
  bounded delivery, and scripted transform sequence.
- Added client handshake retry, replica application, revision filtering,
  acknowledgements, diagnostics, and map-load cleanup.
- Added independent replica API version 1 Java agent and reversible tools.
- Recorded successful solo hosted handshake, visible replica, and transform
  transport checkpoints; guest multiplayer remains unverified.
