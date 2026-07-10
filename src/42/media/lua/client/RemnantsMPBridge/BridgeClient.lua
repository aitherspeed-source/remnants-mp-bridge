require "RemnantsMPBridge/Protocol"

RemnantsMPBridge.Client = RemnantsMPBridge.Client or {}
local Client = RemnantsMPBridge.Client
local Protocol = RemnantsMPBridge.Protocol

Client.status = Client.status or "not-started"
Client.reason = Client.reason or "none"
Client.attempts = Client.attempts or 0
Client.lastHelloAt = Client.lastHelloAt or 0
Client.replicaRevisions = Client.replicaRevisions or {}
Client.packetCounts = Client.packetCounts or { sent = {}, received = {} }
Client.invalidReplicaLookups = Client.invalidReplicaLookups or 0
Client.duplicateCreates = Client.duplicateCreates or 0
Client.MAX_ATTEMPTS = 6
Client.RETRY_INTERVAL_MS = 3000

local function nowMs()
    if getTimestampMs then return getTimestampMs() end
    return 0
end

local function countPacket(direction, command)
    local counts = Client.packetCounts[direction]
    counts[command] = (counts[command] or 0) + 1
end

function Client.clearReplicas(reason)
    local removed = 0
    if npcfwReplicaClearAll then
        local ok, result = pcall(npcfwReplicaClearAll)
        if ok then
            removed = tonumber(result) or 0
        else
            print("[RemnantsMPBridge] replica cleanup failed: " .. tostring(reason))
        end
    end
    Client.replicaRevisions = {}
    Protocol.debug("cleared replicas reason=" .. tostring(reason) .. " removed=" .. tostring(removed))
    return removed
end

local function localPlayer()
    if getPlayer then
        local playerObj = getPlayer()
        if playerObj then return playerObj end
    end
    if getSpecificPlayer then return getSpecificPlayer(0) end
    return nil
end

local function halo(playerObj, text, good)
    if not playerObj or not HaloTextHelper then return end
    if good and HaloTextHelper.addGoodText then
        HaloTextHelper.addGoodText(playerObj, text)
    elseif HaloTextHelper.addBadText then
        HaloTextHelper.addBadText(playerObj, text)
    end
end

function Client.sendHello(playerObj)
    if not isClient or not isClient() then
        Client.status = "single-player-disabled"
        return false
    end

    playerObj = playerObj or localPlayer()
    if not playerObj then return false end

    Client.attempts = Client.attempts + 1
    Client.lastHelloAt = nowMs()
    Client.status = "awaiting-server"
    countPacket("sent", Protocol.Commands.HELLO)
    sendClientCommand(playerObj, Protocol.MODULE, Protocol.Commands.HELLO, Protocol.makeHello())
    print("[RemnantsMPBridge] sent handshake attempt " .. tostring(Client.attempts))
    return true
end

function Client.onCreatePlayer(playerNum, playerObj)
    if playerNum ~= 0 then return end
    Client.sendHello(playerObj)
end

function Client.onTick()
    if Client.status == "ready" or Client.status == "blocked" then return end
    if not isClient or not isClient() then return end
    if Client.attempts >= Client.MAX_ATTEMPTS then
        if Client.status ~= "server-timeout" then
            Client.status = "server-timeout"
            Client.reason = "no-handshake-response"
            print("[RemnantsMPBridge] handshake timed out")
            halo(localPlayer(), "Remnants MP Bridge: server handshake timed out", false)
        end
        return
    end

    local now = nowMs()
    if Client.lastHelloAt == 0 or now == 0 or now - Client.lastHelloAt >= Client.RETRY_INTERVAL_MS then
        Client.sendHello()
    end
end

function Client.onServerCommand(module, command, args)
    if module ~= Protocol.MODULE then return end
    if type(args) ~= "table" then return end
    countPacket("received", command)

    if command == Protocol.Commands.HELLO_RESULT then
        Client.reason = tostring(args.reason or "unknown")
        if args.accepted == true then
            Client.clearReplicas("accepted-handshake-reconcile")
            Client.status = "ready"
            print("[RemnantsMPBridge] handshake accepted")
            halo(localPlayer(), "Remnants MP Bridge ready", true)
        else
            Client.status = "blocked"
            print("[RemnantsMPBridge] handshake blocked: " .. Client.reason)
            halo(localPlayer(), "Remnants MP Bridge blocked: " .. Client.reason, false)
        end
        return
    end

    if command == Protocol.Commands.REPLICA_CREATE
            or command == Protocol.Commands.REPLICA_UPDATE then
        Client.onReplicaCreate(args)
        return
    end
    if command == Protocol.Commands.REPLICA_DESTROY then
        Client.onReplicaDestroy(args)
    end
end

function Client.sendReplicaResult(snapshot, created, detail)
    local playerObj = localPlayer()
    if not playerObj or not isClient or not isClient() then return end
    countPacket("sent", Protocol.Commands.REPLICA_RESULT)
    sendClientCommand(playerObj, Protocol.MODULE, Protocol.Commands.REPLICA_RESULT, {
        bridgeId = snapshot.bridgeId,
        revision = snapshot.revision,
        x = snapshot.x,
        y = snapshot.y,
        z = snapshot.z,
        created = created == true,
        detail = tostring(detail or "none"),
    })
end

function Client.onReplicaDestroy(snapshot)
    local valid, reason = Protocol.validateReplicaSnapshot(snapshot)
    if not valid then
        print("[RemnantsMPBridge] rejected destroy snapshot: " .. tostring(reason))
        return
    end
    local exists = npcfwReplicaExists and npcfwReplicaExists(snapshot.bridgeId) == true
    local destroyed = false
    if exists and npcfwReplicaDestroy then
        local ok, result = pcall(npcfwReplicaDestroy, snapshot.bridgeId)
        destroyed = ok and result == true
    elseif not exists then
        Client.invalidReplicaLookups = Client.invalidReplicaLookups + 1
        destroyed = true
    end
    Client.replicaRevisions[snapshot.bridgeId] = nil
    Client.sendReplicaResult(snapshot, destroyed, exists and "destroyed" or "already-missing")
end

function Client.onReplicaCreate(snapshot)
    local valid, reason = Protocol.validateReplicaSnapshot(snapshot)
    if not valid then
        print("[RemnantsMPBridge] rejected replica snapshot: " .. tostring(reason))
        return
    end
    if Client.status ~= "ready" then
        Client.sendReplicaResult(snapshot, false, "handshake-not-ready")
        return
    end

    local exists = false
    if npcfwReplicaExists then
        local existsOk, existsResult = pcall(npcfwReplicaExists, snapshot.bridgeId)
        exists = existsOk and existsResult == true
    end
    if not exists and Client.replicaRevisions[snapshot.bridgeId] then
        Client.invalidReplicaLookups = Client.invalidReplicaLookups + 1
        Client.replicaRevisions[snapshot.bridgeId] = nil
    end


    local incomingRevision = tonumber(snapshot.revision)
    local lastRevision = Client.replicaRevisions[snapshot.bridgeId] or 0
    if exists and incomingRevision <= lastRevision then
        Client.duplicateCreates = Client.duplicateCreates + 1
        print("[RemnantsMPBridge] ignored stale replica revision " .. tostring(incomingRevision)
            .. " last=" .. tostring(lastRevision))
        Client.sendReplicaResult(snapshot, true, "stale-ignored")
        return
    end

    local callOk, result
    if exists and npcfwReplicaSetPosition then
        callOk, result = pcall(
            npcfwReplicaSetPosition,
            snapshot.bridgeId,
            snapshot.x,
            snapshot.y,
            snapshot.z)
    elseif npcfwReplicaCreate then
        callOk, result = pcall(
            npcfwReplicaCreate,
            snapshot.bridgeId,
            tostring(snapshot.displayName or "Bridge Replica"),
            snapshot.female == true,
            snapshot.x,
            snapshot.y,
            snapshot.z,
            tostring(snapshot.outfit or "SURVIVOR"))
    else
        Client.sendReplicaResult(snapshot, false, "replica-api-missing")
        return
    end

    local created = callOk and result == true
    local detail = created and (exists and "updated" or "created") or (callOk and "api-returned-false" or "api-error")
    if created then
        Client.replicaRevisions[snapshot.bridgeId] = incomingRevision
    end
    print("[RemnantsMPBridge] inert replica " .. tostring(snapshot.bridgeId)
        .. " result=" .. tostring(created)
        .. " detail=" .. detail)
    if created and npcfwReplicaDescribe then
        local describeOk, description = pcall(npcfwReplicaDescribe, snapshot.bridgeId)
        if describeOk then
            print("[RemnantsMPBridge] replica description: " .. tostring(description))
        end
    end
    Client.sendReplicaResult(snapshot, created, detail)
    if created and not exists then
        halo(localPlayer(), "Bridge Test Replica created", true)
    end
end

function Client.diagnosticSnapshot()
    local hello = Protocol.makeHello()
    return {
        status = Client.status,
        reason = Client.reason,
        attempts = Client.attempts,
        bridgeVersion = hello.bridgeVersion,
        protocolVersion = hello.protocolVersion,
        gameVersion = hello.gameVersion,
        projectRemnantsReady = hello.projectRemnantsReady,
        replicaReady = hello.replicaReady,
        replicaApiVersion = hello.replicaApiVersion,
        packetCounts = Client.packetCounts,
        invalidReplicaLookups = Client.invalidReplicaLookups,
        duplicateCreates = Client.duplicateCreates,
        replicaRevisions = Client.replicaRevisions,
    }
end

function Client.onPreMapLoad()
    local removed = Client.clearReplicas("pre-map-load")
    print("[RemnantsMPBridge] cleared " .. tostring(removed) .. " replicas before map load")
    Client.status = "not-started"
    Client.reason = "none"
    Client.attempts = 0
    Client.lastHelloAt = 0
    Client.packetCounts = { sent = {}, received = {} }
    Client.invalidReplicaLookups = 0
    Client.duplicateCreates = 0
end

Events.OnCreatePlayer.Add(Client.onCreatePlayer)
Events.OnServerCommand.Add(Client.onServerCommand)
Events.OnTick.Add(Client.onTick)
Events.OnPreMapLoad.Add(Client.onPreMapLoad)
