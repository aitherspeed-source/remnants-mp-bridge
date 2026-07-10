# Disposable Multiplayer Handshake Test

Use a new Host profile named `NPCMPTest` and a new disposable world. Do not use `servertest`.

## Setup

- Confirm both computers run Project Zomboid `42.19.0`.
- Confirm both have the same Project Remnants Workshop payload.
- Run `tools/deploy_local_mod.ps1` on both computers. It deploys root metadata
  plus the versioned `42` copy required by the Build 42 listen-server loader.
- Enable `ProjectRemnants;RemnantsMPBridge` in `NPCMPTest`.
- For the pre-install checkpoint, do not patch any Java extension.

## Expected current result

1. Start the host and join the disposable world.
2. Invite the friend and have them join.
3. Both clients should display a blocked message rather than spawn an NPC.
4. The reason should be `project-remnants-agent-not-ready` when the existing Java agent is not installed, or `replica-api-missing-or-mismatched` when Project Remnants is ready but the future replica extension is absent.
5. The listen-server log should contain one handshake record per player with their accepted status and reason.
6. No `NPCFW_Data.bin`, bridge save, player database row, NPC, or item should be created by the bridge.

After the companion installer and rollback path are ready, repeat in a second disposable world. The expected result then changes to `Remnants MP Bridge ready`, while the bridge must still spawn no NPC until the inert-replica command phase is explicitly enabled.

## Shared inert replica checkpoint

With the companion and current bridge installed:

1. Host enters `NPCMPTest` and confirms exactly one
   `bridge-test-shared-001` body.
2. Wait for the six movement revisions and retain the client/listen-server logs.
3. Invite the friend. The guest must receive the same ID and current revision,
   while the host must not create a second body.
4. Observe both views for ten minutes. Compare reported positions and revisions.
5. Have the guest disconnect and reconnect; confirm exactly one guest body and
   the same canonical ID.
6. Exit to the menu and confirm pre-map-load cleanup reports one removed body.

Any guest result remains unconfirmed until both client logs and the listen-server
log show the same ID and revisions.

## Failure checks

- No Lua stack traces from `RemnantsMPBridge`.
- No `required mod "RemnantsMPBridge" not found` warning in `coop-console.txt`.
- No repeated halo messages after a definitive blocked response.
- No more than one handshake per second from a client.
- Unknown bridge commands receive a rejection and make no state change.
- Disabling the bridge allows the disposable world to reload.

Retain both client logs, the listen-server log, enabled mod lists, and exact jar hashes with the test result.
