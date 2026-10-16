# Reactivate TFOL OBT33 v36 — Argos offline + original Megatron tutorial

## Base / status
Source base: v35 Native Result UI Test. Full local test ZIP SHA-256: `be456c24a0508023886bf1589b8b9b5d7d1a9246fc6492590a9378d4582532ac`.
This document is a development checkpoint, **not** a GitHub Release. Tested in Python, **not** executed on Windows.

## Offline translator
Added a sixth provider `argos` to `Release/ClientLanguages/prepare_translation.py` and its full preparation workflow.
- UI setting saved in `LauncherSettings.ini` under `translator=`. Provider list: auto / argos / google_public / mymemory / libretranslate / google_cloud.
- Setup button runs `Release/Tools/Install-Argos.ps1` only with consent. Needs Python 3.11/3.12 64-bit and internet once to install `argostranslate`, model zh→en and en→ru.
- Models and native Python dependencies are NOT bundled. Separate user venv in `%LOCALAPPDATA%\Reactivate\Argos\venv`; no modifications to the embedded Python3.13 or original game.
- Persistent offline worker `argos_worker36.py` and `argos_local36.py`; no network provider called if explicitly selecting Argos. Existing cache, placeholder validation and size limits retained. `auto` uses offline Argos first when ready, then online fallback.
- Forcing the offline provider removes the project's *client-side* daily character work budget. Existing public API rate limits are not bypassed.

Upstream: https://github.com/argosopentech/argos-translate

## Original Megatron tutorial
Confirmed original source files, SHA-256 via `MISSION_MEGATRON_FINDINGS.json`:
- `Maps/PVE/Tutorial/Scene/Tutorial_Scene.umap`
- `Maps/PVE/Tutorial/Scripts/Tutorial_Level.umap`
- `Maps/PVE/Tutorial/Scripts/Tutorial_Matinee.umap`
- Original map ID `1009`, objective `击退威震天。` (Repel Megatron), blueprint `MegatronCharacter_PVE_C`.
- Original native bridge code **already** invokes tutorial via `action=2, map=1009, mode=1004, bots=0`: `engine_execute` calls UE4 private original function `0x7cdf60`.
- `tutorial_mission36.py` automatically dispatches this native job after a short lobby delay for locally registered accounts with `tutorial_required=1` and `tutorial_completed_at=NULL`.
- A different existing match is never interrupted; public VPS does not launch the UE4 world; dispatch **does not** count as tutorial completion.

Original cooked game PAKs 105/108 must be present in the user's complete installation. No original game EXE, PAKs or models have been uploaded here.

## Verification
58 targeted Python tests PASS; no live Windows GUI or boss fight test. Original 3 tutorial .umap SHA-256 verified. Original UE4 EXE/PAKs and native runtime unchanged. Bootstrap UI cache updated to `v36argos1` to avoid stale launcher.
Do not claim a real Megatron boss encounter, AI or mission victory is verified until a Windows runtime report proves it.
