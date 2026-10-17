# OBT33 v38 — audit of all six available diagnostic reports

Based on one OBT23 report (2026-10-16) and five OBT33 reports (2026-10-17). Historical logs are not runtime validation of the new build.

## Quantified UE4/client warnings
- 85,587 repeated missing vehicle skill icon lines; **unresolved** asset/skill binding.
- 5,336 missing MovementAnim_* array lines; **unresolved** actor animation initialization.
- 3,012 empty astMonthDaySignDayList and 120 astMonthHistoryAccSignList lines; **v38 changes the server's MonthSignInfoRes(256)** to include actual calendar-day slots without invented rewards.
- 1,242 empty littleItemDatas messages; **unresolved**, no trustworthy daily-reward item reference.
- 124 missing ICU resources, 6 missing CHS-font warning lines; **unresolved**; no proprietary fonts redistributed.
- 26 native DS SendPackFail; 23 invulnerable-hit warnings; 14 failed skill-spawn lines; **unresolved**.
- 16 missing ingameResult_camerashake references; 2 OnBattleResultDataTimeout occurrences; **critical P0 unresolved** (verified UE4 EndMatch -> OB15 -> protocol 60 -> client result window -> persisted rewards is not yet complete).

Counts are logged warning *occurrences*, not unique broken assets.

## Proven missing TDR protocol responses fixed in v38
1. **117 QueryAchievementList** appeared in three reports and was silently discarded. Now sends valid **118 SyncAchievementList** with a 0-length list; does not invent achievements.
2. **196 LogoutReq** appeared once with no response. Now sends **197 LogoutRes**, closes only the current session, and treats duplicate logout idempotently; no account reset/reward minting.
3. **255 MonthSignInfoReq** used to return 0 daily, accumulated and history slots. Now responds with actual days of the month (Feb 28/29 included) with all rewards unclaimed and all item lists empty. This mitigates absent array slots, but original client UI can still index -1 before receiving the response.
4. 132 and 74 unhandled in the much older OBT23 report were already supported in v37; no claim of a new fix.

## Test evidence
- 85/85 server-level targeted regression tests PASS, including skins, battle-only currency, tutorial, PvE result escrow, matchmaking and postmatch.
- 2/2 synthetic privacy-safe audit-tool tests PASS.
- Two original stale test assertions updated to the existing 30-second hero countdown and SQLite schema 11. They failed identically on unchanged v37.
- ZIP checksum passed; original game EXE, original client update EXE, launcher bootstrap EXE unchanged (identical SHA256 vs v37). No original UE4 binaries/PAKs published to GitHub.
- **Windows actual gameplay is not verified**; particularly core damage, AI skill animation, CTF flags and post-match result remain P0/P1.

Full v38 test ZIP generated separately in the conversation (not uploaded as GitHub Release). Server patch included in ZIP as `V38_SERVER_FIX.patch`. See `patches/V38_PROTOCOL_REPORT_FIX.patch` for the two changed production modules.
