require "RemnantsMPBridge/Protocol"

RemnantsMPBridge.Server = RemnantsMPBridge.Server or {}
local Server = RemnantsMPBridge.Server
local Protocol = RemnantsMPBridge.Protocol

Server.clients = Server.clients or {}
Server.replicas = Server.replicas or {}
Server.packetCounts = Server.packetCounts or { sent = {}, received = {} }
Server.invalidReplicaLookups = Server.invalidReplicaLookups or 0
Server.SAVE_KEY = "RemnantsMPBridge.Canonical"
Server.SAVE_MAGIC = "RMPB"
Server.SAVE_SCHEMA_VERSION = 1
Server.saveRoot = Server.saveRoot or nil
Server.saveStatus = Server.saveStatus or "not-loaded"
Server.persistentReplicaId = Server.persistentReplicaId or nil
Server.HELLO_RATE_LIMIT_MS = 1000
Server.MAX_REPLICA_DELIVERIES = 20
Server.REPLICA_RETRY_INTERVAL_MS = 3000
Server.MOVEMENT_INITIAL_DELAY_MS = 10000
Server.MOVEMENT_JOIN_DELAY_MS = 3000
Server.MOVEMENT_INTERVAL_MS = 3000
Server.MOVEMENT_UPDATE_COUNT = 6

local function nowMs()
    if getTimestampMs then return getTimestampMs() end
    return 0
end

local function playerKey(playerObj)
    if not playerObj then return "missing-player" end
    local ok, username = pcall(function() return playerObj:getUsername() end)
    if ok and username ~= nil then return tostring(username) end
    return "unknown-player"
end

local function countPacket(direction, command)
    local counts = Server.packetCounts[direction]
    counts[command] = (counts[command] or 0) + 1
end

local function copyCanonicalRecord(record)
    if type(record) ~= "table" then return nil end
    return {
        magic = record.magic,
        schemaVersion = record.schemaVersion,
        bridgeId = record.bridgeId,
        revision = record.revision,
        displayName = record.displayName,
        female = record.female == true,
        outfit = record.outfit,
        appearanceSeed = record.appearanceSeed,
        x = record.x,
        y = record.y,
        z = record.z,
        checksum = record.checksum,
    }
end

local function canonicalText(record)
    return table.concat({
        tostring(record.magic or ""),
        tostring(record.schemaVersion or ""),
        tostring(record.bridgeId or ""),
        tostring(record.revision or ""),
        tostring(record.displayName or ""),
        record.female == true and "1" or "0",
        tostring(record.outfit or ""),
        tostring(record.appearanceSeed or ""),
        tostring(record.x or ""),
        tostring(record.y or ""),
        tostring(record.z or ""),
    }, "|")
end

local function canonicalChecksum(record)
    local hash = 5381
    local text = canonicalText(record)
    for index = 1, #text do
        hash = (hash * 33 + string.byte(text, index)) % 2147483647
    end
    return tostring(hash)
end

local function validateCanonicalRecord(record)
    if type(record) ~= "table" then return false, "missing-record" end
    if record.magic ~= Server.SAVE_MAGIC then return false, "magic-mismatch" end
    if tonumber(record.schemaVersion) ~= Server.SAVE_SCHEMA_VERSION then
        return false, "schema-mismatch"
    end
    local valid, reason = Protocol.validateReplicaSnapshot(record)
    if not valid then return false, reason end
    if tostring(record.checksum or "") ~= canonicalChecksum(record) then
        return false, "checksum-mismatch"
    end
    return true, "valid"
end

local function persistentReplicaId()
    local value = getRandomUUID and getRandomUUID() or nil
    if not value or tostring(value) == "" then
        value = tostring(nowMs()) .. "-" .. tostring(ZombRand and ZombRand(1000000000) or 0)
    end
    return string.sub("rmp-" .. tostring(value), 1, 128)
end

function Server.persistReplica(replica, reason)
    if not Server.saveRoot or not replica then return false end
    local nextRecord = {
        magic = Server.SAVE_MAGIC,
        schemaVersion = Server.SAVE_SCHEMA_VERSION,
        bridgeId = replica.bridgeId,
        revision = replica.revision,
        displayName = replica.displayName,
        female = replica.female == true,
        outfit = replica.outfit,
        appearanceSeed = replica.appearanceSeed,
        x = replica.x,
        y = replica.y,
        z = replica.z,
    }
    nextRecord.checksum = canonicalChecksum(nextRecord)
    local currentValid = validateCanonicalRecord(Server.saveRoot.primary)
    if currentValid then
        Server.saveRoot.backup = copyCanonicalRecord(Server.saveRoot.primary)
    end
    Server.saveRoot.primary = nextRecord
    Server.saveRoot.lastWriteReason = tostring(reason or "state-change")
    Server.saveRoot.schemaVersion = Server.SAVE_SCHEMA_VERSION
    Server.saveStatus = "saved"
    Protocol.debug("persisted bridgeId=" .. replica.bridgeId
        .. " revision=" .. tostring(replica.revision)
        .. " reason=" .. Server.saveRoot.lastWriteReason)
    return true
end

function Server.onInitGlobalModData(isNewGame)
    Server.saveRoot = ModData.getOrCreate(Server.SAVE_KEY)
    local primaryValid, primaryReason = validateCanonicalRecord(Server.saveRoot.primary)
    local record = nil
    if primaryValid then
        record = copyCanonicalRecord(Server.saveRoot.primary)
        Server.saveStatus = "loaded-primary"
    else
        local backupValid = validateCanonicalRecord(Server.saveRoot.backup)
        if backupValid then
            record = copyCanonicalRecord(Server.saveRoot.backup)
            Server.saveRoot.primary = copyCanonicalRecord(record)
            Server.saveStatus = "recovered-backup"
        else
            Server.saveStatus = isNewGame and "new-world" or "no-valid-record"
        end
    end
    if record then
        Server.persistentReplicaId = record.bridgeId
        Server.replicas[record.bridgeId] = {
            bridgeId = record.bridgeId,
            revision = tonumber(record.revision),
            displayName = record.displayName,
            female = record.female == true,
            outfit = record.outfit,
            appearanceSeed = tonumber(record.appearanceSeed) or 0,
            x = tonumber(record.x), y = tonumber(record.y), z = tonumber(record.z),
            spawnSource = Server.saveStatus,
            path = {}, pathIndex = 0, updatesRemaining = 0, nextMoveAt = 0,
            deliveries = {},
        }
        print("[RemnantsMPBridge] restored canonical replica " .. record.bridgeId
            .. " revision=" .. tostring(record.revision)
            .. " source=" .. Server.saveStatus)
    else
        Protocol.debug("canonical save unavailable reason=" .. tostring(primaryReason)
            .. " status=" .. Server.saveStatus)
    end
end

local function sendHelloResult(playerObj, accepted, reason)
    countPacket("sent", Protocol.Commands.HELLO_RESULT)
    sendServerCommand(playerObj, Protocol.MODULE, Protocol.Commands.HELLO_RESULT, {
        accepted = accepted == true,
        reason = tostring(reason or "unknown"),
        bridgeVersion = Protocol.BRIDGE_VERSION,
        protocolVersion = Protocol.PROTOCOL_VERSION,
        serverGameVersion = Protocol.gameVersion(),
        requiredGameVersion = Protocol.TARGET_GAME_VERSION,
        requiredReplicaApiVersion = Protocol.REPLICA_API_VERSION,
    })
end

local function safePlayerPosition(playerObj)
    local ok, x, y, z = pcall(function()
        return playerObj:getX(), playerObj:getY(), playerObj:getZ()
    end)
    if not ok then return nil end
    return tonumber(x), tonumber(y), tonumber(z)
end

local function safeReplicaPosition(playerObj)
    local current = playerObj and playerObj.getCurrentSquare and playerObj:getCurrentSquare() or nil
    if current then
        local ok, adjacent = pcall(function() return current:getRandomAdjacentFreeSameRoom() end)
        if ok and adjacent then
            return adjacent:getX() + 0.5, adjacent:getY() + 0.5, adjacent:getZ()
        end

        local cell = getCell and getCell() or nil
        if cell then
            local offsets = {
                { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
                { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 },
            }
            for _, offset in ipairs(offsets) do
                local square = cell:getGridSquare(
                    current:getX() + offset[1],
                    current:getY() + offset[2],
                    current:getZ())
                local usable = false
                if square then
                    local usableOk, result = pcall(function()
                        return square:isFree(false) and current:canReachTo(square)
                    end)
                    usable = usableOk and result == true
                end
                if usable then
                    return square:getX() + 0.5, square:getY() + 0.5, square:getZ()
                end
            end
        end
    end

    local x, y, z = safePlayerPosition(playerObj)
    if not x then return nil end
    return x + 0.75, y + 0.25, z
end

local function reachableReplicaPath(playerObj)
    local path = {}
    local current = playerObj and playerObj.getCurrentSquare and playerObj:getCurrentSquare() or nil
    local cell = getCell and getCell() or nil
    if not current or not cell then return path end

    local offsets = {
        { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 },
        { 1, 1 }, { -1, 1 }, { -1, -1 }, { 1, -1 },
    }
    for _, offset in ipairs(offsets) do
        local square = cell:getGridSquare(
            current:getX() + offset[1],
            current:getY() + offset[2],
            current:getZ())
        local usable = false
        if square then
            local ok, result = pcall(function()
                return square:isFree(false) and current:canReachTo(square)
            end)
            usable = ok and result == true
        end
        if usable then
            table.insert(path, {
                x = square:getX() + 0.5,
                y = square:getY() + 0.5,
                z = square:getZ(),
            })
        end
    end
    return path
end

function Server.sendReplica(playerObj, replica, command)
    local key = playerKey(playerObj)
    command = command or Protocol.Commands.REPLICA_CREATE
    if replica.deliveryRevision ~= replica.revision then
        replica.deliveryRevision = replica.revision
        replica.deliveries = {}
    end
    replica.lastCommand = command
    replica.deliveries = replica.deliveries or {}
    replica.deliveryCommands = replica.deliveryCommands or {}
    replica.deliveryCommands[key] = command
    replica.deliveries[key] = (replica.deliveries[key] or 0) + 1
    countPacket("sent", command)
    sendServerCommand(playerObj, Protocol.MODULE, command, {
        bridgeId = replica.bridgeId,
        revision = replica.revision,
        displayName = replica.displayName,
        female = replica.female,
        outfit = replica.outfit,
        appearanceSeed = replica.appearanceSeed,
        spawnSource = replica.spawnSource,
        x = replica.x,
        y = replica.y,
        z = replica.z,
    })
    print("[RemnantsMPBridge] sent inert replica " .. replica.bridgeId
        .. " command=" .. tostring(command)
        .. " revision=" .. tostring(replica.revision)
        .. " player=" .. key
        .. " delivery=" .. tostring(replica.deliveries[key]))
end

function Server.destroyReplica(bridgeId, reason)
    local replica = Server.replicas[bridgeId]
    if not replica then
        Server.invalidReplicaLookups = Server.invalidReplicaLookups + 1
        return false
    end
    replica.revision = replica.revision + 1
    replica.destroyReason = tostring(reason or "server-request")
    Server.broadcastReplica(replica, Protocol.Commands.REPLICA_DESTROY)
    Server.replicas[bridgeId] = nil
    Protocol.debug("destroyed canonical replica bridgeId=" .. bridgeId
        .. " reason=" .. replica.destroyReason)
    return true
end

local function acceptedOnlinePlayers()
    local result = {}
    local onlineKeys = {}
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if players then
        for index = 0, players:size() - 1 do
            local playerObj = players:get(index)
            local key = playerKey(playerObj)
            onlineKeys[key] = true
            if Server.clients[key] and Server.clients[key].accepted == true then
                table.insert(result, playerObj)
            end
        end
    end
    for key, client in pairs(Server.clients) do
        local present = onlineKeys[key] == true
        if client.present ~= present then
            client.present = present
            Protocol.debug("presence player=" .. key .. " online=" .. tostring(present))
        end
    end
    return result
end

function Server.broadcastReplica(replica, command)
    local recipients = acceptedOnlinePlayers()
    for _, playerObj in ipairs(recipients) do
        Server.sendReplica(playerObj, replica, command)
    end
    Protocol.debug("broadcast bridgeId=" .. replica.bridgeId
        .. " revision=" .. tostring(replica.revision)
        .. " command=" .. tostring(command)
        .. " recipients=" .. tostring(#recipients))
end

function Server.ensureTestReplica(playerObj)
    local key = playerKey(playerObj)
    local bridgeId = Server.persistentReplicaId
    if not bridgeId then
        bridgeId = persistentReplicaId()
        Server.persistentReplicaId = bridgeId
    end
    local replica = Server.replicas[bridgeId]
    if not replica then
        local x, y, z = safeReplicaPosition(playerObj)
        if not x then
            print("[RemnantsMPBridge] cannot create test replica: player position unavailable")
            return
        end
        replica = {
            bridgeId = bridgeId,
            revision = 1,
            displayName = "Bridge Test Replica",
            female = false,
            outfit = "SURVIVOR",
            appearanceSeed = ZombRand and ZombRand(2147483647) or 0,
            x = x,
            y = y,
            z = z,
            spawnSource = "first-accepted-client:" .. key,
            path = reachableReplicaPath(playerObj),
            pathIndex = 0,
            updatesRemaining = 0,
            nextMoveAt = 0,
            deliveries = {},
        }
        Server.replicas[bridgeId] = replica
        Server.persistReplica(replica, "created")
        print("[RemnantsMPBridge] registered persistent inert replica " .. bridgeId)
    elseif #(replica.path or {}) == 0 then
        replica.path = reachableReplicaPath(playerObj)
    end
    Server.sendReplica(playerObj, replica)
end

function Server.onHello(playerObj, args)
    local key = playerKey(playerObj)
    local now = nowMs()
    local existing = Server.clients[key]
    local reconnecting = existing ~= nil and existing.present == false
    if existing and now > 0 and existing.lastHelloAt > 0
            and now - existing.lastHelloAt < Server.HELLO_RATE_LIMIT_MS then
        sendHelloResult(playerObj, false, "hello-rate-limited")
        return
    end

    local accepted, reason = Protocol.validateHello(args)
    Server.clients[key] = {
        accepted = accepted,
        reason = reason,
        lastHelloAt = now,
        bridgeVersion = args and tostring(args.bridgeVersion or "missing") or "missing",
        protocolVersion = args and tonumber(args.protocolVersion) or -1,
        gameVersion = args and tostring(args.gameVersion or "missing") or "missing",
        projectRemnantsReady = args and args.projectRemnantsReady == true or false,
        replicaReady = args and args.replicaReady == true or false,
        replicaApiVersion = args and tostring(args.replicaApiVersion or "missing") or "missing",
        present = true,
    }

    print("[RemnantsMPBridge] handshake player=" .. key
        .. " accepted=" .. tostring(accepted)
        .. " reason=" .. tostring(reason)
        .. " clientGame=" .. tostring(args and args.gameVersion or "missing")
        .. " serverGame=" .. Protocol.gameVersion())
    sendHelloResult(playerObj, accepted, reason)
    if accepted then
        if reconnecting then
            local replica = Server.persistentReplicaId
                and Server.replicas[Server.persistentReplicaId] or nil
            if replica then
                replica.movementScheduledClients = replica.movementScheduledClients or {}
                replica.movementScheduledClients[key] = nil
                replica.reconnectCount = (replica.reconnectCount or 0) + 1
                Protocol.debug("reconnect snapshot player=" .. key
                    .. " bridgeId=" .. replica.bridgeId
                    .. " revision=" .. tostring(replica.revision)
                    .. " reconnectCount=" .. tostring(replica.reconnectCount))
            end
        end
        Server.ensureTestReplica(playerObj)
    end
end

function Server.onReplicaResult(playerObj, args)
    countPacket("received", Protocol.Commands.REPLICA_RESULT)
    local valid, reason = Protocol.validateReplicaSnapshot(args)
    local key = playerKey(playerObj)
    local clientState = Server.clients[key]
    if not clientState or clientState.accepted ~= true then
        print("[RemnantsMPBridge] replica result before accepted handshake player=" .. key)
        return
    end
    if not valid then
        print("[RemnantsMPBridge] invalid replica result player=" .. key .. " reason=" .. reason)
        return
    end

    local replica = Server.replicas[args.bridgeId]
    if not replica or tonumber(args.revision) ~= replica.revision then
        Server.invalidReplicaLookups = Server.invalidReplicaLookups + 1
        print("[RemnantsMPBridge] stale or unknown replica result player=" .. key)
        return
    end

    local created = args.created == true
    print("[RemnantsMPBridge] replica result player=" .. key
        .. " bridgeId=" .. replica.bridgeId
        .. " created=" .. tostring(created)
        .. " detail=" .. string.sub(tostring(args.detail or "none"), 1, 64))
    local deliveries = replica.deliveries and replica.deliveries[key] or 0
    if created and replica.retryAtByPlayer then
        replica.retryAtByPlayer[key] = nil
    end
    if not created and deliveries < Server.MAX_REPLICA_DELIVERIES then
        replica.retryAtByPlayer = replica.retryAtByPlayer or {}
        replica.retryAtByPlayer[key] = nowMs() + Server.REPLICA_RETRY_INTERVAL_MS
        Protocol.debug("scheduled replica retry player=" .. key
            .. " bridgeId=" .. replica.bridgeId
            .. " attempt=" .. tostring(deliveries + 1))
    elseif not created then
        print("[RemnantsMPBridge] replica delivery exhausted player=" .. key
            .. " bridgeId=" .. replica.bridgeId
            .. " deliveries=" .. tostring(deliveries))
    elseif created then
        replica.movementScheduledClients = replica.movementScheduledClients or {}
        if replica.movementScheduledClients[key] then return end
        replica.movementScheduledClients[key] = true
        replica.updatesRemaining = Server.MOVEMENT_UPDATE_COUNT
        local delay = replica.revision == 1
            and Server.MOVEMENT_INITIAL_DELAY_MS
            or Server.MOVEMENT_JOIN_DELAY_MS
        replica.nextMoveAt = nowMs() + delay
        print("[RemnantsMPBridge] scheduled " .. tostring(replica.updatesRemaining)
            .. " transform updates for " .. replica.bridgeId
            .. " confirmedClient=" .. key
            .. " delayMs=" .. tostring(delay)
            .. " pathSquares=" .. tostring(#(replica.path or {})))
    end
end

function Server.onTick()
    local now = nowMs()
    if now <= 0 then return end
    local acceptedPlayers = acceptedOnlinePlayers()
    for _, playerObj in ipairs(acceptedPlayers) do
        local key = playerKey(playerObj)
        for _, replica in pairs(Server.replicas) do
            local retryAt = replica.retryAtByPlayer and replica.retryAtByPlayer[key] or nil
            local deliveries = replica.deliveries and replica.deliveries[key] or 0
            if retryAt and now >= retryAt then
                replica.retryAtByPlayer[key] = nil
                if deliveries < Server.MAX_REPLICA_DELIVERIES then
                    local command = replica.deliveryCommands and replica.deliveryCommands[key]
                        or Protocol.Commands.REPLICA_CREATE
                    Server.sendReplica(playerObj, replica, command)
                end
            end
        end
    end
    for _, replica in pairs(Server.replicas) do
        if replica.updatesRemaining and replica.updatesRemaining > 0
                and now >= (replica.nextMoveAt or 0) then
            local path = replica.path or {}
            if #path == 0 then
                replica.updatesRemaining = 0
                print("[RemnantsMPBridge] movement sequence stopped for " .. replica.bridgeId
                    .. " reason=no-reachable-path")
            else
                replica.pathIndex = (replica.pathIndex % #path) + 1
                local position = path[replica.pathIndex]
                replica.x = position.x
                replica.y = position.y
                replica.z = position.z
                replica.revision = replica.revision + 1
                replica.updatesRemaining = replica.updatesRemaining - 1
                replica.nextMoveAt = now + Server.MOVEMENT_INTERVAL_MS
                Server.persistReplica(replica, "movement")
                Server.broadcastReplica(replica, Protocol.Commands.REPLICA_UPDATE)
                if replica.updatesRemaining == 0 then
                    print("[RemnantsMPBridge] movement sequence complete for " .. replica.bridgeId
                        .. " finalRevision=" .. tostring(replica.revision))
                end
            end
        end
    end
end

function Server.diagnosticSnapshot()
    local replicaCount = 0
    local clientCount = 0
    for _ in pairs(Server.replicas) do replicaCount = replicaCount + 1 end
    for _ in pairs(Server.clients) do clientCount = clientCount + 1 end
    return {
        sharedReplicaId = Server.persistentReplicaId,
        replicas = replicaCount,
        clients = clientCount,
        packetCounts = Server.packetCounts,
        invalidReplicaLookups = Server.invalidReplicaLookups,
        reconnectCount = Server.persistentReplicaId and Server.replicas[Server.persistentReplicaId]
            and (Server.replicas[Server.persistentReplicaId].reconnectCount or 0)
            or 0,
        saveStatus = Server.saveStatus,
        saveSchemaVersion = Server.SAVE_SCHEMA_VERSION,
    }
end

function Server.onClientCommand(module, command, playerObj, args)
    if module ~= Protocol.MODULE then return end
    if not playerObj then return end

    if command == Protocol.Commands.HELLO then
        countPacket("received", command)
        Server.onHello(playerObj, args)
        return
    end
    if command == Protocol.Commands.REPLICA_RESULT then
        Server.onReplicaResult(playerObj, args)
        return
    end

    sendHelloResult(playerObj, false, "unknown-command")
end

Events.OnClientCommand.Add(Server.onClientCommand)
Events.OnTick.Add(Server.onTick)
Events.OnInitGlobalModData.Add(Server.onInitGlobalModData)
print("[RemnantsMPBridge] server protocol " .. tostring(Protocol.PROTOCOL_VERSION)
    .. " loaded for game " .. Protocol.TARGET_GAME_VERSION)
