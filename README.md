# Remnants MP Bridge

Experimental Project Zomboid Build 42 hosted-multiplayer compatibility work for
Pat's NPC: Project Remnants.

This repository is currently a Phase 1 inert-replica test. It is not a finished
gameplay mod. Use only a disposable hosted world such as `NPCMPTest`.

## Requirements

- Project Zomboid Build 42.19.0
- Steam Workshop Project Remnants (`3738362476`)
- Windows, for the current Java-agent installers

## Install

Download the newest ZIP from [Releases](https://github.com/aitherspeed-source/remnants-mp-bridge/releases/latest),
extract it, close Project Zomboid, and double-click
`Install Remnants MP Bridge.bat`.

Keep the extracted folder. For future builds, double-click
`Update Remnants MP Bridge.bat`; it verifies and installs the latest release.

## Project status

Read `CURRENT_STATUS.md` first. Architecture, decisions, roadmap, testing, and
rollback procedures are maintained in the other top-level continuity documents.

Project Remnants and Project Zomboid binaries are not included in this repository
or its releases. The bridge companion is independently built and contains only
`remnantsmpbridge.*` classes.
