REMNANTS MP BRIDGE - PRIVATE TEST BUILD

Requirements:
- Windows
- Project Zomboid Build 42.19.0 installed through Steam
- Steam Workshop item 3738362476 (Project Remnants) downloaded
- Project Remnants downloaded from Steam Workshop

Installation:
1. Exit Project Zomboid completely.
2. Extract this entire ZIP.
3. Double-click "Install Remnants MP Bridge.bat".
4. Enable ProjectRemnants and RemnantsMPBridge for the disposable NPCMPTest Host.

Future updates:
- Keep this extracted folder.
- Exit Project Zomboid.
- Double-click "Update Remnants MP Bridge.bat".
- It downloads the latest public GitHub release, verifies its SHA-256 checksum,
  and installs it automatically. Restart the game after an update.

The installer automatically locates Steam libraries. If Project Remnants' Java
agent is missing, it runs Project Remnants' own supplied installer with its
normal backup and verification behavior. It then backs up any prior local
bridge and ProjectZomboid64.json, installs this bridge, and verifies its files.

If it reports that Project Remnants is not downloaded, subscribe to Workshop
item 3738362476, wait for Steam to finish, and run this installer again.

Use "Uninstall Remnants MP Bridge.bat" to remove only this bridge and its Java
launch entries. Project Remnants is left unchanged.

This is a private unstable multiplayer test build. Do not use a real server save.
