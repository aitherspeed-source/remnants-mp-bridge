RemnantsMPBridge = RemnantsMPBridge or {}
RemnantsMPBridge.Protocol = RemnantsMPBridge.Protocol or {}

local Protocol = RemnantsMPBridge.Protocol

Protocol.MODULE = "RemnantsMPBridge"
Protocol.BRIDGE_VERSION = "0.1.3"
Protocol.PROTOCOL_VERSION = 1
Protocol.TARGET_GAME_VERSION = "42.19.0"
Protocol.REPLICA_API_VERSION = "1"
Protocol.DEBUG = true

Protocol.Commands = {
    HELLO = "hello",
    HELLO_RESULT = "helloResult",
    REPLICA_CREATE = "replicaCreate",
    REPLICA_UPDATE = "replicaUpdate",
    REPLICA_DESTROY = "replicaDestroy",
    REPLICA_RESULT = "replicaResult",
}

function Protocol.debug(message)
    if Protocol.DEBUG then
        print("[RemnantsMPBridge][debug] " .. tostring(message))
    end
end

local function safeString(value, fallback, maxLength)
    local result = value == nil and fallback or tostring(value)
    if maxLength and #result > maxLength then
        result = string.sub(result, 1, maxLength)
    end
    return result
end

function Protocol.gameVersion()
    if not getCore then return "unknown" end
    local ok, version = pcall(function() return getCore():getVersion() end)
    if not ok then return "unknown" end
    return safeString(version, "unknown", 64)
end

function Protocol.baseGameVersion(value)
    local raw = safeString(value, "unknown", 64)
    return string.match(raw, "^(%d+%.%d+%.%d+)") or raw
end

function Protocol.javaStatus()
    local status = {
        projectRemnantsReady = false,
        replicaReady = false,
        replicaApiVersion = "missing",
    }

    if npcfwIsReady then
        local ok, ready = pcall(npcfwIsReady)
        status.projectRemnantsReady = ok and ready == true
    end

    -- This function is intentionally absent from the current Project Remnants
    -- jar. The future Java extension must expose it before NPC replication is
    -- allowed to start.
    if npcfwReplicaApiVersion then
        local ok, version = pcall(npcfwReplicaApiVersion)
        if ok and version ~= nil then
            status.replicaApiVersion = safeString(version, "invalid", 32)
        else
            status.replicaApiVersion = "error"
        end
    end

    if npcfwReplicaIsReady then
        local ok, ready = pcall(npcfwReplicaIsReady)
        status.replicaReady = ok and ready == true
    end

    return status
end

function Protocol.makeHello()
    local java = Protocol.javaStatus()
    return {
        bridgeVersion = Protocol.BRIDGE_VERSION,
        protocolVersion = Protocol.PROTOCOL_VERSION,
        gameVersion = Protocol.gameVersion(),
        projectRemnantsReady = java.projectRemnantsReady,
        replicaReady = java.replicaReady,
        replicaApiVersion = java.replicaApiVersion,
    }
end

function Protocol.validateHello(args)
    if type(args) ~= "table" then
        return false, "invalid-payload"
    end

    if tonumber(args.protocolVersion) ~= Protocol.PROTOCOL_VERSION then
        return false, "protocol-mismatch"
    end
    if safeString(args.bridgeVersion, "", 64) ~= Protocol.BRIDGE_VERSION then
        return false, "bridge-version-mismatch"
    end
    if Protocol.baseGameVersion(args.gameVersion) ~= Protocol.TARGET_GAME_VERSION then
        return false, "game-version-mismatch"
    end
    if args.projectRemnantsReady ~= true then
        return false, "project-remnants-agent-not-ready"
    end
    if safeString(args.replicaApiVersion, "", 32) ~= Protocol.REPLICA_API_VERSION then
        return false, "replica-api-missing-or-mismatched"
    end
    if args.replicaReady ~= true then
        return false, "replica-api-not-ready"
    end

    return true, "ready"
end

function Protocol.validateReplicaSnapshot(snapshot)
    if type(snapshot) ~= "table" then return false, "invalid-replica-payload" end

    local bridgeId = safeString(snapshot.bridgeId, "", 128)
    if bridgeId == "" or not string.match(bridgeId, "^[%w%._:%-]+$") then
        return false, "invalid-replica-id"
    end

    local revision = tonumber(snapshot.revision)
    if not revision or revision < 1 or revision ~= math.floor(revision) then
        return false, "invalid-replica-revision"
    end

    for _, field in ipairs({ "x", "y", "z" }) do
        local value = tonumber(snapshot[field])
        if not value or value ~= value or math.abs(value) > 10000000 then
            return false, "invalid-replica-position"
        end
    end
    if tonumber(snapshot.z) < -32 or tonumber(snapshot.z) > 31 then
        return false, "invalid-replica-z"
    end

    return true, "valid"
end
