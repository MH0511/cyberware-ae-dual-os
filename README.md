# Cyberware AE — Cyberdeck & Sandevistan Dual OS Support

[简体中文](README.zh-CN.md)

An unofficial addon for **Cyberware-AE** that lets one cyberdeck and one Sandevistan work together in Cyberpunk 2077. Use your normal cyberware ability key for Sandevistan outside the scanner, and for Overclock inside the scanner. Quickhacking remains available, with separate HUD charge indicators.

**Version 0.1.0 · Windows PC · Tested on Cyberpunk 2077 2.5 with Cyberware-AE 1.01.**

Cyberware-AE's page now lists 1.13. That version has **not** been tested with this addon. Compatibility with later AE versions or different OS mods is not established. This addon does not redistribute Cyberware-AE or Cyberware-EX.

![Separate cyberware HUD indicators after reloading a save](docs/images/dual-os-hud.png)

## Requirements

| Component | Tested version |
| --- | --- |
| Cyberpunk 2077 | 2.5, Windows PC |
| [Cyberware-AE](https://www.nexusmods.com/cyberpunk2077/mods/35708) | 1.01 |
| [redscript](https://github.com/jac3km4/redscript) | 0.5.32 |
| [Cyber Engine Tweaks](https://github.com/maximegmd/CyberEngineTweaks) | 1.38.0 |

The addon does not require RED4ext, Codeware or TweakXL. Do not run it alongside Cyberware-EX, System-EX, or another mod that replaces the same OS activation, equipment, or cyberware HUD methods; that combination has not been tested.

## Install

1. Close the game and back up your saves.
2. Install the prerequisites separately. Buy an additional operating-system slot through Cyberware-AE.
3. Download the install ZIP from this repository's **Releases**, rather than GitHub's automatic source archive.
4. Extract its `bin` and `r6` folders into your Cyberpunk 2077 installation directory.
5. Start the game normally and equip one cyberdeck and one Sandevistan. Restarting is required; do not first load this addon through CET while a save is already running.

Installed directories:

```text
bin/x64/plugins/cyber_engine_tweaks/mods/ae_dual_os/
r6/scripts/AEDualOS/
```

Cyberware-AE's `NativeCyberwareSlots` files are not replaced.

## Controls

| State | Cyberware ability key (E in the tested setup) |
| --- | --- |
| Normal gameplay | Use Sandevistan; interrupt it where the model supports interruption |
| Scanner / focus mode | Use the vanilla Overclock action |

Overclock still requires its perk. Cooldowns, charge, phone-call restrictions and other vanilla ability restrictions remain in effect. The addon does not unlock perks, increase damage, change cyberware capacity, or edit quest data.

## Tested scope and limitations

- Tested combination: **Militech Apogee 5++ + NetWatch Netdriver 5++**.
- The tester reported normal dual-system operation. A newly saved game was reloaded successfully with both systems recognized.
- Separate HUD icons and the complete HUD row were verified after restart. The scanner displayed vehicle quickhack options.
- Offline compilation against the local vanilla 2.5 script bundle and in-game startup compilation passed.
- LuaJIT tests cover mapping scope, repeat initialization, partial-failure rollback and prevention of first initialization during gameplay. These tests do not simulate combat or the game's native systems.

Multiple cyberdecks, multiple Sandevistans, Berserk triple-OS setups and multiple arm cyberware are outside this release's support scope. Equipment-order swaps, removing either OS independently, all quest scenarios and extended combat have not been exhaustively tested. No universal compatibility or crash-free guarantee is claimed.

![Quickhack options remain visible in the scanner](docs/images/quickhack-menu.png)

## Uninstall

With the addon still active, visit a ripperdoc, unequip the extra Sandevistan, leave a single cyberdeck installed and create a new manual save. Close the game, then move the two addon directories listed above outside the game folder. Keep Cyberware-AE's own files if you still want its slot expansion. redscript recompiles on the next launch.

Do not overwrite newer saves with backups. If reverting to an earlier setup, select an appropriate earlier save from the game's load menu.

## Troubleshooting and reports

If the game reports a script compilation error, check `r6/logs/redscript_rCURRENT.log` for the named conflict. CET startup output should contain `[AE Dual OS] READY`. A `[AE Dual OS] DISABLED` message means initialization failed; its message identifies the reason.

For a read-only state snapshot, use this CET console command during gameplay:

```lua
GetMod("ae_dual_os").diagnostics()
```

Restrictions in shops, story scenes or phone calls can make an ability unavailable. Test in a normal gameplay area before reporting a failure. Include game/mod versions, both OS names, equipment order, relevant log excerpts and steps to reproduce in a GitHub issue. Do not post your full save, account data or unrelated personal information.

## Source, credits and development disclosure

The equipment, focus-mode and HUD approach is adapted from [Cyberware-EX](https://github.com/psiberx/cp2077-cyberware-ex) by **Pavel Siberx / psiberx**, under the MIT license. Its copyright notice and license are retained in [LICENSE](LICENSE). Cyberware-AE by **HilanderGK** supplies the separately installed slot expansion; this project is not an official release from either author.

The addon implementation and documentation were substantially generated with **OpenAI Codex**, adapting the credited upstream design. The project owner specified the behavior and performed in-game testing. AI involvement is disclosed rather than described as wholly human-authored development. On Nexus Mods, the code fits the **AI-Generated Content** tag; generated page descriptions also require the applicable **AI Media** tag under its current rules. Screenshots are actual gameplay captures.

No game executable, decompiled game scripts, vanilla script bundle, save files, prerequisite binaries, account credentials or private troubleshooting logs are included.

## Development

Runtime source is under `package/`. To run the Lua mapping tests with Python and LuaJIT:

```sh
python -m pip install -r tests/requirements.txt
python tests/test_runtime_mapping.py
```

Build the install archive on Windows with:

```powershell
pwsh -File ./build.ps1
```

The build writes an install ZIP and SHA-256 checksum to `dist/`, and verifies archive contents against the source files. See [CHANGELOG.md](CHANGELOG.md) for release notes.
