# OBT33 v48 — WinForms, skin default, human-only UI localization and new Windows report

Full local test artifact: `Reactivate_TFOL_OBT33_v48_UI_MANUAL_SKIN_TEST_FULL.zip`; 703 files, 102768080 bytes, ZIP CRC passed; SHA-256 `07a3c3bc09a9344cf9f5768717bff4ecefa6e543857fa72bfe1a6abfccb8e574`. Mini patch for **full v47 only**: `TFOL_OBT33_v48_UI_MANUAL_SKIN_MINIPATCH.zip`, 18 files, 281376 bytes, SHA-256 `c3fe839d3ace5b60046bf4a5f9a3c68471f54b733ccd806746190f2549f7f2d1`. **Neither is a GitHub Release. Original UE4 executable/PAKs and user ZIP/RAR are not uploaded.**

## WinForms regression fixed
The screenshot shows manual translation button overlapping Save Settings and bottom PAK scan clipped in a 1198×512 card. v47 text button x735+260=995 overlaps save x935..1171. v48 places translation x735..975, save x985..1173, scan y468..503, admin/GitHub at y376. RU/EN/ZH language switches update their `i18n:` tagged text and the report checkbox instead of retaining mixed labels. Own Reactivate launcher bootstrap UI cache key updated from v47 to v48; native game EXE untouched. Windows WinForms compilation/visual result still **unverified**.

## Actual language corpus provided by user
Archive `Reactivate.rar` contains user-generated UE4.14 `ui_catalog_v1.json`, 205 scanned PAK indexes, 1670 original FText rows and 1064 distinct Chinese source strings, 0 scanner errors. Old translated count 179. 127 additional phrases were reviewed by editor and added manually to `ClientLanguages/manual_dictionary.json`. End-to-end original `.locres` compilation validates **309/1064** unique sources / 850 LocRes identities for each of RU and EN, zero identity conflicts, leaving **755 original Chinese sources**; they remain untranslated, with source info in `ManualLocalization/UI_Review_Backlog_v48.csv`. No machine translation or network provider has been reintroduced. This is explicitly **not** 100% game translation (texture text, out-of-Pak assets and all localizable table rows are separate).

## Game skins
User reports skin/model failures inside a match even with no paid skins. New server handling of native `EquipItemReq` with zero skin ID now clears only that owned holder's cosmetic and responds success with bag sync, even if default was already equipped. Exact 64-bit item ID is resolved **before** fallback resource ID, fixing `item_id=1` vs other hero `resource_id=1` collision. Real local TF15 socket test passed for repeated zero-skin reset and rejecting a foreign holder; previous purchase checks continue to pass.

### Additional UE4 errors from report
`TFOL.log` contains `LeftMesh null`, default `FirstPersonMesh` material count zero and a missing `MeleeWeapon_DestroyGemini` asset; such errors could affect normal skinless characters and are not necessarily related to Store/EquipItemReq. In this report there are **0 EquipItemReq(40)** and **0 UnEquipItemReq(287)**. An offline PAK-index analyzer `check_v48_game_assets.py` was added to locate affected assets without modifying the game. UE4 actor/UMG failures are **not** fixed by this server update.

## Post-match proof from new real report
`OBT_LOCAL_33_REPORT_20261018_010803_225776.zip`:
- 2026-10-17T15:12:05.470Z server `native_ui_round_end_observed` outcome **victory**, one persisted participation grant including 75 silver.
- UE4 later `OnBattleResultDataTimeout` and `WaitingPostMatch -> LeavingMap`.
- **No `native_result_persisted` / authenticated OB15**. The original server currently cannot provide full GameStopInfo+AccBattleInfo (kills, deaths, team scores). Result screen and accurate per-kill payouts are still P0; never synthesize a victory scoreboard from the banner.
- Offline report analyzer `analyze_v48_report.py` outputs only safe aggregate counts.

## Archivo Narrow
It is available from https://github.com/google/fonts/tree/main/ofl/archivonarrow (SIL OFL). The local opt-in `Fonts/Setup-ArchivoNarrow.ps1` stages it outside the game's PAK; **font files are not redistributed**. The font does not guarantee Russian/CJK coverage. Actual TFOL UE4.14 cooked UI requires verified FontFace/CompositeFont assets plus Cyrillic/CJK fallbacks. The runtime game font has **not** been changed. Offline font asset scanner included.

## Tests
68/68 targeted+regression Python tests passed, including live TCP store and zero-skin behavior, first-login mission, manual language and UI event. RU/EN LocRes round-trip produced 309 distinct sources, 850 entries, zero identity conflicts. ZIP CRCs passed. Original `Release/Server/ClientUpdate/TFOL_OBT.exe` SHA unchanged versus v47. Windows/UE4 integration not tested.
