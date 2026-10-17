# TFOL OBT33 v49 — AFK hero autoselection and Spark presets

**Base:** full v48, independent user screenshot `image(20261017-155450).png`; screenshot shows hero timer `-18` while the human player has not pressed Ready, and a native “Unknown error” dialog around the scheme 1/2 selection. **Windows client behavior is not yet verified.**

## Root cause: negative countdown
`Release/Server/native_bots.py` defines 30 seconds for original hero-selection UI and a 120-second safety timeout. In v48 `poll()` never checked `selection_end` for AFK players: only `GameReadyDataReq(21)` would advance the match. For players who do not press Ready, the UE4 timer can go below zero and the server waits to fail at 120 seconds.

v49: after a confirmed room, at `selection_end` the local coordinator verifies the player's last selected owned character, marks readiness once, sends authentic `GameReadyDataRes(22)` and `GetTeamListDataRes(18)`. Subsequent bridge heartbeat dispatches a single original `OB27` job to the pre-selected mode/map. Manual Ready, decline/cancel, engine rejection and non-owned characters keep their existing checks. The AFK fallback is for **local native-bot sessions**, not proof that shared Internet matchmaking is fixed.

## Spark 1/2 unknown error candidate
The existing `SelectSparkConfigReq(141)` handler required a 64-bit inventory item ID for the selected character and rejected `Id=0`. Original UI can represent the currently selected hero as 0 or by original character resource ID. v49 `owned_spark_holder()` resolves (in priority order) an exact owned `inventory.item_id`, owned original resource ID, or the current owned character for ID=0, and stores a single canonical scheme association keyed to `item_id`. `QueryJijiaSparkReq(245)` resolves the same canonical key. Unowned and unknown schemes are rejected. The screenshot **does not prove** that the error came from command 141, so do not claim Windows skin/scheme issue fixed without a report.

## Deliverables and verification
- `TFOL_OBT33_v49_AFK_SPARK_MINIPATCH.zip`, 14287 bytes, SHA256 `7f790f1b3b1859c01ea852132a23f487427f1fe7aa62c42cfc34e29003cc8d74`. Two production Python files, 7 new tests, README, diff, manifest.
- `Reactivate_TFOL_OBT33_v49_AFK_SPARK_FULL.zip`, 101832837 bytes, SHA256 `505d6e3925d17d1c706070e8f73995845dc4a92a6f2b704de2d18df8f508172f`; 707 files, based on v48 unchanged original game EXE/PAK and manual RU/EN files.
- 21 related tests PASS, including 7 new AFK, Spark ownership, native bridge TF15 authenticated heartbeat tests plus v30/v41/v48 regression coverage. Broader historical suite timed out and is **not** claimed successful.
- Both ZIPs passed CRC and unique-path checks.
- Not yet verified: exact native UE4 HUD clock zeroing, true gameplay after automatic selection, origin of “Unknown error,” actual multi-PC match, CTF scoring, results OB15.

Install: shut down game and server, back up installation, extract mini over the root directory of full **v48** preserving `Release/Server/` paths; or run the separate full v49. To validate, confirm the found match but do not click Ready, wait until 30 seconds; separately test switching Spark scheme 1/2. If unknown error remains, enable ZIP reports only from launcher settings and provide server/native log with command 141 or UI error events. No machine translator reintroduced; do not publish original game files or any personal session reports in GitHub.
