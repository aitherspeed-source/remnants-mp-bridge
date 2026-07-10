# Local Baseline — 2026-07-10

This read-only baseline identifies the files inspected before any bridge installation. Recalculate it after every Project Zomboid unstable or Project Remnants Workshop update.

| Component | SHA-256 | Size |
| --- | --- | ---: |
| Project Remnants `NPCFW.jar` | `F199B1AEE1463CC45D416B6F3FF322E71A182F9A4F2D8299BC44122C12D47719` | 583,469 bytes |
| Build 42 `projectzomboid.jar` | `901A12E3E2E4F3DE841C17D9A30D0E2FE97115D390E8AF577FDCDCB98C5D7D76` | 63,890,567 bytes |
| `ProjectZomboid64.json` | `B829AF8ED561B5EC9BDF453C14CDFE7C15A376507BD131A0290D763394E66572` | 476 bytes |
| `ProjectZomboidServer.bat` | `6C307497D37884B14CEA19CF9CCE35C0C577BF14B638C2CC2EA7FDC32E457C0F` | 323 bytes |

- Game version observed in `console.txt`: `42.19.0`.
- `SVNRevision.txt`: `964`.
- Workshop item: `3738362476`.
- Project Remnants mod ID: `ProjectRemnants`.
- No `NPCFW` or `-javaagent` entry was present in `ProjectZomboid64.json` during inspection.
- The supplied Project Remnants installer targets `ProjectZomboid64.json`, not `ProjectZomboidServer.bat`.
- The existing `servertest` profile is outside the bridge test scope and was not changed.

These hashes document compatibility; they do not authorize copying or distributing the hashed files.

## Locally built companion

- Artifact: `java/build/RemnantsMPBridgeAgent.jar`
- SHA-256: `DB61E4F4D707CA5C83A7BF6C5BD5CCB3271451D0F38E8DEB1A700F2900CE6687`
- Compiled with Temurin `javac 25.0.3` against the baseline game and Project Remnants jars.
- Contains only `remnantsmpbridge.*` classes and a Java-agent manifest; it does not bundle game, Kahlua, or `npcfw.*` classes.
