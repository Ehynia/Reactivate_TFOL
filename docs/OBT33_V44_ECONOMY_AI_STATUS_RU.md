# OBT33 v44 — authenticated combat economy, participation fallback, AI diagnostics

Full local test ZIP built: `Reactivate_TFOL_OBT33_v44_ECONOMY_NATIVE_AI_DIAGNOSTICS_FULL.zip` (101764058 bytes, SHA-256 `cac3e7346c576df0002312e097a18d213c42f623a9f764e893dc5354d27df0c0`, 679 files, ZIP CRC pass). Server-only mini patch: `TFOL_OBT33_v44_SERVER_ECONOMY_MINIPATCH.zip` (27164 bytes, SHA-256 `7e2ad8d91b0c207a9b7a7c0339eaff47258bac1ff9cbabfad12ad910d59f553d`). These ZIPs have **not** been published as GitHub Releases.

## Proven improvements (server logic)
- `economy.complete()` pays for each unique, validated native OB15 result, even for a **lost** match. Old blanket 60-second suppression no longer zeroes legitimate back-to-back matches. Existing SQLite transaction ID idempotency, wrong-owner rejection and cap checks remain.
- Native PvE `KillMonster` works when `Kill=0`; `max(Kill,KillMonster)` avoids double-counting the same kills in both counters. Real draws/failed mission outcomes never become fake wins; short/invalid outcomes remain rejected.
- Project-defined, more generous policy: XP base 125 +20 per kill, silver 150 +75 per kill, blue and other currencies +2/kill, currency 1 +1/kill, skin tickets +1/kill. Original values were intentionally not treated as authentic Tencent economy.
- Without OB15, **no per-kill count is known**. Instead an actually acknowledged local match of >=45 seconds can earn ONE strictly capped participation grant (currencies 1:+1,2:+2,3:+75,5:+2,6:+2 plus a real bonus card). Limits: 60-second interval, 20 per UTC day, one grant per persisted round ID. Clicking menus or shop cannot create money; public hosted-preparation does not grant local currency.
- The client often returns to the lobby without sending ExitPostGameReq(165). Mode-list request 263 now settles an existing tracked round, returning real `SyncBagData(38)` and `SyncItemData(39)` wallet updates, *without clearing the engine match context*, allowing a late genuine native result to still be handled.

## Native C
- An original client's `TutorialBattleReq(176)` no longer clears `engine_started_sequence` before post-match capture; exit commands still terminate the session. Rebuilt pinned x86 PE test SHA-256 `6908d8719becb7662a806b8cbdebafdd0d16464a942de547f123a74fd5fd0914` and updated base_exe_manifest. **Windows runtime not tested.**
- `ai_change_repaired` now emits a bounded sample (48 per PvP test match) of existing Controller presence and enable flags. This is **diagnostic only**. No invented aiming, aim-assist, navigation, or difficulty changes: original `AIStrenthTable.bytes` five coefficients remain semantically unverified.

## Unresolved top-priority blockers
- **EndMatch -> OB15.** The native bridge advertises OB15 support (TF15 kind10) but its current C code does NOT capture original UE4 GameStopInfo+AccBattleInfo into a TF15 kind7 frame. Python can render original packet 60 only after receiving an actual native scoreboard. The result screen remains unverified and likely timed out on real Windows.
- **Weak/static bots.** Original UE4 BT tactics exist. Controller-presence diagnostics do not by themselves repair aim accuracy, navmesh, target selection, team imbalance. Must recover genuine original UTBot/UTBaseAIController runtime data and test on Windows; cannot credibly assert AI improved.
- TRW/CTF score replication and engine PVE core/timer remain unresolved.

## Test evidence
80/80 targeted Python regression tests passed; two stale expectations updated to the real 30-second hero-selection countdown and v42 launcher-cache key. Pinned compiled PE32 x86 ABI, imports, sections and original code patches validated statically. Full ZIP CRC passed; no private databases, player passwords or original large PAKs shared.

**Important:** Never promise in-game kill payouts or results while UE4 does not emit confirmed native kill/end-match events. The increased native kill rewards work upon actual OB15; the participation fallback works on a tracked local round/exit path.
