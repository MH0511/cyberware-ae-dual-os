# Changelog

## 0.1.0 — 2026-10-25

First public package of the locally tested Cyberware-AE dual-OS addon.

- Separate Sandevistan attachment mapping using CET, with rollback on initialization failure.
- Resolve the equipped cyberdeck for quickhacking, independent of its visual OS slot.
- Route the cyberware ability key by scanner state: Sandevistan normally, vanilla Overclock in focus mode.
- Preserve the remaining OS's effects when another OS is successfully unequipped.
- Adapt focus-mode time dilation handling for use with Sandevistan.
- Show separate charge indicators and widen the HUD row to avoid clipping.
- Add English and Simplified Chinese installation, removal and troubleshooting documentation.

Tested: Cyberpunk 2077 2.5, Cyberware-AE 1.01, redscript 0.5.32, CET 1.38.0; Apogee 5++ and NetWatch Netdriver 5++. Later AE versions are unverified. See the README for limitations and AI-development disclosure.

Runtime Lua and redscript sources are unchanged from the locally tested package; public-release changes are documentation, packaging and development tooling.
