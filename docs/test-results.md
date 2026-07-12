# Test Results

## 2026-07-12 — Three-cycle solo host reload

Result: PASS for session cleanup/recreation and duplicate prevention.

- The same disposable hosted world was loaded three times.
- Exactly one bridge replica appeared in every cycle and moved each session.
- No duplicate body or second canonical registration was observed.
- Recorded adjacent spawn squares varied (`12025.5,6915.5` and
  `12025.5,6914.5`), so placement is not a fixed exact square; it follows the
  reachable-adjacent selection design.
- Project Remnants reported `Saved 0 NPCs`, consistent with persistence
  detachment.
- The visible Lua error was vanilla `Lua(Vanilla).handleMannequinZone` for
  Muldraugh coordinates `13583,1299,0`; no bridge Lua stack trace occurred.
- Java reported forgetting one stale replica reference during Lua environment
  replacement. No body survived into the next session, but explicit cleanup
  ordering remains a technical risk to investigate later.

## 2026-07-10 — Public v0.1.4 reconnect checkpoint release

Result: publication PASS; live reconnect pending.

- Release asset: `RemnantsMPBridge-0.1.4.zip`, 32,976 bytes.
- SHA-256:
  `97C0AF8BB41B524A0D6CC3ED3867DC3F387CF9300D150652FC77618E6A11D19E`.
- Public latest manifest reports 0.1.4 and the correct asset URL.
- Twenty-three static tests pass.

## 2026-07-10 — Two-player synchronized movement

Result: PASS.

- Host `IntellectualNobo` and guest `Unofficial.Insomniac` both created
  `bridge-test-shared-001`.
- Guest confirmation scheduled the three-second delayed movement replay.
- Server broadcast revisions 8, 9, 10, 11, 12, and 13 to two recipients.
- Both host and guest returned `created=true detail=updated` for every revision.
- Both players visually observed the same three-second teleport movement.
- Sequence completed at canonical revision 13.
- Server later detected the guest offline; reconnect/duplicate behavior remains
  the next checkpoint.

## 2026-07-10 — v0.1.2 multiplayer file mismatch diagnosis

Result: FAIL, root cause confirmed.

- Both host and guest reported version 0.1.2 and both games had been closed.
- Installed host `Protocol.lua` SHA-256 was
  `8BC3A7A56FEEBABFC08CC708EAA829BFB33656E9BDFCBBDB850AF21A76BCEE7E`.
- GitHub release `Protocol.lua` SHA-256 was
  `69B33D646CD6869404590C978949EE61F12C632EC78B87F88D06137C6CC469D2`.
- After normalizing CRLF to LF, contents were identical. Project Zomboid had
  compared the byte-different files.
- Version 0.1.3 normalizes packaged runtime text and adds an exact-byte test.

## 2026-07-10 — Public v0.1.3 deterministic-package verification

Result: PASS; multiplayer reconnect pending.

- Release asset: `RemnantsMPBridge-0.1.3.zip`, 32,727 bytes.
- Release SHA-256:
  `9EE4AC499CE39AF35B8A12AAD8AF750B6EA3CFBA4696858E0B639609AAFD4814`.
- Public manifest and downloaded ZIP hashes match.
- Released versioned `Protocol.lua` and the host's deployed `Protocol.lua` have
  the exact same SHA-256:
  `C5EFDFDA1EBA4FBD7819F9545104388DE5E5DC7A97D8B70A39EE0BA9394F30EA`.
- Twenty-two static tests pass, including exact release/source byte equality.

## 2026-07-10 — Guest visibility retest

Result: PASS for shared body visibility.

- Host and Steam-invited guest loaded into `NPCMPTest`.
- Guest was teleported to the host.
- After the delayed cell-loading retry correction, the guest could see the same
  shared test replica as the host.
- Movement parity was not observed because the original movement sequence ended
  before guest loading completed.
- Version 0.1.2 therefore schedules a new bounded sequence once each new client
  confirms successful creation; runtime movement parity remains pending.

## 2026-07-10 — Public v0.1.2 release verification

Result: publication/download integrity PASS; movement runtime pending.

- Release workflow completed successfully using `actions/checkout@v5`.
- Public asset: `RemnantsMPBridge-0.1.2.zip`, 32,873 bytes.
- Published SHA-256:
  `B2E5096E77ECD4044F491592770BDD403EFFCF51AD966614B4A8B6875A2C3107`.
- Public `latest.json` reports version 0.1.2 and the correct tag asset URL.
- A fresh download matched the manifest checksum.
- Twenty-one static tests pass.

## 2026-07-10 — Version 0.1.1 release candidate

Result: static/package PASS; GitHub publication and runtime retest pending.

- Bundle: `RemnantsMPBridge-0.1.1.zip`
- Size: 32,536 bytes (31.77 KiB).
- SHA-256: `FC0C7AF45EF462C17F9AF959840132583609781869474248C0B78BCC029A051D`.
- Includes `Update Remnants MP Bridge.bat`, which reads the latest release
  manifest, downloads the named asset, verifies SHA-256, installs, and checks
  the resulting `mod.info` version.
- Twenty static tests pass.

## 2026-07-10 — Public v0.1.1 release verification

Result: PASS for publication/download integrity; guest runtime retest pending.

- Repository: `https://github.com/aitherspeed-source/remnants-mp-bridge`
- Release: `https://github.com/aitherspeed-source/remnants-mp-bridge/releases/tag/v0.1.1`
- GitHub Actions release workflow completed successfully.
- Public manifest reports version `0.1.1` and the tag-specific asset URL.
- Downloaded release size: 32,717 bytes.
- Published SHA-256:
  `DE1AE13265DC14E1C8BF13DEBA1094CAA9CF7CD3F9A385BFB2D86365859CCB99`.
- Downloaded asset hash matched the manifest.
- End-to-end updater test passed locally: it detected installed `0.1.0`,
  downloaded public `0.1.1`, verified the checksum, installed both root and
  versioned mod layouts plus the companion, backed up launch JSON, and verified
  installed `mod.info` version `0.1.1`.

## 2026-07-10 — First real guest shared-replica attempt

Result: FAIL, diagnosed.

- Host `IntellectualNobo` passed the handshake, created
  `bridge-test-shared-001`, and applied revisions 1-7 successfully.
- Guest `Unofficial.Insomniac` passed the same protocol/API handshake.
- Listen server sent shared ID revision 7 to the guest.
- Guest returned `created=false detail=api-returned-false` three times.
- All three retries occurred within roughly 0.2 seconds while the guest's client
  had not loaded the NPC's host-area square. Teleport happened after retries had
  already been exhausted, so no later snapshot was sent.
- Corrective patch spaces attempts three seconds apart and permits twenty
  bounded deliveries (about one minute) so cell loading/teleport can complete.
- This correction is statically verified only; the guest retest is pending.
- Corrected private ZIP: 31,153 bytes (30.42 KiB), SHA-256
  `E353C7D8E444CEF42E2CF9C4ECBFD531C84DA7DEA1033699E02225DAAF5BD22C`.
- Nineteen static tests pass and the corrected Lua was deployed locally with a
  backup of the previous deployment.

## 2026-07-10 — Private friend bundle static checkpoint

Result: PASS for packaging/static verification; friend-machine runtime untested.

- Bundle: `RemnantsMPBridge-0.1.0-private-test.zip`
- Superseded by the automatic-prerequisite rebuild below.
- All 13 manifest-listed files verified against their embedded SHA-256 values.
- ZIP inspection found no `NPCFW.jar` or `projectzomboid.jar`.
- Eighteen static tests pass.
- Required runtime evidence: install and uninstall on the friend machine, then
  the disposable Host/Steam-invite checkpoint.

## 2026-07-10 — Automatic Project Remnants prerequisite rebuild

Result: packaging and manifest PASS; friend-machine runtime untested.

- If NPCFW launch entries are absent, the friend installer locates and invokes
  Workshop `root/install_project_remnants.ps1` with the detected game path and
  `-NoPause`, checks its exit code, reloads launch JSON, and verifies both NPCFW
  entries before continuing.
- The Project Remnants installer itself remains in the Workshop payload; it is
  not copied into this ZIP.
- Rebuilt ZIP size: 30,758 bytes (30.04 KiB).
- Rebuilt ZIP SHA-256:
  `A37F0EAAA3C441E19B0734AE3358D07C390DDAD011895B32A33398A288E92346`.

## 2026-07-10 — Shared lifecycle static checkpoint

Result: PASS for static verification; runtime untested.

- Sixteen Python static tests pass.
- The server now owns one session-only ID, `bridge-test-shared-001`.
- Create/current-state delivery is directed to each accepted joiner; movement is
  broadcast to all accepted online clients.
- Explicit destroy, handshake reconciliation, presence tracking, and diagnostic
  counters are present.
- No game files or saves were changed by this checkpoint.
- The Lua mod was deployed to `C:\Users\gauge\Zomboid\mods\RemnantsMPBridge`;
  the deploy tool backed up the previous copy and all three deployed Lua file
  hashes match repository source.
- Required next evidence: solo Host smoke test followed by Steam guest F1-F4.

## 2026-07-10 — Solo listen-server handshake

Environment:

- Game: Build `42.19.0`, revision `964`, commit `1aa820d7bb66c4e55513cae04022bdacdac5b34e`.
- Host profile/save: disposable `NPCMPTest`.
- Mods: `ProjectRemnants;RemnantsMPBridge`.
- Project Remnants Workshop item: `3738362476`.
- Bridge protocol: `1`.
- Companion API: `1`, eight Lua functions exposed.

Result: PASS.

- Client loaded `RemnantsMPBridge` and sent the handshake.
- Listen server loaded `RemnantsMPBridge` and accepted the host player:
  `accepted=true reason=ready`.
- Client received `handshake accepted`.
- Client and server reported the same full game build string.
- No bridge replica was created during the handshake phase.
- Project Remnants independently restored one local NPC from
  `NPCMPTest_player/NPCFW_Data.bin`.
- The only Lua error observed was the unrelated vanilla Muldraugh mannequin-zone warning.

Corrections discovered during the checkpoint:

1. Build 42's listen-server loader required the local mod under a versioned
   `42` folder in addition to root metadata.
2. `getCore():getVersion()` includes commit/date metadata, so protocol validation
   now compares the leading three-part version and logs the complete raw value.

Guest-client visibility and synchronization remain untested.

## 2026-07-10 — First visible server-issued inert replica

Result: PASS for the solo host/client lifecycle checkpoint.

- Listen server registered `bridge-test-IntellectualNobo`, revision `1`.
- Server delivered the canonical create snapshot once.
- Client created the body through companion API version 1 and acknowledged
  `created=true detail=created`.
- Client diagnostics reported position `12025.5,6916.5,0`, current square
  `12025,6916,0`, `inWorld=true`, `alpha=1.0`, and `targetAlpha=1.0`.
- Screenshot confirmed the named human body was visible on a reachable adjacent
  square and was absent from Project Remnants' party portrait registry.
- No bridge errors were logged.
- The replica was detached from Project Remnants persistence before the server
  received the success acknowledgment.

The Project Remnants save in this disposable multiplayer player directory was
only 14 bytes after the run, and its earlier Annette companion was no longer in
the party UI. Earlier logs showed Project Remnants detaching an NPC during
`primary player death failover`. Treat this as evidence that unmodified Project
Remnants persistence is not multiplayer-safe; do not use this test world as
evidence that Pat's local NPC save survives multiplayer player lifecycle events.

Remaining Phase 1 checks: controlled transform updates, cleanup on exit/rejoin,
and visibility from a real guest client.
