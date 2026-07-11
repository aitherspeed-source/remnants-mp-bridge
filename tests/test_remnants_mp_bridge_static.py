from pathlib import Path
import unittest
import zipfile


ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src" / "42"


def read(path: str) -> str:
    return (SRC / path).read_text(encoding="utf-8")


def doc(path: str) -> str:
    return (ROOT / "docs" / path).read_text(encoding="utf-8")


class RemnantsMPBridgeStaticTests(unittest.TestCase):
    def test_mod_layout_exists(self):
        expected = [
            "mod.info",
            "media/lua/shared/RemnantsMPBridge/Protocol.lua",
            "media/lua/server/RemnantsMPBridge/BridgeServer.lua",
            "media/lua/client/RemnantsMPBridge/BridgeClient.lua",
        ]
        for rel in expected:
            self.assertTrue((SRC / rel).exists(), rel)

    def test_metadata_is_isolated_and_requires_project_remnants(self):
        metadata = read("mod.info")
        self.assertIn("id=RemnantsMPBridge", metadata)
        self.assertIn("require=ProjectRemnants", metadata)
        self.assertIn("version=0.1.4", metadata)
        self.assertIn("versionMin=42.19.0", metadata)

    def test_protocol_is_versioned_and_pinned(self):
        protocol = read("media/lua/shared/RemnantsMPBridge/Protocol.lua")
        self.assertIn('Protocol.MODULE = "RemnantsMPBridge"', protocol)
        self.assertIn("Protocol.PROTOCOL_VERSION = 1", protocol)
        self.assertIn('Protocol.TARGET_GAME_VERSION = "42.19.0"', protocol)
        self.assertIn('Protocol.REPLICA_API_VERSION = "1"', protocol)
        self.assertIn("Protocol.baseGameVersion", protocol)
        self.assertIn('string.match(raw, "^(%d+%.%d+%.%d+)")', protocol)
        self.assertIn("Protocol.validateHello", protocol)

    def test_replication_fails_closed_without_java_api(self):
        protocol = read("media/lua/shared/RemnantsMPBridge/Protocol.lua")
        self.assertIn('replicaApiVersion = "missing"', protocol)
        self.assertIn("npcfwReplicaApiVersion", protocol)
        self.assertIn("npcfwReplicaIsReady", protocol)
        self.assertIn('return false, "project-remnants-agent-not-ready"', protocol)
        self.assertIn('return false, "replica-api-missing-or-mismatched"', protocol)
        self.assertIn('return false, "replica-api-not-ready"', protocol)

    def test_server_owns_handshake_validation(self):
        server = read("media/lua/server/RemnantsMPBridge/BridgeServer.lua")
        self.assertIn("Events.OnClientCommand.Add", server)
        self.assertIn("Protocol.validateHello(args)", server)
        self.assertIn("sendServerCommand(playerObj", server)
        self.assertIn("HELLO_RATE_LIMIT_MS", server)
        self.assertNotIn("npcfwSpawn", server)

    def test_first_replica_is_server_issued_inert_and_session_only(self):
        protocol = read("media/lua/shared/RemnantsMPBridge/Protocol.lua")
        server = read("media/lua/server/RemnantsMPBridge/BridgeServer.lua")
        client = read("media/lua/client/RemnantsMPBridge/BridgeClient.lua")
        self.assertIn('REPLICA_CREATE = "replicaCreate"', protocol)
        self.assertIn('REPLICA_UPDATE = "replicaUpdate"', protocol)
        self.assertIn('REPLICA_RESULT = "replicaResult"', protocol)
        self.assertIn("validateReplicaSnapshot", protocol)
        self.assertIn('displayName = "Bridge Test Replica"', server)
        self.assertIn("getRandomAdjacentFreeSameRoom", server)
        self.assertIn("square:isFree(false)", server)
        self.assertIn("Server.replicas", server)
        self.assertIn("Server.ensureTestReplica(playerObj)", server)
        self.assertIn("Server.MAX_REPLICA_DELIVERIES = 20", server)
        self.assertNotIn("ModData", server)
        self.assertIn("npcfwReplicaCreate", client)
        self.assertIn("npcfwReplicaSetPosition", client)
        self.assertIn("Client.sendReplicaResult", client)
        self.assertIn("Client.replicaRevisions", client)
        self.assertNotIn("npcfwSpawn", client)

    def test_transform_checkpoint_is_bounded_and_server_authoritative(self):
        server = read("media/lua/server/RemnantsMPBridge/BridgeServer.lua")
        client = read("media/lua/client/RemnantsMPBridge/BridgeClient.lua")
        self.assertIn("Server.MOVEMENT_INITIAL_DELAY_MS = 10000", server)
        self.assertIn("Server.MOVEMENT_INTERVAL_MS = 3000", server)
        self.assertIn("Server.MOVEMENT_UPDATE_COUNT = 6", server)
        self.assertIn("reachableReplicaPath", server)
        self.assertIn("replica.revision = replica.revision + 1", server)
        self.assertIn("Protocol.Commands.REPLICA_UPDATE", server)
        self.assertIn("Events.OnTick.Add(Server.onTick)", server)
        self.assertIn("incomingRevision <= lastRevision", client)
        self.assertIn('"stale-ignored"', client)

    def test_shared_replica_is_broadcast_and_late_join_reconciles(self):
        protocol = read("media/lua/shared/RemnantsMPBridge/Protocol.lua")
        server = read("media/lua/server/RemnantsMPBridge/BridgeServer.lua")
        client = read("media/lua/client/RemnantsMPBridge/BridgeClient.lua")
        self.assertIn('REPLICA_DESTROY = "replicaDestroy"', protocol)
        self.assertIn('Server.SHARED_TEST_REPLICA_ID = "bridge-test-shared-001"', server)
        self.assertNotIn('testReplicaId(key)', server)
        self.assertIn("acceptedOnlinePlayers", server)
        self.assertIn("Server.broadcastReplica", server)
        self.assertIn("Server.sendReplica(playerObj, replica)", server)
        self.assertIn("Server.broadcastReplica(replica, Protocol.Commands.REPLICA_UPDATE)", server)
        self.assertIn("Server.destroyReplica", server)
        self.assertIn("Client.onReplicaDestroy", client)
        self.assertIn('Client.clearReplicas("accepted-handshake-reconcile")', client)

    def test_failed_guest_create_retries_are_delayed_for_cell_loading(self):
        server = read("media/lua/server/RemnantsMPBridge/BridgeServer.lua")
        self.assertIn("Server.MAX_REPLICA_DELIVERIES = 20", server)
        self.assertIn("Server.REPLICA_RETRY_INTERVAL_MS = 3000", server)
        self.assertIn("replica.retryAtByPlayer[key] = nowMs() + Server.REPLICA_RETRY_INTERVAL_MS", server)
        self.assertIn("replica.deliveryCommands[key] = command", server)
        self.assertIn("if retryAt and now >= retryAt then", server)
        self.assertIn("replica delivery exhausted", server)
        self.assertNotIn("Server.sendReplica(playerObj, replica, replica.lastCommand)", server)

    def test_newly_confirmed_guest_replays_bounded_movement(self):
        server = read("media/lua/server/RemnantsMPBridge/BridgeServer.lua")
        self.assertIn("Server.MOVEMENT_JOIN_DELAY_MS = 3000", server)
        self.assertIn("replica.movementScheduledClients", server)
        self.assertIn("if replica.movementScheduledClients[key] then return end", server)
        self.assertIn("or Server.MOVEMENT_JOIN_DELAY_MS", server)
        self.assertIn('.. " confirmedClient=" .. key', server)

    def test_live_reconnect_reconciles_and_replays_movement(self):
        server = read("media/lua/server/RemnantsMPBridge/BridgeServer.lua")
        self.assertIn("local reconnecting = existing ~= nil and existing.present == false", server)
        self.assertIn("if reconnecting then", server)
        self.assertIn("replica.movementScheduledClients[key] = nil", server)
        self.assertIn("replica.reconnectCount = (replica.reconnectCount or 0) + 1", server)
        self.assertIn('Protocol.debug("reconnect snapshot player="', server)
        self.assertIn("Server.ensureTestReplica(playerObj)", server)
        self.assertIn("reconnectCount = Server.replicas", server)

    def test_phase_one_diagnostics_are_debug_gated(self):
        protocol = read("media/lua/shared/RemnantsMPBridge/Protocol.lua")
        server = read("media/lua/server/RemnantsMPBridge/BridgeServer.lua")
        client = read("media/lua/client/RemnantsMPBridge/BridgeClient.lua")
        self.assertIn("Protocol.DEBUG", protocol)
        self.assertIn("function Protocol.debug", protocol)
        self.assertIn("Server.packetCounts", server)
        self.assertIn("Server.invalidReplicaLookups", server)
        self.assertIn("Server.diagnosticSnapshot", server)
        self.assertIn("spawnSource", server)
        self.assertIn("Client.packetCounts", client)
        self.assertIn("Client.invalidReplicaLookups", client)
        self.assertIn("Client.duplicateCreates", client)
        self.assertIn("replicaRevisions = Client.replicaRevisions", client)

    def test_client_retries_bounded_and_exposes_diagnostics(self):
        client = read("media/lua/client/RemnantsMPBridge/BridgeClient.lua")
        self.assertIn("Client.MAX_ATTEMPTS = 6", client)
        self.assertIn("Client.RETRY_INTERVAL_MS = 3000", client)
        self.assertIn("sendClientCommand", client)
        self.assertIn("Events.OnServerCommand.Add", client)
        self.assertIn("Client.diagnosticSnapshot", client)
        self.assertNotIn("npcfwSpawn", client)

    def test_no_vanilla_or_workshop_payload_is_copied(self):
        all_files = [p for p in ROOT.rglob("*") if p.is_file()]
        jars = [p.name for p in all_files if p.suffix.lower() == ".jar"]
        self.assertEqual(jars, ["RemnantsMPBridgeAgent.jar"])
        self.assertFalse(any(p.name in {"NPCFW.jar", "projectzomboid.jar"} for p in all_files))
        self.assertFalse(any(p.suffix.lower() == ".class" and "remnantsmpbridge" not in p.parts for p in all_files))
        self.assertFalse(any("ProjectRemnants" in p.parts for p in all_files))

    def test_java_companion_uses_public_replica_lifecycle(self):
        source = (ROOT / "java/src/main/java/remnantsmpbridge/ReplicaAgent.java").read_text(encoding="utf-8")
        self.assertIn("NPCManager.getInstance()", source)
        self.assertIn("manager.spawn(", source)
        self.assertIn("npc.setBehaviorTree(null)", source)
        self.assertIn("manager.detachFromPersistence", source)
        self.assertIn("manager.reattachRuntimeNPC", source)
        self.assertIn("manager.despawn(bridgeId)", source)
        self.assertIn("MAX_REPLICAS = 16", source)
        self.assertIn("forgetAllForEnvironmentChange", source)
        self.assertIn("npcfwReplicaDescribe", source)
        self.assertIn("setHaloNote", source)
        self.assertIn("setAlphaAndTarget(1.0f)", source)
        self.assertNotIn("ClassFileTransformer", source)
        self.assertNotIn("setAccessible", source)

    def test_built_agent_does_not_bundle_dependencies(self):
        agent = ROOT / "java/build/RemnantsMPBridgeAgent.jar"
        self.assertTrue(agent.exists())
        with zipfile.ZipFile(agent) as archive:
            names = archive.namelist()
        self.assertTrue(any(name.startswith("remnantsmpbridge/") for name in names))
        self.assertFalse(any(name.startswith(("npcfw/", "zombie/", "se/krka/")) for name in names))

    def test_installer_is_reversible_and_client_only(self):
        installer = (ROOT / "tools/install_companion.ps1").read_text(encoding="utf-8")
        self.assertIn("ProjectZomboid64.json", installer)
        self.assertIn("RemnantsMPBridgeBackup", installer)
        self.assertIn("Project Remnants Java agent is not installed", installer)
        self.assertIn("Is-BridgeClassPath", installer)
        self.assertIn("Is-BridgeAgentArg", installer)
        self.assertIn("$Mode -eq 'Install'", installer)
        self.assertIn("Remove-Item -LiteralPath $targetAgent", installer)
        self.assertNotIn("ProjectZomboidServer.bat'", installer)

    def test_local_deployer_includes_build42_versioned_layout(self):
        deployer = (ROOT / "tools/deploy_local_mod.ps1").read_text(encoding="utf-8")
        self.assertIn("$versionedDestination = Join-Path $destination '42'", deployer)
        self.assertIn("42 versioned copy is required", deployer)
        self.assertIn("BridgeServer.lua", deployer)
        self.assertIn("Deployment verification failed", deployer)

    def test_private_bundle_is_one_click_and_does_not_bundle_remnants(self):
        installer = (ROOT / "tools/friend_bundle/tools/friend_install.ps1").read_text(encoding="utf-8")
        packager = (ROOT / "tools/package_private_bundle.ps1").read_text(encoding="utf-8")
        readme = (ROOT / "tools/friend_bundle/README.txt").read_text(encoding="utf-8")
        self.assertIn("Get-SteamLibraries", installer)
        self.assertIn("libraryfolders.vdf", installer)
        self.assertIn("ProjectZomboid64.json", installer)
        self.assertIn("install_project_remnants.ps1", installer)
        self.assertIn("-ProjectZomboidPath $gameHome -NoPause", installer)
        self.assertIn("Project Remnants supplied installer failed", installer)
        self.assertIn("RemnantsMPBridgeBackup", installer)
        self.assertIn("Move-Item -LiteralPath $modDestination", installer)
        self.assertIn("Compress-Archive", packager)
        self.assertIn("CHECKSUMS.sha256", packager)
        self.assertIn("runs Project Remnants' own supplied installer", readme)
        self.assertNotIn("NPCFW.jar' -Destination", packager)

    def test_private_bundle_zip_contains_only_bridge_runtime(self):
        bundle = ROOT / "dist/RemnantsMPBridge-0.1.4.zip"
        self.assertTrue(bundle.exists())
        with zipfile.ZipFile(bundle) as archive:
            names = archive.namelist()
        self.assertTrue(any(name.endswith("Install Remnants MP Bridge.bat") for name in names))
        self.assertTrue(any(name.endswith("RemnantsMPBridgeAgent.jar") for name in names))
        self.assertTrue(any(name.endswith("CHECKSUMS.sha256") for name in names))
        self.assertFalse(any(name.endswith(("NPCFW.jar", "projectzomboid.jar")) for name in names))

    def test_release_runtime_text_is_lf_and_matches_source(self):
        bundle = ROOT / "dist/RemnantsMPBridge-0.1.4.zip"
        with zipfile.ZipFile(bundle) as archive:
            protocol_name = next(
                name for name in archive.namelist()
                if name.endswith("payload/RemnantsMPBridge/42/media/lua/shared/RemnantsMPBridge/Protocol.lua")
            )
            released = archive.read(protocol_name)
        source = (SRC / "media/lua/shared/RemnantsMPBridge/Protocol.lua").read_bytes()
        self.assertNotIn(b"\r\n", released)
        self.assertEqual(released, source)

    def test_public_release_updater_is_checksum_verified(self):
        updater = (ROOT / "tools/friend_bundle/tools/update_bridge.ps1").read_text(encoding="utf-8")
        workflow = (ROOT / ".github/workflows/release.yml").read_text(encoding="utf-8")
        self.assertIn("aitherspeed-source/remnants-mp-bridge", updater)
        self.assertIn("releases/latest/download/latest.json", updater)
        self.assertIn("Get-FileHash -Algorithm SHA256", updater)
        self.assertIn("Checksum mismatch", updater)
        self.assertIn("friend_install.ps1", updater)
        self.assertIn('tags:', workflow)
        self.assertIn("gh release create", workflow)
        self.assertIn("latest.json", workflow)

    def test_docs_pin_disposable_profile_and_compatibility_process(self):
        design = doc("design.md")
        rollback = doc("rollback.md")
        compatibility = doc("compatibility.md")
        checklist = doc("test-checklist.md")
        baseline = doc("baseline.md")
        self.assertIn("NPCMPTest", design)
        self.assertIn("does not alter", rollback)
        self.assertIn("Audit-required categories", compatibility)
        self.assertIn("bisect", compatibility)
        self.assertIn("Expected current result", checklist)
        self.assertIn("Do not use `servertest`", checklist)
        self.assertIn("F199B1AEE1463CC45D416B6F3FF322E71A182F9A4F2D8299BC44122C12D47719", baseline)
        self.assertIn("SVNRevision.txt`: `964`", baseline)


if __name__ == "__main__":
    unittest.main()
