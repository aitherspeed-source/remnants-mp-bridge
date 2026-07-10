package remnantsmpbridge;

import java.lang.instrument.Instrumentation;
import java.lang.reflect.Method;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import npcfw.core.IsoNPC;
import npcfw.core.NPCManager;
import npcfw.data.NPCData;
import se.krka.kahlua.integration.expose.LuaJavaClassExposer;
import se.krka.kahlua.vm.KahluaTable;
import zombie.Lua.LuaManager;

/**
 * Independent companion agent for Project Remnants.
 *
 * <p>This class does not transform game or Project Remnants bytecode. It only
 * exposes a small replica API after the normal Lua environment is ready.</p>
 */
public final class ReplicaAgent {
    private static final String LOG_PREFIX = "[RemnantsMPBridgeAgent] ";
    private static final ReplicaApi API = new ReplicaApi();

    private ReplicaAgent() {
    }

    public static void premain(String agentArgs, Instrumentation instrumentation) {
        log("starting; no bytecode transformers are installed");
        Thread watcher = new Thread(ReplicaAgent::watchLuaEnvironment, "RemnantsMPBridge-Lua-Watcher");
        watcher.setDaemon(true);
        watcher.start();
    }

    private static void watchLuaEnvironment() {
        KahluaTable lastEnvironment = null;
        while (!Thread.currentThread().isInterrupted()) {
            try {
                Thread.sleep(1000L);
                LuaJavaClassExposer exposer = LuaManager.exposer;
                KahluaTable environment = LuaManager.env;
                if (exposer == null || environment == null || environment == lastEnvironment) {
                    continue;
                }
                if (lastEnvironment != null) {
                    API.forgetAllForEnvironmentChange();
                }
                if (exposeApi(exposer, environment)) {
                    lastEnvironment = environment;
                }
            } catch (InterruptedException interrupted) {
                Thread.currentThread().interrupt();
            } catch (Throwable error) {
                log("watcher error: " + error.getClass().getName() + ": " + safeMessage(error));
            }
        }
    }

    private static boolean exposeApi(LuaJavaClassExposer exposer, KahluaTable environment) {
        int exposed = 0;
        try {
            for (Method method : ReplicaApi.class.getMethods()) {
                if (!method.getName().startsWith("npcfwReplica")) {
                    continue;
                }
                exposer.exposeGlobalObjectFunction(environment, API, method, method.getName());
                exposed++;
            }
            log("exposed " + exposed + " Lua replica functions");
            return exposed > 0;
        } catch (Throwable error) {
            log("Lua API exposure failed: " + error.getClass().getName() + ": " + safeMessage(error));
            return false;
        }
    }

    private static String safeMessage(Throwable error) {
        String message = error.getMessage();
        return message == null ? "no message" : message;
    }

    static void log(String message) {
        System.out.println(LOG_PREFIX + message);
    }

    public static final class ReplicaApi {
        private static final String API_VERSION = "1";
        private static final int MAX_REPLICAS = 16;
        private static final int MAX_ID_LENGTH = 128;
        private static final int MAX_NAME_LENGTH = 64;
        private final Map<String, ReplicaRecord> replicas = new ConcurrentHashMap<>();

        public String npcfwReplicaApiVersion() {
            return API_VERSION;
        }

        public boolean npcfwReplicaIsReady() {
            try {
                return NPCManager.getInstance() != null;
            } catch (Throwable ignored) {
                return false;
            }
        }

        public int npcfwReplicaCount() {
            return replicas.size();
        }

        public boolean npcfwReplicaExists(String bridgeId) {
            return bridgeId != null && replicas.containsKey(bridgeId);
        }

        public String npcfwReplicaDescribe(String bridgeId) {
            ReplicaRecord record = replicas.get(bridgeId);
            if (record == null) {
                return "missing:" + bridgeId;
            }
            IsoNPC npc = record.npc;
            boolean inWorld = npc.getCell() != null && npc.getCell().getObjectList().contains(npc);
            String square = npc.getCurrentSquare() == null
                    ? "null"
                    : npc.getCurrentSquare().getX() + "," + npc.getCurrentSquare().getY() + "," + npc.getCurrentSquare().getZ();
            return bridgeId
                    + " pos=" + npc.getX() + "," + npc.getY() + "," + npc.getZ()
                    + " square=" + square
                    + " inWorld=" + inWorld
                    + " alpha=" + npc.getAlpha()
                    + " targetAlpha=" + npc.getTargetAlpha();
        }

        public boolean npcfwReplicaCreate(
                String bridgeId,
                String displayName,
                Boolean female,
                Double x,
                Double y,
                Double z,
                String outfit) {
            if (!validId(bridgeId) || replicas.size() >= MAX_REPLICAS && !replicas.containsKey(bridgeId)) {
                return false;
            }
            if (!finiteCoordinates(x, y, z)) {
                return false;
            }

            ReplicaRecord existing = replicas.get(bridgeId);
            if (existing != null) {
                return applyPosition(existing.npc, x.floatValue(), y.floatValue(), z.floatValue());
            }

            String safeName = sanitizeName(displayName);
            String safeOutfit = sanitizeOutfit(outfit);
            NPCManager manager = NPCManager.getInstance();
            NPCData data = manager.spawn(
                    safeName,
                    Boolean.TRUE.equals(female),
                    x.floatValue(),
                    y.floatValue(),
                    z.floatValue(),
                    safeOutfit);
            if (data == null || data.npcId == null) {
                return false;
            }

            String originalId = data.npcId;
            IsoNPC npc = manager.getNPC(originalId);
            if (npc == null) {
                manager.despawn(originalId);
                return false;
            }

            try {
                makeInert(npc);
                manager.detachFromPersistence(npc, "RemnantsMPBridge replica");
                data.npcId = bridgeId;
                npc.bindData(data);
                makeInert(npc);
                if (!applyPosition(npc, x.floatValue(), y.floatValue(), z.floatValue())) {
                    destroyDetached(manager, bridgeId, npc);
                    return false;
                }
                replicas.put(bridgeId, new ReplicaRecord(npc));
                log("created inert replica " + bridgeId);
                return true;
            } catch (Throwable error) {
                log("create failed for " + bridgeId + ": " + safeMessage(error));
                destroyDetached(manager, bridgeId, npc);
                return false;
            }
        }

        public boolean npcfwReplicaSetPosition(String bridgeId, Double x, Double y, Double z) {
            ReplicaRecord record = replicas.get(bridgeId);
            if (record == null || !finiteCoordinates(x, y, z)) {
                return false;
            }
            return applyPosition(record.npc, x.floatValue(), y.floatValue(), z.floatValue());
        }

        public boolean npcfwReplicaDestroy(String bridgeId) {
            ReplicaRecord record = replicas.remove(bridgeId);
            if (record == null) {
                return false;
            }
            destroyDetached(NPCManager.getInstance(), bridgeId, record.npc);
            log("destroyed replica " + bridgeId);
            return true;
        }

        public int npcfwReplicaClearAll() {
            int removed = 0;
            for (String bridgeId : replicas.keySet().toArray(new String[0])) {
                if (npcfwReplicaDestroy(bridgeId)) {
                    removed++;
                }
            }
            return removed;
        }

        void forgetAllForEnvironmentChange() {
            int forgotten = replicas.size();
            replicas.clear();
            if (forgotten > 0) {
                log("forgot " + forgotten + " stale replica references after Lua environment change");
            }
        }

        private static void makeInert(IsoNPC npc) {
            npc.setPossessed(false);
            npc.setBehaviorTree(null);
            npc.cancelAllTasks();
            npc.clearTasks();
            npc.stopMovement();
            npc.setCollidable(false);
            npc.setNoDamage(true);
            npc.setAvoidDamage(true);
            npc.setBlockMovement(false);
            npc.setSceneCulled(false);
            npc.setAlphaAndTarget(1.0f);
            npc.setOutlineHighlightCol(0.1f, 0.9f, 1.0f, 1.0f);
            npc.setOutlineHighlight(true);
            npc.setOutlineThickness(2.0f);
            npc.setHaloNote("Bridge Test Replica", 80, 230, 255, 600.0f);
        }

        private static boolean applyPosition(IsoNPC npc, float x, float y, float z) {
            try {
                npc.setPosition(x, y, z);
                npc.setCurrentSquareFromPosition();
                npc.setMovingSquare(npc.getCurrentSquare());
                return npc.getCurrentSquare() != null;
            } catch (Throwable error) {
                log("position update failed: " + safeMessage(error));
                return false;
            }
        }

        private static void destroyDetached(NPCManager manager, String bridgeId, IsoNPC npc) {
            try {
                manager.reattachRuntimeNPC(npc, "RemnantsMPBridge cleanup");
                manager.despawn(bridgeId);
            } catch (Throwable error) {
                log("normal cleanup failed for " + bridgeId + ": " + safeMessage(error));
                try {
                    npc.removeFromWorld();
                    npc.removeFromSquare();
                } catch (Throwable fallbackError) {
                    log("fallback cleanup failed for " + bridgeId + ": " + safeMessage(fallbackError));
                }
            }
        }

        private static boolean validId(String bridgeId) {
            if (bridgeId == null || bridgeId.isEmpty() || bridgeId.length() > MAX_ID_LENGTH) {
                return false;
            }
            for (int i = 0; i < bridgeId.length(); i++) {
                char value = bridgeId.charAt(i);
                if (!(Character.isLetterOrDigit(value) || value == '-' || value == '_' || value == '.' || value == ':')) {
                    return false;
                }
            }
            return true;
        }

        private static boolean finiteCoordinates(Double x, Double y, Double z) {
            return x != null && y != null && z != null
                    && Double.isFinite(x) && Double.isFinite(y) && Double.isFinite(z)
                    && z >= -32.0 && z <= 31.0;
        }

        private static String sanitizeName(String displayName) {
            if (displayName == null) {
                return "Remnant Replica";
            }
            String trimmed = displayName.trim();
            if (trimmed.isEmpty()) {
                return "Remnant Replica";
            }
            return trimmed.length() <= MAX_NAME_LENGTH ? trimmed : trimmed.substring(0, MAX_NAME_LENGTH);
        }

        private static String sanitizeOutfit(String outfit) {
            if (outfit == null || outfit.trim().isEmpty() || outfit.length() > 64) {
                return "SURVIVOR";
            }
            return outfit.trim();
        }
    }

    private record ReplicaRecord(IsoNPC npc) {
    }
}
