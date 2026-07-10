# Remnants MP Bridge Rollback

The current bridge scaffold does not alter Project Zomboid, Project Remnants, launch JSON, server configuration, or save files.

## Disable the scaffold

1. Exit the host and both clients completely.
2. Remove `RemnantsMPBridge` from the disposable `NPCMPTest` profile's `Mods=` list.
3. Leave Workshop item `3738362476` and mod ID `ProjectRemnants` unchanged.
4. Restart the disposable profile and confirm that neither client nor server logs contain a new `[RemnantsMPBridge]` line.

Deleting the local bridge folder is optional after it is disabled. Never delete or edit the subscribed Project Remnants Workshop folder as part of bridge rollback.

## Companion Java-extension rollback

The companion is built but has not been installed. Its installer edits only the
client `ProjectZomboid64.json` and copies `RemnantsMPBridgeAgent.jar` to the game
root. It refuses installation until the Project Remnants Java agent is already
present.

To uninstall after a disposable test:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File ".\tools\install_companion.ps1" -Mode Uninstall
```

The uninstall mode creates a fresh pre-uninstall backup, surgically removes only
the companion classpath and `-javaagent` entries, then deletes only the companion
jar from the game root. It preserves Project Remnants entries and never modifies
`ProjectZomboidServer.bat`.

Every install/uninstall creates a timestamped backup beside
`ProjectZomboid64.json`. If surgical rollback fails, exit the game and restore
the relevant `ProjectZomboid64.json.RemnantsMPBridgeBackup.<timestamp>` file
manually.

Do not install a future agent into the existing `servertest` profile or test against a real multiplayer save.

## Private friend bundle rollback

The private ZIP includes `Uninstall Remnants MP Bridge.bat`. It removes only the
bridge launch entries and agent. The installed local mod is moved to a timestamped
`.uninstalled-*` folder rather than deleted. Before changing launch JSON, the
tool creates `ProjectZomboid64.json.RemnantsMPBridgeBackup.<timestamp>`.

Project Remnants files and launch entries are preserved. If automated rollback
fails, exit the game and restore the timestamped launch JSON backup manually.
